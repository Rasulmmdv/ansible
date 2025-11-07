# Traefik Ansible Role

This Ansible role installs and configures Traefik as a reverse proxy using Docker Compose. Traefik is a modern reverse proxy and load balancer that makes deploying microservices easy.

## Features

- **Docker Compose deployment** - Runs Traefik in a Docker container with proper configuration
- **Automatic SSL/TLS** - Supports Let's Encrypt ACME certificates with HTTP, DNS, or TLS challenges
- **Dashboard with authentication** - Web dashboard with optional basic authentication
- **Security hardening** - Includes security headers, HSTS, and other security features
- **Flexible configuration** - Supports both Docker and file providers
- **Logging and monitoring** - Configurable logging and optional Prometheus metrics
- **Network management** - Creates and manages Docker networks
- **User and permission management** - Creates dedicated user and sets proper permissions

## Requirements

- Target system running a Debian-based Linux distribution (Ubuntu, Debian)
- The `community.docker` collection for Ansible
- SSH access to the target system with sudo privileges

## Tags

This role implements the standardized tagging strategy for selective execution:

### Lifecycle Tags
- `prereq` - Prerequisites and validation tasks
- `install` - Package installation and system setup
- `configure` - Configuration and user setup
- `deploy` - Service deployment
- `validate` - Health checks and validation

### Functional Tags
- `security` - Security configuration (users, permissions, certificates)
- `networking` - Network setup and firewall configuration

### Component Tags
- `docker` - Docker-related operations
- `web` - Web service deployment and validation

### Usage Examples
```bash
# Full deployment
ansible-playbook site.yml --tags "traefik"

# Install and configure only (no deployment)
ansible-playbook site.yml --tags "install,configure" --limit traefik_hosts

# Deploy and validate only
ansible-playbook site.yml --tags "deploy,validate" --limit traefik_hosts

# Security configuration only
ansible-playbook site.yml --tags "security" --limit traefik_hosts

# Validation and health checks only
ansible-playbook site.yml --tags "validate" --limit traefik_hosts
```

**Note**: The role automatically installs all required dependencies including:
- Docker and Docker Compose
- Python3 with bcrypt and docker libraries (via system packages when available)
- Required system packages
- Configures firewall rules via iptables

**Python Dependencies**: The role intelligently handles Python package installation:
1. First attempts to use system packages (python3-bcrypt, python3-docker)
2. Falls back to pip with `--break-system-packages` if system packages are unavailable
3. Compatible with both older and newer Ubuntu/Debian systems (including PEP 668 compliance)

## Role Variables

### Basic Configuration

```yaml
# Traefik Docker image
traefik_image: "traefik:v3.4"
traefik_container_name: "traefik"

# Ports
traefik_dashboard_port: 8080
traefik_web_port: 80
traefik_websecure_port: 443

# Directories
traefik_data_dir: "/opt/traefik"
traefik_config_dir: "/opt/traefik/config"
traefik_certs_dir: "/opt/traefik/certs"

# User and group
traefik_user: "traefik"
traefik_group: "traefik"

# Network
traefik_network_name: "traefik-network"
```

### Dashboard Configuration

```yaml
# Dashboard settings
traefik_dashboard_enabled: true
traefik_dashboard_auth_enabled: true
traefik_dashboard_username: "admin"
traefik_dashboard_password: "changeme"  # Please change this!
```

### SSL/TLS Configuration

```yaml
# SSL settings
traefik_ssl_enabled: true

# Certificate type - choose one: "acme" for Let's Encrypt, "custom" for your own certificates
traefik_certificate_type: "acme"  # Default: use ACME (Let's Encrypt)

# ACME (Let's Encrypt) configuration - used when traefik_certificate_type: "acme"
traefik_acme_email: "admin@example.com"
traefik_acme_challenge_type: "http"  # Options: http, dns, tls
traefik_acme_use_staging: true  # Use staging for testing, false for production
traefik_ssl_certificate_resolver: "letsencrypt"

# Custom certificate configuration - used when traefik_certificate_type: "custom"
traefik_certificate_files:
  - cert: "/certificates/cert.pem"
    key: "/certificates/key.pem"
    stores:
      - default
  # Add more certificates if needed
  # - cert: "/certificates/other-cert.pem"
  #   key: "/certificates/other-key.pem"
  #   stores:
  #     - other-store
```

