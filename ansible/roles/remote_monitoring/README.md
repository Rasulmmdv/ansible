# Remote Monitoring Role

This Ansible role orchestrates remote monitoring by setting up Nginx Exporter on remote machines and updating Prometheus configuration on the monitoring server to scrape these metrics.

## Overview

The `remote_monitoring` role is designed to work with your existing monitoring infrastructure that includes:
- Prometheus (on monitoring server)
- Grafana (on monitoring server)
- Blackbox Exporter (on monitoring server)

This role adds Nginx monitoring capabilities to remote machines with Docker-based Nginx by:
1. Configuring Docker-based Nginx with `stub_status` endpoint on remote machines
2. Deploying Nginx Exporter via Docker on remote machines
3. Updating Prometheus configuration on the monitoring server to scrape remote metrics

## Architecture

```
┌─────────────────┐    VPN Network    ┌─────────────────┐
│   Remote Server │◄─── 10.0.0.0/24 ──►│ Monitoring Server│
│                 │                   │                 │
│ Nginx Container │                   │ Prometheus      │
│ + Nginx Exporter│                   │ + Grafana       │
│ (port 9113)     │                   │ + Alertmanager  │
└─────────────────┘                   └─────────────────┘
```

## Prerequisites

### On Remote Machine
- Docker installed and running
- **Docker-based Nginx already deployed and running** (this role will NOT install Nginx)
- Network connectivity to monitoring server

### On Monitoring Server
- Prometheus running and accessible
- Prometheus configuration writable

## Role Structure

```
roles/remote_monitoring/
├── defaults/main.yml          # Configuration variables
├── tasks/
│   ├── main.yml              # Main task orchestration
│   ├── prerequisites.yml     # User/directory setup
│   ├── nginx_config.yml      # Nginx stub_status configuration
│   ├── nginx_exporter.yml    # Nginx Exporter deployment
│   ├── prometheus_config.yml # Prometheus configuration update
│   └── cleanup.yml           # Cleanup tasks for removed hosts
├── handlers/main.yml          # Service restart handlers
├── templates/
│   ├── nginx_stub_status.conf.j2       # Nginx configuration
│   ├── docker-compose.yml.j2           # Nginx Exporter container
│   ├── host_target.yml.j2              # Individual host target file
│   └── prometheus_scrape_config.yml.j2 # Prometheus scrape config
├── files/verify_remote_monitoring.sh   # Verification script
├── meta/main.yml             # Role metadata
└── README.md                 # This file
```

## Dynamic File-Based Service Discovery

This role implements a dynamic file-based service discovery pattern for Prometheus:

1. **Individual Target Files**: Each monitored host gets its own target file (`{hostname}_nginx.yml`) in the Prometheus targets directory
2. **Automatic Discovery**: Prometheus automatically discovers new targets and removes old ones based on file presence
3. **No Configuration Reloads**: Adding/removing hosts doesn't require Prometheus configuration changes
4. **Scalable**: Supports hundreds of remote hosts without performance degradation

### File Structure on Monitoring Server
```
/opt/monitoring/prometheus/config/
├── targets/
│   ├── prod-01_nginx.yml     # Target for prod-01
│   ├── prod-02_nginx.yml     # Target for prod-02
│   └── dev-01_nginx.yml      # Target for dev-01
└── scrape_configs/
    └── remote_nginx.yml      # Scrape configuration
```

## Quick Start

### 1. Configure Your Inventory
Set the required variables per host in your inventory (see `INVENTORY_EXAMPLES.md` for details):

```yaml
---
all:
  children:
    production:
      hosts:
        prod-01:
          ansible_host: 188.124.37.101
          monitoring_server_host: "infra-01"
          nginx_status_allowed_ips:
            - "127.0.0.1"
            - "::1"
            - "10.0.0.5"
          remote_monitoring_labels:
            instance: "prod-01"
            environment: "production"
            service: "nginx"
          remote_monitoring_scrape_interval: "15s"
    
    development:
      hosts:
        dev-01:
          ansible_host: 192.168.1.100
          monitoring_server_host: "192.168.1.16"
          nginx_status_allowed_ips:
            - "127.0.0.1"
            - "::1"
            - "192.168.1.16"
          remote_monitoring_labels:
            instance: "dev-01"
            environment: "development"
            service: "nginx"
          remote_monitoring_scrape_interval: "30s"
```

### 2. Run the Playbook
```bash
# Deploy to all configured servers
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml

# Or deploy to specific groups
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml --limit production
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml --limit development

# Or deploy to specific server
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml --limit dev-01
```

