# Jenkins Docker Role

This Ansible role deploys Jenkins lts using Docker with comprehensive configuration and management capabilities.

## Features

- Deploys Jenkins lts in a Docker container
- Configures Jenkins with essential plugins
- Sets up basic security with admin user
- Provides management scripts
- Configures Docker networking
- Supports SSL/TLS configuration
- Automated plugin installation

## Requirements

- Docker installed on target system
- Ansible 2.9+
- `community.docker` collection

## Quick Start

### Basic Jenkins Deployment

```yaml
- hosts: jenkins_servers
  become: yes
  vars:
    jenkins_admin_password: "secure_password"
  roles:
    - jenkins-docker
```

## Role Variables

### Main Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `jenkins_image` | `jenkins/jenkins:lts` | Jenkins Docker image |
| `jenkins_container_name` | `jenkins` | Container name |
| `jenkins_host_port` | `8080` | Host port for Jenkins web UI |
| `jenkins_agent_port` | `50000` | Port for Jenkins agents |

### Directories

| Variable | Default | Description |
|----------|---------|-------------|
| `jenkins_home` | `/var/lib/jenkins` | Jenkins home directory |
| `jenkins_data_dir` | `/opt/jenkins` | Jenkins data directory |

### Security

| Variable | Default | Description |
|----------|---------|-------------|
| `jenkins_admin_username` | `admin` | Admin username |
| `jenkins_admin_password` | `changeme` | Admin password (change this!) |

### Plugin Management

| Variable | Default | Description |
|----------|---------|-------------|
| `jenkins_install_plugins` | `true` | Enable plugin installation |
| `jenkins_plugins_list` | See defaults | List of plugins to install |


### SSL/TLS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `jenkins_use_ssl` | `false` | Enable SSL/TLS for Jenkins |
| `jenkins_ssl_cert_path` | `""` | Path to SSL certificate file |
| `jenkins_ssl_key_path` | `""` | Path to SSL private key file |
| `jenkins_verify_ssl_certs` | `false` | Enable SSL certificate validation during verification tests |

## Example Playbook

```yaml
- hosts: jenkins_servers
  become: yes
  vars:
    jenkins_admin_password: "secure_password"
    jenkins_host_port: 8080
  roles:
    - jenkins-docker
```

## Plugin Management

The role uses Docker-native plugin installation for fast and reliable plugin management.

**How it works:**
- Creates a `plugins.txt` file with your plugin list
- Mounts this file to `/usr/share/jenkins/ref/plugins.txt` in the container  
- Jenkins Docker image installs plugins during container initialization
- All plugins are available immediately when Jenkins starts

### Configuration

```yaml
# Enable/disable plugin installation
jenkins_install_plugins: true

# Customize the plugin list
jenkins_plugins_list:
  - "git"
  - "pipeline-stage-view"
  - "workflow-aggregator"
  # ... add your plugins
```

### Benefits

✅ **Fast Installation** - Plugins installed during container startup
✅ **Reliable** - Uses Jenkins Docker image's built-in installer  
✅ **No Delays** - Plugins available immediately at startup
✅ **Docker Native** - Follows Jenkins Docker best practices

## Testing and Verification

The role includes built-in verification tasks that run automatically during deployment. For comprehensive testing, use the dedicated verification playbook:

```bash
# Run comprehensive Jenkins verification
ansible-playbook -i inventory.yml playbooks/verify-jenkins.yml

# Test specific hosts
ansible-playbook -i inventory.yml playbooks/verify-jenkins.yml --limit jenkins_servers
```

### What gets verified:
- ✅ Docker container is running
- ✅ Jenkins web interface is accessible
- ✅ Jenkins API is responding
- ✅ No permission errors in logs
- ✅ Home directory permissions are correct
- ✅ Management scripts are functional


## Security Considerations

1. Change the default admin password
2. Configure SSL/TLS for production use
3. Regularly update Jenkins and plugins
4. Implement proper firewall rules

## Troubleshooting

### Ansible-native debugging:
```bash
# Check deployment status
ansible-playbook -i inventory.yml playbooks/verify-jenkins.yml

# Check specific issues
ansible jenkins_servers -m command -a "docker logs jenkins --tail 50"
ansible jenkins_servers -m stat -a "path=/var/lib/jenkins"
```

### Plugin Installation Issues

If Jenkins shows "no plugins installed":

1. **Check plugins.txt file**:
   ```bash
   # Run diagnostic script
   ./scripts/diagnose-jenkins-plugins.sh
   
   # Check if plugins.txt is a file (not directory)
   ls -la /opt/jenkins/plugins.txt
   ```

2. **Force plugin reinstallation**:
   ```bash
   ansible-playbook -i inventory.yml playbooks/jenkins-docker.yml \
     -e jenkins_force_plugin_reinstall=true
   ```

3. **Test plugin installation**:
   ```bash
   ansible-playbook -i inventory.yml playbooks/test-jenkins-plugins.yml
   ```

### Common Issues

- **"plugins.txt as directory"**: Remove directory and redeploy
- **Container permission errors**: Check Jenkins user UID/GID matches volume permissions
- **Network connectivity**: Ensure Docker network is created properly

### Manual troubleshooting:
1. Check container logs: `docker logs jenkins`
2. Verify permissions on Jenkins home directory
3. Ensure Docker daemon is running

### SSL Certificate Verification Issues

If you encounter SSL certificate verification errors during Jenkins verification:

1. **For internal/testing environments**: Set `jenkins_verify_ssl_certs: false` (default)
   ```yaml
   jenkins_verify_ssl_certs: false
   ```

2. **For production environments**: Ensure proper SSL certificates are configured
   ```yaml
   jenkins_verify_ssl_certs: true
   jenkins_use_ssl: true
   jenkins_ssl_cert_path: "/path/to/cert.pem"
   jenkins_ssl_key_path: "/path/to/key.pem"
   ```

3. **Alternative**: Use HTTP for internal testing
   - The verification tasks will automatically use HTTP when `jenkins_verify_ssl_certs` is false

### Common Issues

## License

MIT
