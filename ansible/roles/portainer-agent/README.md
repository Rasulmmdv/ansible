# Portainer Agent Ansible Role

This role installs and configures the Portainer Agent, which allows remote management of Docker environments through a Portainer server.

## Requirements

- Docker
- Ansible 2.9+

## Role Variables

### Required Variables

None - all variables have sensible defaults.

### Optional Variables

- `portainer_agent_image`: Docker image for Portainer Agent (default: `portainer/agent:latest`)
- `portainer_agent_data_directory`: Data directory for agent (default: `/opt/portainer-agent`)
- `portainer_agent_compose_dir`: Docker compose directory (default: `/etc/portainer-agent`)
- `portainer_agent_user`: User to run the agent (default: `root`)
- `portainer_agent_group`: Group to run the agent (default: `root`)
- `portainer_agent_restart_policy`: Container restart policy (default: `always`)
- `portainer_agent_port`: Port to expose the agent on (default: `9001`)
- `portainer_agent_log_level`: Log level for the agent (default: `INFO`)
- `portainer_agent_edge`: Enable Edge agent mode (default: `false`)
- `portainer_agent_edge_key`: Edge agent key (required if edge mode is enabled)
- `portainer_agent_edge_id`: Edge agent ID (required if edge mode is enabled)
- `portainer_agent_insecure`: Disable TLS/HTTPS for HTTP communication (default: `true`)

## Dependencies

- `docker`

## Example Playbook

### Basic Usage

```yaml
- hosts: servers
  roles:
    - portainer-agent
```

### With Custom Configuration

```yaml
- hosts: servers
  vars:
    portainer_agent_port: "9002"
    portainer_agent_data_directory: "/data/portainer-agent"
    portainer_agent_log_level: "DEBUG"
  roles:
    - portainer-agent
```

### Edge Agent Mode

```yaml
- hosts: edge-servers
  vars:
    portainer_agent_edge: true
    portainer_agent_edge_key: "your-edge-key"
    portainer_agent_edge_id: "your-edge-id"
  roles:
    - portainer-agent
```

## What This Role Does

1. Creates the necessary directories for Portainer Agent
2. Generates a Docker Compose file with the agent configuration
3. Starts the Portainer Agent container
4. Configures the agent to listen on the specified port (default: 9001)

## Connecting to Portainer Server

After running this role, you can add the agent to your Portainer server by:

1. Going to your Portainer server web interface
2. Navigate to "Environments" → "Add Environment"
3. Select "Agent"
4. Enter the hostname/IP and port of the server where this agent is running
5. The agent will be available for remote management

## License

MIT 