### Security Settings

```yaml
# Security options
traefik_hsts_enabled: true
traefik_frame_deny: true
traefik_content_type_nosniff: true
traefik_browser_xss_filter: true
```

### Provider Configuration

```yaml
# Docker provider
traefik_docker_provider_enabled: true
traefik_docker_expose_by_default: false

# File provider
traefik_file_provider_enabled: true
traefik_file_provider_watch: true
```

### Logging

```yaml
# Logging settings (logs go to stdout/stderr for Docker)
traefik_log_level: "INFO"
traefik_access_logs_enabled: true
```

### Prerequisites and Dependencies

```yaml
# Automatic dependency management
traefik_ensure_docker_installed: true    # Automatically install Docker
traefik_configure_firewall: true         # Configure iptables rules

# Customizable package lists
traefik_system_packages:
  - python3
  - python3-pip
  - curl
  - gnupg
  - ca-certificates
  - apt-transport-https

traefik_python_packages:
  - bcrypt
  - docker
```

## Dependencies

This role **automatically manages its dependencies**:
- **Docker role**: Installs and configures Docker and Docker Compose
- **iptables role**: Configures firewall rules for required ports
- **System packages**: Installs all required system dependencies
- **Python packages**: Installs bcrypt and docker Python libraries

You can disable automatic dependency management by setting:
```yaml
traefik_ensure_docker_installed: false
traefik_configure_firewall: false
```

## Example Playbook

### Basic Usage

```yaml
---
- hosts: servers
  roles:
    - traefik  # Automatically includes docker and iptables roles
```

### Advanced Configuration

```yaml
---
- hosts: servers
  vars:
    # Custom configuration
    traefik_acme_email: "ssl@example.com"
    traefik_dashboard_password: "secure-password-here"
    traefik_log_level: "DEBUG"
    
    # Enable metrics
    traefik_metrics_enabled: true
    traefik_metrics_prometheus: true
    
    # Enable rate limiting
    traefik_rate_limit_enabled: true
    traefik_rate_limit_average: 100
    traefik_rate_limit_burst: 200
    
  roles:
    - traefik
```

### Production Configuration with DNS Challenge

```yaml
---
- hosts: servers
  vars:
    traefik_certificate_type: "acme"
    traefik_acme_email: "ssl@yourdomain.com"
    traefik_acme_use_staging: false  # Production mode
    traefik_dashboard_password: "very-secure-password"
    
    # Use DNS challenge for wildcard certificates
    traefik_acme_challenge_type: "dns"
    traefik_acme_dns_provider: "cloudflare"  # or your DNS provider
    
    # Production logging
    traefik_log_level: "WARN"
    traefik_access_logs_enabled: true
    
    # Security settings
    traefik_hsts_enabled: true
    traefik_frame_deny: true
    
  roles:
    - traefik
```

### Custom Certificate Configuration

```yaml
---
- hosts: servers
  vars:
    traefik_dashboard_password: "very-secure-password"
    
    # Use custom certificates instead of ACME
    traefik_certificate_type: "custom"
    traefik_certificate_files:
      - cert: "/certificates/yourdomain.com.crt"
        key: "/certificates/yourdomain.com.key"
        stores:
          - default
      # Add wildcard certificate
      - cert: "/certificates/wildcard.yourdomain.com.crt"
        key: "/certificates/wildcard.yourdomain.com.key"
        stores:
          - wildcard
    
    # Security settings
    traefik_hsts_enabled: true
    traefik_frame_deny: true
    
  roles:
    - traefik

  pre_tasks:
    # Ensure certificate files are in place before running the role
    - name: Copy certificate files
      copy:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        mode: "0600"
      loop:
        - { src: "local/yourdomain.com.crt", dest: "/certificates/yourdomain.com.crt" }
        - { src: "local/yourdomain.com.key", dest: "/certificates/yourdomain.com.key" }
        - { src: "local/wildcard.yourdomain.com.crt", dest: "/certificates/wildcard.yourdomain.com.crt" }
        - { src: "local/wildcard.yourdomain.com.key", dest: "/certificates/wildcard.yourdomain.com.key" }
```

## Using Traefik with Other Services

