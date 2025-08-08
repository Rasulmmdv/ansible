# Loki Role

This Ansible role deploys and configures Grafana Loki for log aggregation and storage.

## Features

- Deploys Loki using Docker Compose
- Configures log retention policies
- Sets up monitoring and alerting
- Integrates with Prometheus for metrics collection
- **NEW**: File-based service discovery for Prometheus targets

## Prometheus Integration

Loki is automatically registered with Prometheus using file-based service discovery:

### Automatic Registration
- Loki automatically creates a targets file at `/opt/monitoring/prometheus/targets/loki_targets.yml`
- Prometheus automatically discovers and scrapes Loki metrics from `loki:3100/metrics`
- Configuration is reloaded automatically when targets change

### Target File Format
The targets file follows Prometheus file-based service discovery format:

```yaml
---
- targets:
    - loki:3100
  labels:
    job: loki
    instance: loki
    service: logging
    component: log-aggregator
```

## Configuration

### Default Variables

```yaml
loki_image: "grafana/loki:latest"
loki_container_name: "loki"
loki_data_dir: "/opt/loki"
loki_ports:
  - "3100:3100"
```

### Storage Configuration

Loki is configured with:
- **Local filesystem storage** for simplicity
- **TSDB index** for efficient querying
- **24-hour index periods** for optimal performance
- **Single replication factor** for development/testing

## Integration

### With Grafana Alloy
- Alloy automatically forwards Docker container logs to Loki
- No manual configuration required
- Rich metadata preserved (container names, images, services)

### With Grafana
- Loki is automatically configured as a data source in Grafana
- Logs can be queried using LogQL syntax
- Available in Grafana Explore and dashboards

## LogQL Queries

Once deployed, you can query logs in Grafana using LogQL:

```logql
# All Docker container logs
{job="docker"}

# Logs from specific containers
{container="nginx"}

# Error logs
{job="docker"} |= "error"

# Logs with specific labels
{image="nginx:latest"}

# Time-range queries
{job="docker"} [1h]
```

## Monitoring

- Loki exposes metrics on port 3100
- Storage metrics available for monitoring
- Query performance metrics tracked
- Integration with Prometheus for metrics collection

## Troubleshooting

### Check Loki Status
```bash
docker ps | grep loki
docker logs loki
```

### Check Storage
```bash
ls -la /opt/loki/data/
ls -la /opt/loki/tsdb-index/
```

### Verify Log Ingestion
1. Access Grafana at http://your-server:3000
2. Go to Explore → Loki
3. Run query: `{job="docker"}`

### Common Issues

1. **No logs appearing**: Check if Alloy is running and forwarding logs
2. **Storage issues**: Verify disk space and permissions
3. **Network issues**: Ensure containers are on the same Docker network 