### 3. What Gets Deployed

#### On Remote Machine:
- Nginx stub_status endpoint at `/nginx_status` to Docker-based Nginx
- Nginx Exporter container on port 9113
- Docker monitoring network

#### On Monitoring Server (infra-01):
- Prometheus configuration updated with remote scrape job
- Prometheus container restarted
- VPN Network: Communication via VPN network (10.0.0.0/24)

### 4. Verification
```bash
# Check Nginx stub_status
curl http://remote-machine:80/nginx_status

# Check Nginx Exporter metrics
curl http://remote-machine:9113/metrics

# Check Prometheus targets
curl http://infra-01:9090/targets

# Run verification script
./ansible/roles/remote_monitoring/files/verify_remote_monitoring.sh
```

## Configuration Variables

### Nginx Exporter Settings
- `nginx_exporter_image`: Docker image for Nginx Exporter (default: `nginx/nginx-prometheus-exporter:latest`)
- `nginx_exporter_port`: Port for exposing metrics (default: `9113`)
- `nginx_stub_status_url`: Nginx stub status endpoint (default: `http://localhost:80/nginx_status`)

### Docker-based Nginx Configuration
- `nginx_docker_container_name`: Nginx container name (default: `nginx`)
- `nginx_docker_config_dir`: Nginx config directory (default: `/data/nginx/nginx_conf`)

### Security Settings
- `nginx_status_allowed_ips`: List of IPs allowed to access nginx_status endpoint
- `nginx_exporter_user_id`: User ID for Nginx Exporter container (default: `65531`)
- `nginx_exporter_group_id`: Group ID for Nginx Exporter container (default: `65531`)

### Prometheus Integration
- `monitoring_server_host`: Hostname of the monitoring server (required)
- `prometheus_config_dir`: Prometheus configuration directory (default: `/opt/monitoring/prometheus/config`)
- `remote_monitoring_job_name`: Job name in Prometheus (default: `nginx_remote`)
- `remote_monitoring_scrape_interval`: Scrape interval (default: `15s`)

### Labels and Metadata
- `remote_monitoring_labels`: Labels to apply to metrics in Prometheus

## Advanced Usage

### Custom Playbook
```yaml
---
- hosts: your_servers
  vars:
    nginx_docker_container_name: "nginx"
    nginx_docker_config_dir: "/data/nginx/nginx_conf"
    # Set these per host in inventory for maximum flexibility
    # monitoring_server_host: "your-monitoring-server"
    # nginx_status_allowed_ips: ["127.0.0.1", "::1", "your-monitoring-ip"]
    # remote_monitoring_labels: {...}
  roles:
    - remote_monitoring
```

### Per-Host Configuration
The role is designed to be configured per host in your inventory for maximum flexibility:

```yaml
# In your inventory
your-server:
  ansible_host: 192.168.1.100
  monitoring_server_host: "192.168.1.16"
  nginx_status_allowed_ips:
    - "127.0.0.1"
    - "::1"
    - "192.168.1.16"
  remote_monitoring_labels:
    instance: "your-server"
    environment: "development"
    service: "nginx"
  remote_monitoring_scrape_interval: "30s"
```

## Metrics Available

The Nginx Exporter provides the following key metrics:

- `nginx_requests_total`: Total number of HTTP requests
- `nginx_connections_active`: Number of active connections
- `nginx_connections_reading`: Number of connections reading
- `nginx_connections_writing`: Number of connections writing
- `nginx_connections_waiting`: Number of connections waiting

## VPN Network Integration

This role is configured for VPN network communication:

### Network Architecture
```
┌─────────────────┐    VPN Network    ┌─────────────────┐
│   prod-01       │◄─── 10.0.0.0/24 ──►│   infra-01      │
│ 188.124.37.101  │                   │   10.0.0.5      │
│                 │                   │ (Monitoring)    │
│ Nginx Container │                   │ Prometheus      │
│ + Nginx Exporter│                   │ + Grafana       │
└─────────────────┘                   └─────────────────┘
```

### Security Benefits
- **Encrypted communication** via WireGuard VPN
- **Private network** - no public IP exposure
- **Controlled access** - only VPN members can access

## Important Notes

- **IMPORTANT**: This role is designed for Docker-based Nginx setups only. It assumes Nginx is already deployed as a Docker container.
- Docker must be available on the remote machine
- The monitoring server must be accessible from the remote machine
- Prometheus configuration is updated on the monitoring server, not the remote machine
- Metrics are exposed on port 9113 by default (configurable)
- Communication happens via VPN network (10.0.0.0/24)

