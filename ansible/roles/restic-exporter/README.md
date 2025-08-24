# Restic Exporter Role

This Ansible role deploys the [restic-exporter](https://github.com/ngosang/restic-exporter) Prometheus exporter for monitoring Restic backup systems.

## Overview

The restic-exporter provides Prometheus metrics for Restic backup repositories, including:
- Backup success/failure status
- Snapshot counts and timestamps
- Backup sizes and file counts
- Repository health checks
- Lock information

## Requirements

- Docker (managed by `docker` role)
- Monitoring network (managed by `monitoring-stack` role)
- Restic repository access credentials

## Role Variables

### Core Configuration

```yaml
# Enable/disable the role
restic_exporter_enabled: true

# Container version
restic_exporter_version: "1.7.0"

# Container name and restart policy
restic_exporter_container_name: "restic-exporter"
restic_exporter_restart_policy: "unless-stopped"
```

### Network Configuration

```yaml
# Port configuration
restic_exporter_port: 8001
restic_exporter_internal_port: 8001
restic_exporter_network: "monitoring"
```

### Restic Repository Configuration

```yaml
# Repository settings (REQUIRED)
restic_exporter_restic_repository: "s3:s3.amazonaws.com/bucket-name"
restic_exporter_restic_password: "your-password"

# AWS S3 credentials (if using S3)
restic_exporter_aws_access_key_id: "your-access-key"
restic_exporter_aws_secret_access_key: "your-secret-key"

# Backblaze B2 credentials (if using B2)
restic_exporter_b2_account_id: "your-account-id"
restic_exporter_b2_account_key: "your-account-key"
```

### Environment Variables

```yaml
restic_exporter_environment:
  TZ: "UTC"
  REFRESH_INTERVAL: "1800"  # 30 minutes
  LOG_LEVEL: "INFO"
  EXIT_ON_ERROR: "False"
  NO_CHECK: "False"
  NO_STATS: "False"
  NO_LOCKS: "False"
  INCLUDE_PATHS: "False"
  INSECURE_TLS: "False"
```

### Volume Mounts

```yaml
restic_exporter_volumes:
  - "/host_path/restic/data:/data:ro"
```

## Usage

### Basic Usage

```yaml
- hosts: monitoring
  roles:
    - restic-exporter
```

### With Custom Configuration

```yaml
- hosts: monitoring
  vars:
    restic_exporter_restic_repository: "s3:s3.amazonaws.com/my-backups"
    restic_exporter_restic_password: "{{ vault_restic_password }}"
    restic_exporter_aws_access_key_id: "{{ vault_aws_access_key }}"
    restic_exporter_aws_secret_access_key: "{{ vault_aws_secret_key }}"
    restic_exporter_environment:
      REFRESH_INTERVAL: "3600"  # 1 hour
      LOG_LEVEL: "DEBUG"
  roles:
    - restic-exporter
```

## Tags

The role supports the following tags:

- `install`: Container creation and basic setup
- `configure`: Configuration and environment setup
- `validate`: Health checks and validation
- `always`: Always executed tasks

### Example Tag Usage

```bash
# Install only
ansible-playbook -t install playbook.yml

# Configure and validate
ansible-playbook -t configure,validate playbook.yml

# Skip validation
ansible-playbook --skip-tags validate playbook.yml
```

## Dependencies

- `docker`: Provides Docker runtime
- `monitoring-stack`: Provides monitoring network

## Monitoring Integration

### Prometheus Configuration

Add this to your Prometheus configuration:

```yaml
scrape_configs:
  - job_name: 'restic-exporter'
    static_configs:
      - targets: ['localhost:8001']
    scrape_interval: 30s
```

### Available Metrics

- `restic_check_success`: Repository health check status
- `restic_snapshots_total`: Total number of snapshots
- `restic_backup_timestamp`: Last backup timestamp
- `restic_backup_files_total`: Number of files in backup
- `restic_backup_size_total`: Total backup size in bytes
- `restic_locks_total`: Number of repository locks
- `restic_scrape_duration_seconds`: Scrape duration

### Grafana Dashboard

A reference Grafana dashboard is available in the [restic-exporter repository](https://github.com/ngosang/restic-exporter/tree/main/grafana).

## Security Considerations

- Never commit sensitive credentials to version control
- Use Ansible Vault or environment variables for secrets
- The container runs with non-root user (UID 1000)
- Repository data is mounted as read-only
- Health checks validate the exporter is working correctly

## Troubleshooting

### Common Issues

1. **Container won't start**: Check Docker logs with `docker logs restic-exporter`
2. **Metrics endpoint unreachable**: Verify port 8001 is accessible and not blocked by firewall
3. **Authentication errors**: Verify Restic repository credentials and permissions
4. **High resource usage**: Increase `REFRESH_INTERVAL` for remote repositories

### Debug Commands

```bash
# Check container status
docker ps -a | grep restic-exporter

# View container logs
docker logs restic-exporter

# Test metrics endpoint
curl http://localhost:8001/metrics

# Check container health
docker inspect restic-exporter | jq '.[0].State.Health'
```

## License

MIT License - see the [restic-exporter repository](https://github.com/ngosang/restic-exporter) for details.
