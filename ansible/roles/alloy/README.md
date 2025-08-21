# Grafana Alloy Ansible Role

This role deploys Grafana Alloy as a Docker container for collecting logs from Docker containers and systemd journald, forwarding them to Loki.

## Features
- Installs Grafana Alloy using Docker Compose
- Automatically discovers and collects logs from all Docker containers
- Collects logs from systemd journald (including container logs using journald driver)
- Forwards logs to Loki for centralized storage and querying
- Provides rich metadata including container names, images, services, and systemd units

## Usage
Include this role in your playbook:
```yaml
- hosts: all
  roles:
    - loki
    - alloy
```

## Architecture

```
+-------------------+        +-------------------+
|   Docker Containers|        |   Systemd Journald|
|  +-------------+  |        |  +-------------+  |
|  | Container 1 |  |        |  | Container   |  |
|  | Container 2 |  |        |  | System      |  |
|  | Container 3 |  |        |  | Service     |  |
|  +-------------+  |        |  +-------------+  |
+-------------------+        |  +-------------+  |
         |   |                        |   |
         |   +------------------------+   |
         |                              |
         +------------------------------+
                        |
                        v
               +----------------+
               |  Grafana Alloy |
               +----------------+
                        |
                        v
               +----------------+
               |     Loki       |
               +----------------+
                        |
                        v
               +----------------+
               |    Grafana     |
               +----------------+
```

## Configuration

### Default Variables

```yaml
alloy_image: "grafana/alloy:latest"
alloy_container_name: "alloy"
alloy_data_dir: "/opt/monitoring/alloy"
alloy_ports:
  - "12345:12345"

# Journald configuration
alloy_enable_journald: true  # Enables journald log collection
```

### Log Collection Features

The Alloy configuration automatically:

1. **Discovers Docker containers** using the Docker socket
2. **Collects logs** from all running containers
3. **Collects systemd journald logs** including:
   - Container logs using journald driver
   - System service logs
   - Application logs
4. **Adds metadata** including:
   - Container name and ID
   - Container image
   - Docker Compose service name (if applicable)
   - Host instance name
   - Log stream information
   - Systemd unit name
   - Syslog identifier
   - Priority level
5. **Forwards logs** to Loki for storage and querying

## Integration with Grafana

When deployed with the Grafana role, logs will be available in Grafana dashboards:

1. Go to Grafana (http://your-server:3000)
2. Navigate to Explore
3. Select "Loki" as the data source
4. Query logs using LogQL syntax

### Example LogQL Queries

#### Docker Container Logs
```logql
# All Docker container logs
{job="integrations/docker"}

# Logs from a specific container
{container="your-container-name"}

# Logs from containers with a specific image
{image="nginx:latest"}

# Logs from a specific service
{service="web"}

# Error logs
{job="integrations/docker"} |= "error"
```

#### Journald Logs
```logql
# All journald logs
{job="integrations/journald"}

# Logs from a specific systemd unit
{unit="docker.service"}

# Container logs using journald driver
{container!=""}

# System service logs
{unit=~".*\.service"}

# High priority logs
{priority="err"}

# Logs from a specific container ID
{container_id="abc123"}

# Combined query for all logs
{job=~"integrations/(docker|journald)"}
```

## Monitoring

- Alloy exposes metrics on port 12345
- Logs are automatically forwarded to Loki
- Container discovery happens automatically
- Journald log collection includes all systemd units
- No manual configuration required for new containers or services

## Troubleshooting

### Check Alloy Status
```bash
docker ps | grep alloy
docker logs alloy
```

### Check Loki Status
```bash
docker ps | grep loki
docker logs loki
```

### Verify Log Collection
1. Access Grafana at http://your-server:3000
2. Go to Explore → Loki
3. Run queries:
   - `{job="integrations/docker"}` for Docker logs
   - `{job="integrations/journald"}` for journald logs

### Common Issues

1. **No logs appearing**: Check if Alloy and Loki are running
2. **Permission denied**: Ensure Docker socket and journald access
3. **Network issues**: Verify containers are on the same Docker network
4. **Journald access**: Ensure Alloy has proper capabilities (SYS_ADMIN, SYS_PTRACE)

### Journald-Specific Issues

1. **No journald logs**: Check if `/var/log/journal` and `/run/log/journal` are mounted
2. **Permission errors**: Ensure Alloy container has privileged access
3. **Missing units**: Verify systemd units are running and accessible 