## Troubleshooting

### Common Issues:

1. **Nginx stub_status not accessible**
   - Check if Nginx container is running: `docker ps | grep nginx`
   - Verify configuration: `docker exec nginx nginx -t`
   - Check if stub_status config was added: `docker exec nginx cat /etc/nginx/conf.d/default.conf`
   - **Volume-mounted configurations**: If nginx configuration is volume-mounted from the host, the role will automatically detect this and update the source file on the host instead of inside the container.

2. **Nginx Exporter not starting**
   - Check Docker logs: `docker logs nginx_exporter`
   - Verify nginx_status endpoint is accessible
   - Check port 9113 is not in use
   - Verify Docker network exists
   - Ensure correct environment variable `SCRAPE_URI` is set

3. **Prometheus not scraping**
   - Check Prometheus configuration: `docker exec prometheus cat /etc/prometheus/prometheus.yml`
   - Verify VPN network connectivity between monitoring server and remote machine
   - Check Prometheus logs: `docker logs prometheus`
   - Verify target appears in `/targets` page

### Volume-Mounted Nginx Configurations

If your Nginx container uses volume-mounted configuration files (common in production setups), the role will:

1. **Detect volume mounts** automatically by inspecting the container
2. **Update the source file** on the host instead of inside the container
3. **Create backups** of the original configuration
4. **Handle both volume-mounted and standard configurations** seamlessly

Example volume mount detection:
```bash
# The role detects mounts like this:
docker inspect nginx_container | grep -A 10 Mounts
# Output: "Source": "/root/nginx.conf", "Destination": "/etc/nginx/conf.d/default.conf"
```

### Verification Commands
```bash
# Check Nginx container
docker ps | grep nginx
docker exec nginx nginx -t
curl http://localhost/nginx_status

# Check Nginx Exporter
docker ps | grep nginx_exporter
curl http://localhost:9113/metrics
docker logs nginx_exporter

# Check networks
docker network ls | grep -E "(monitoring|nginx_network)"
docker inspect nginx_exporter | grep -A 10 "Networks"

# Check volume mounts
docker inspect nginx_container | grep -A 10 "Mounts"
```

## Security Considerations

1. **Access Control**: The nginx_status endpoint is restricted to specified IPs
2. **Network Isolation**: Use Docker networks for container communication
3. **User Permissions**: Nginx Exporter runs as non-root user
4. **Firewall**: Ensure only necessary ports are open (80, 9113)
5. **VPN Security**: All monitoring traffic goes through encrypted VPN

## Integration with Existing Roles

This role is designed to work alongside your existing:
- `blackbox_exporter` role (for endpoint availability monitoring)
- `prometheus` role (for metrics collection)
- `grafana` role (for visualization)

The role follows the same patterns and conventions as your existing monitoring roles.

## Usage

The role comes with a ready-to-run playbook that works with your existing inventory:

```bash
# Deploy to all configured servers
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml

# Deploy only to production servers
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml --limit production

# Deploy only to test servers
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml --limit test
```

## Cleanup and Removal

When a host is removed from monitoring, you can run the cleanup tasks:

```bash
# Include cleanup tasks in your playbook
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml --tags cleanup

# Or manually run cleanup
ansible-playbook -i ansible/all/inventory.yml ansible/playbooks/remote_monitoring.yml --tags cleanup --limit hostname
```

The cleanup process:
1. Removes the target file from Prometheus configuration
2. Stops and removes the nginx_exporter container
3. Removes the nginx_exporter data directory
4. Reloads Prometheus configuration

## Files Created

### On Remote Machine
- `/data/nginx/nginx_conf/conf.d/stub_status.conf` - Nginx stub_status configuration
- `/opt/monitoring/nginx_exporter/` - Nginx Exporter data directory
- `/opt/monitoring/nginx_exporter/docker-compose.yml` - Nginx Exporter container configuration

### On Monitoring Server
- `/opt/monitoring/prometheus/config/targets/{hostname}_nginx.yml` - Individual host target file
- `/opt/monitoring/prometheus/config/scrape_configs/remote_nginx.yml` - Prometheus scrape configuration

## Notes

- **IMPORTANT**: This role is designed for Docker-based Nginx setups only. It assumes Nginx is already deployed as a Docker container.
- Docker must be available on the remote machine
- The monitoring server must be accessible from the remote machine
- Prometheus configuration is updated on the monitoring server, not the remote machine
- Metrics are exposed on port 9113 by default (configurable)
- **Dynamic Discovery**: Prometheus automatically discovers new targets and removes old ones without configuration reloads 