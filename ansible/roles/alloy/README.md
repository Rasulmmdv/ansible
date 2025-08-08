# Grafana Alloy Ansible Role

This role deploys Grafana Alloy as a Docker container for collecting logs from Docker containers and forwarding them to Loki.

## Features
- Installs Grafana Alloy using Docker Compose
- Automatically discovers and collects logs from all Docker containers
- Forwards logs to Loki for centralized storage and querying
- Provides rich metadata including container names, images, and services

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
|   Docker Containers|        |   Docker Containers|
|  +-------------+  |        |  +-------------+  |
|  | Container 1 |  |        |  | Container 2 |  |
|  | Container 2 |  |        |  | Container 3 |  |
|  +-------------+  |        |  +-------------+  |
+-------------------+        +-------------------+
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
alloy_data_dir: "/opt/alloy"
alloy_ports:
  - "12345:12345"
```

### Log Collection Features

The Alloy configuration automatically:

1. **Discovers Docker containers** using the Docker socket
2. **Collects logs** from all running containers
3. **Adds metadata** including:
   - Container name
   - Container image
   - Docker Compose service name (if applicable)
   - Host instance name
   - Log stream information
4. **Forwards logs** to Loki for storage and querying

## Integration with Grafana

When deployed with the Grafana role, logs will be available in Grafana dashboards:

1. Go to Grafana (http://your-server:3000)
2. Navigate to Explore
3. Select "Loki" as the data source
4. Query logs using LogQL syntax

### Example LogQL Queries

```logql
# All Docker container logs
{job="docker"}

# Logs from a specific container
{container="your-container-name"}

# Logs from containers with a specific image
{image="nginx:latest"}

# Logs from a specific service
{service="web"}

# Error logs
{job="docker"} |= "error"

# Logs from the last 1 hour
{job="docker"} [1h]
```

## Monitoring

- Alloy exposes metrics on port 12345
- Logs are automatically forwarded to Loki
- Container discovery happens automatically
- No manual configuration required for new containers

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
3. Run query: `{job="docker"}`

### Common Issues

1. **No logs appearing**: Check if Alloy and Loki are running
2. **Permission denied**: Ensure Docker socket is accessible
3. **Network issues**: Verify containers are on the same Docker network 