Once Traefik is deployed, you can easily add other services to the same network and configure them with Docker labels:

```yaml
# docker-compose.yml for an application
services:
  app:
    image: nginx:alpine
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"
      - "traefik.http.routers.app.tls=true"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"
      - "traefik.http.services.app.loadbalancer.server.port=80"
    networks:
      - traefik-network

networks:
  traefik-network:
    external: true
```

## Middleware Usage

The role creates several pre-configured middlewares that you can use:

- `secure-headers` - Security headers including HSTS
- `default-headers` - Basic security headers
- `gzip-compress` - Compression middleware
- `cors-headers` - CORS headers
- `rate-limit` - Rate limiting (if enabled)

Example usage:
```yaml
labels:
  - "traefik.http.routers.app.middlewares=secure-headers,gzip-compress"
```

## Accessing the Dashboard

After deployment, you can access the Traefik dashboard at:
- `http://your-server-ip:8080/dashboard/` (if dashboard authentication is disabled)
- `https://traefik.yourdomain.com/dashboard/` (if configured with a domain and SSL)

Default credentials (if authentication is enabled):
- Username: `admin`
- Password: Value of `traefik_dashboard_password` variable

## File Structure

```
/opt/traefik/
├── docker-compose.yml    # Docker Compose configuration
├── traefik.yml          # Static configuration
├── config/              # Dynamic configuration directory
│   ├── dynamic.yml      # Dynamic routing configuration
│   └── middlewares.yml  # Middleware definitions
└── certs/               # SSL certificates directory
    └── acme.json       # Let's Encrypt certificates

# Note: Logs go to stdout/stderr (view with `docker logs traefik`)
```

## Troubleshooting

### Common Issues

1. **Permission denied on acme.json**
   - The role automatically sets the correct permissions (600) on the ACME file
   - If issues persist, check that the Traefik user owns the certificates directory

2. **Dashboard not accessible**
   - Check that the dashboard port (8080) is open on your firewall
   - Verify the `traefik_dashboard_enabled` variable is set to `true`

3. **SSL certificate issues**
   - Ensure your domain points to the server's IP address
   - Check that ports 80 and 443 are accessible from the internet for HTTP challenge
   - Verify the `traefik_acme_email` is set to a valid email address

4. **Services not being discovered**
   - Ensure your services are connected to the `traefik-network`
   - Check that `traefik.enable=true` label is set on your services
   - Verify the Docker socket is properly mounted

### Logs

Check Traefik logs for troubleshooting:
```bash
# View real-time logs (stdout/stderr)
docker logs traefik -f

# Last 100 lines
docker logs traefik --tail 100

# With timestamps
docker logs traefik -f --timestamps
```

## Security Considerations

1. **Change default passwords** - Always change the `traefik_dashboard_password`
2. **Use strong SSL settings** - The role enables secure SSL/TLS by default
3. **Limit dashboard access** - Consider using IP whitelisting for the dashboard
4. **Regular updates** - Keep the Traefik image updated
5. **Monitor logs** - Enable access logging and monitor for suspicious activity

## License

MIT
## Certificate Configuration

This role supports two certificate types controlled by a single variable `traefik_certificate_type`:

### ACME (Let's Encrypt) Certificates

This is the default configuration that automatically obtains and renews certificates from Let's Encrypt:

```yaml
traefik_certificate_type: "acme"  # This is the default
traefik_acme_email: "your-email@example.com"
traefik_acme_use_staging: false  # Set to true for testing
traefik_acme_challenge_type: "http"  # or "dns" or "tls"
```

### Custom Certificates

To use your own certificates, simply change the certificate type and provide certificate files:

```yaml
traefik_certificate_type: "custom"
traefik_certificate_files:
  - cert: "/certificates/yourdomain.com.crt"
    key: "/certificates/yourdomain.com.key"
    stores:
      - default
  # Add additional certificates as needed
  - cert: "/certificates/wildcard.yourdomain.com.crt"
    key: "/certificates/wildcard.yourdomain.com.key"
    stores:
      - wildcard
```

**Important**: When using custom certificates:
1. Certificate files must be placed on the server before running the role
2. Files will be automatically secured with correct permissions (600)
3. The role will warn if certificate files are missing
4. Traefik will use the certificate stores defined in the configuration 