# Jenkins SSH Agent Docker Role

This Ansible role deploys a Jenkins SSH agent as a Docker container using the official `jenkins/ssh-agent` image.

## Features

- Automatically generates SSH key pair for agent authentication
- Deploys Jenkins SSH agent in a Docker container
- Configures Docker networking for agent-master communication
- Provides SSH public key for Jenkins credentials setup
- Supports Docker-in-Docker capabilities
- Configurable through Ansible variables

## Requirements

- Docker must be installed on the target host
- The target host should have network connectivity to the Jenkins master
- The Docker daemon must be running
- Ansible community.docker collection must be installed

## Role Variables

### Required Variables

No required variables - all have sensible defaults.

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `jenkins_ssh_agent_image` | Docker image to use | `jenkins/ssh-agent:jdk21` |
| `jenkins_ssh_agent_container_name` | Name of the Docker container | `jenkins-ssh-agent` |
| `jenkins_ssh_key_path` | Path to store SSH keys | `/opt/jenkins/ssh` |
| `jenkins_ssh_key_name` | Name of the SSH key file | `jenkins_agent_key` |
| `jenkins_ssh_key_type` | Type of SSH key | `rsa` |
| `jenkins_ssh_key_bits` | SSH key size in bits | `4096` |
| `jenkins_ssh_key_comment` | SSH key comment | `jenkins-agent` |
| `jenkins_master_url` | URL of the Jenkins master | `http://jenkins:8080` |
| `jenkins_ssh_agent_name` | Name of the agent in Jenkins | `docker-ssh-agent` |
| `jenkins_ssh_agent_workdir` | Working directory inside container | `/home/jenkins/agent` |
| `jenkins_network_name` | Docker network name | `jenkins-network` |
| `jenkins_ssh_agent_restart_policy` | Docker restart policy | `always` |
| `jenkins_ssh_agent_force_pull` | Force pull image on deployment | `true` |

### Volume Mounts

The role mounts the following volumes by default:
- `/var/run/docker.sock:/var/run/docker.sock` - Docker socket for Docker-in-Docker
- `/tmp:/tmp` - Temporary directory

## Dependencies

This role depends on:
- `docker` role - for Docker installation and configuration

## Example Playbook

### Basic Usage

```yaml
- hosts: jenkins_agents
  roles:
    - role: jenkins-ssh-agent-docker
```

### Advanced Configuration

```yaml
- hosts: jenkins_agents
  roles:
    - role: jenkins-ssh-agent-docker
      vars:
        jenkins_ssh_agent_name: "{{ inventory_hostname }}-ssh-agent"
        jenkins_ssh_key_path: "/opt/custom/jenkins/ssh"
        jenkins_network_name: "custom-jenkins-network"
```

## Setting up the Jenkins SSH Agent

1. **Run the playbook:**
   ```bash
   ansible-playbook -i inventory.yml playbooks/jenkins-ssh-agent.yml
   ```

2. **In Jenkins Master:**
   - Go to "Manage Jenkins" → "Manage Credentials"
   - Click "System" → "Global credentials" → "Add Credentials"
   - Select "SSH Username with private key"
   - Configure:
     - ID: `jenkins-ssh-key`
     - Username: `jenkins`
     - Private Key: Select "Enter directly" and paste the private key content
     - Description: "Jenkins SSH Agent Key"

3. **Create the Agent Node:**
   - Go to "Manage Jenkins" → "Manage Nodes and Clouds"
   - Click "New Node"
   - Enter the agent name (should match `jenkins_ssh_agent_name`)
   - Select "Permanent Agent"
   - Configure:
     - Remote root directory: `/home/jenkins/agent`
     - Labels: `docker linux ssh`
     - Launch method: "Launch agents via SSH"
     - Host: IP or hostname of Docker host
     - Credentials: Select the SSH key credential created earlier
     - Host Key Verification Strategy: "Manually trusted key Verification Strategy"

## Docker Network

The role creates or uses a Docker network named `jenkins-network` by default. This allows the agent to communicate with the Jenkins master if both are running as Docker containers on the same host.

## Security Considerations

- SSH keys are stored in a secure directory with restricted permissions
- The agent runs with Docker socket access, which provides root-equivalent privileges
- Consider using a dedicated Docker network for Jenkins components
- Regularly update the Jenkins agent image for security patches

## Troubleshooting

### Agent Not Connecting

1. Check if the Jenkins master is accessible from the agent host
2. Verify the SSH key is correctly added to Jenkins credentials
3. Check Docker logs: `docker logs jenkins-ssh-agent`
4. Ensure the Docker network allows communication

### Permission Issues

1. Verify the SSH key permissions (should be 600)
2. Check volume mount permissions
3. Ensure the working directory has correct ownership

## License

MIT
