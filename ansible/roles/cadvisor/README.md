# Enhanced cAdvisor Ansible Role

This role deploys cAdvisor as a Docker container to expose comprehensive container-level metrics for Prometheus with enhanced monitoring capabilities.

## Features

### Core Functionality
- Installs cAdvisor using Docker Compose with pinned version (v0.49.1)
- Exposes metrics on port 8080 with health checks
- Creates required users, groups, and directories with proper permissions
- Enhanced volume mounts for comprehensive container monitoring

### Enhanced Monitoring
- **Resource Monitoring**: CPU, memory, disk I/O, network I/O monitoring
- **Container Lifecycle**: Start time, restart tracking, exit code monitoring
- **Performance Metrics**: CPU throttling, file descriptor usage, socket monitoring
- **Security Monitoring**: Root user detection, resource limit validation
- **Optimized Metrics**: Disabled unnecessary metrics to reduce storage overhead

### Alert Rules
- **Resource Alerts**: CPU, memory, disk usage thresholds (warning/critical)
- **Availability Alerts**: Container down, restart frequency, exit code errors
- **Performance Alerts**: CPU throttling, high file descriptor usage
- **Security Alerts**: Root user detection, containers without limits

## Configuration

### Default Configuration
```yaml
cadvisor_image: "gcr.io/cadvisor/cadvisor:v0.49.1"
cadvisor_container_name: "cadvisor"
cadvisor_data_dir: "/opt/monitoring/cadvisor"
cadvisor_ports:
  - "8080:8080"
```

### Enhanced Monitoring Settings
```yaml
cadvisor_monitoring:
  detailed_monitoring: true
  resource_thresholds:
    cpu_warning: 80
    cpu_critical: 95
    memory_warning: 85
    memory_critical: 95
  collection_interval: "30s"
  retention_period: "2m"
```

### Resource Limits
```yaml
cadvisor_resources:
  memory: "200Mi"
  memory_reservation: "100Mi"
  cpus: "0.5"
  cpu_reservation: "0.1"
```

## Usage

### Basic Usage
```yaml
- hosts: monitoring
  roles:
    - cadvisor
```

### With Custom Configuration
```yaml
- hosts: monitoring
  roles:
    - role: cadvisor
      vars:
        cadvisor_service_discovery_enabled: true
        cadvisor_monitoring:
          detailed_monitoring: true
          resource_thresholds:
            cpu_warning: 70
            cpu_critical: 90
```

## Integration

### Prometheus Integration
- Automatic service discovery file generation
- Enhanced scraping configuration with metric relabeling
- Alert rules deployment for container monitoring
- Optimized metric collection to reduce storage

### Grafana Dashboards
The role provides metrics suitable for:
- Container resource utilization dashboards
- Container lifecycle monitoring
- Performance bottleneck identification
- Security compliance monitoring

## Alert Rules

### Resource Alerts
- `ContainerHighCPUUsage`: CPU usage > 80% for 5 minutes
- `ContainerCriticalCPUUsage`: CPU usage > 95% for 2 minutes
- `ContainerHighMemoryUsage`: Memory usage > 85% for 5 minutes
- `ContainerCriticalMemoryUsage`: Memory usage > 95% for 2 minutes

### Availability Alerts
- `ContainerNotRunning`: Container not seen for 5 minutes
- `ContainerRestartTooOften`: Container restarting frequently
- `ContainerExitedWithError`: Container exited with non-zero code

### Performance Alerts
- `ContainerCPUThrottling`: CPU throttling detected
- `ContainerHighFileDescriptorUsage`: High file descriptor usage
- `ContainerHighDiskIO`: High disk I/O activity
- `ContainerHighNetworkIO`: High network I/O activity

### Security Alerts
- `ContainerRunningAsRoot`: Processes running as root
- `ContainerPrivilegedMode`: Containers without resource limits

## Testing

Run the included test script to validate the enhanced monitoring:

```bash
# Copy and run the test script
sudo cp /opt/monitoring/cadvisor/test_cadvisor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/test_cadvisor.sh
test_cadvisor.sh
```

## Monitoring Metrics

### Key Metrics Collected
- `container_cpu_usage_seconds_total`: CPU usage per container
- `container_memory_usage_bytes`: Memory usage per container
- `container_network_receive_bytes_total`: Network receive bytes
- `container_network_transmit_bytes_total`: Network transmit bytes
- `container_fs_usage_bytes`: Filesystem usage per container
- `container_last_seen`: Container last seen timestamp
- `container_start_time_seconds`: Container start time

### Enhanced Labels
- `container_name_clean`: Cleaned container name
- `container_image_name`: Short image name
- `container_short_id`: Short container ID
- `compose_service`: Docker Compose service name
- `compose_project`: Docker Compose project name

## Security Features

- No-new-privileges security option
- Read-only volume mounts where possible
- Non-root user execution
- Resource limits to prevent resource exhaustion
- Security monitoring and alerting

## Maintenance

### Health Checks
- HTTP health endpoint at `/healthz`
- Metrics endpoint validation
- Prometheus integration validation

### Troubleshooting
- Check cAdvisor logs: `docker logs cadvisor`
- Verify metrics: `curl http://localhost:8080/metrics`
- Test health: `curl http://localhost:8080/healthz`
- Run test suite: `test_cadvisor.sh`

## Requirements

- Docker and Docker Compose
- Prometheus for metric collection
- Network connectivity to monitored containers
- Sufficient permissions to access Docker socket

## Dependencies

- docker role (for Docker installation)
- prometheus role (for metric collection)
- monitoring-stack role (for orchestration) 