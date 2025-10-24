# Restic Exporter Deployment Guide

This guide provides step-by-step instructions for deploying the Restic Exporter Ansible role across your infrastructure.

## Prerequisites

### System Requirements
- Ansible 2.10+ installed on control machine
- Docker and Docker Compose on target hosts
- Restic already configured and running backups
- Central Prometheus and Grafana setup

### Required Collections
```bash
ansible-galaxy collection install community.docker grafana.grafana
```

## Quick Start

### 1. Prepare Inventory

Create your inventory file based on the example:

```bash
cp inventory_restic_example.yml inventory.yml
# Edit inventory.yml with your actual hosts
```

### 2. Configure Variables

Set up group variables:

```bash
# Copy and customize group variables
cp group_vars/restic_hosts.yml group_vars/restic_hosts.yml
cp group_vars/monitoring.yml group_vars/monitoring.yml

# Create vault for sensitive data
cp group_vars/vault.yml.example group_vars/vault.yml
# Edit vault.yml with your secrets
ansible-vault encrypt group_vars/vault.yml
```

### 3. Deploy the Role

```bash
# Deploy to all hosts
ansible-playbook -i inventory.yml playbooks/restic_exporter.yml --vault-password-file .vault_pass

# Or deploy to specific groups
ansible-playbook -i inventory.yml playbooks/restic_exporter.yml --limit restic_hosts --vault-password-file .vault_pass
ansible-playbook -i inventory.yml playbooks/restic_exporter.yml --limit monitoring --vault-password-file .vault_pass
```

## Detailed Configuration

### Inventory Groups

The role expects these inventory groups:

- **`restic_hosts`**: Hosts that will run the restic-exporter
- **`monitoring`**: Central monitoring host with Prometheus/Grafana

### Key Variables to Customize

#### For Restic Hosts (`group_vars/restic_hosts.yml`)
```yaml
# Exporter port (default: 8001)
exporter_port: 8001

# Refresh interval in seconds (default: 1800 = 30 minutes)
refresh_interval: 1800

# Backup directory structure
backup_base_dir: "/opt/kimdev/backup"

# User/group IDs for restic
restic_uid: 995
restic_gid: 1003
```

#### For Monitoring Host (`group_vars/monitoring.yml`)
```yaml
# Alert thresholds
stale_days: 1  # Alert if backup older than 1 day
pending_period: "30m"  # Wait before firing alert
repeat_interval: "1d"  # How often to repeat alerts

# Prometheus paths
prometheus_config_dir: "/opt/monitoring/prometheus/config"
prometheus_rules_dir: "/opt/monitoring/prometheus/rules"
prometheus_targets_dir: "/opt/monitoring/prometheus/config/targets"

# Grafana configuration
grafana_url: "http://localhost:3000"
dashboard_id: 17554  # Restic Exporter dashboard
```

#### Sensitive Variables (`group_vars/vault.yml`)
```yaml
# Restic repository credentials
restic_repository: "s3:https://storage.yandexcloud.net/backupsdi"
restic_password: "your-restic-password"
aws_access_key_id: "your-aws-key"
aws_secret_access_key: "your-aws-secret"

# Grafana API token
vault_grafana_token: "your-grafana-token"
```

## Verification Steps

### 1. Check Exporter Status

On each restic host:
```bash
# Check container is running
docker ps | grep restic-exporter

# Check health status
docker inspect restic-exporter | grep -A 10 Health

# Test metrics endpoint
curl localhost:8001/metrics | grep restic_backup_timestamp
```

### 2. Verify Prometheus Integration

1. Access Prometheus UI: `http://monitoring-host:9090`
2. Go to Status → Targets
3. Look for `restic-exporter` job
4. Verify all targets are UP
5. Query: `restic_backup_timestamp`

### 3. Check Grafana Dashboard

1. Access Grafana: `http://monitoring-host:3000`
2. Search for "Restic" dashboard
3. Verify metrics are displaying
4. Check different time ranges

### 4. Test Alerting

1. Go to Grafana → Alerting → Alert Rules
2. Find "Restic Backup Stale" rule
3. Check rule status and evaluation
4. Temporarily lower threshold to test alert firing

## Troubleshooting

### Common Issues

#### Exporter Not Starting
```bash
# Check container logs
docker logs restic-exporter

# Verify S3 connectivity
docker exec restic-exporter restic snapshots

# Check environment variables
docker exec restic-exporter env | grep RESTIC
```

#### Prometheus Not Scraping
```bash
# Check targets file exists
ls -la /opt/monitoring/prometheus/config/targets/restic_targets.json

# Verify file content
cat /opt/monitoring/prometheus/config/targets/restic_targets.json

# Test connectivity from monitoring host
curl http://backup-host:8001/metrics
```

#### Grafana Dashboard Missing
```bash
# Check API response
curl -H "Authorization: Bearer $GRAFANA_TOKEN" \
  http://localhost:3000/api/dashboards/db/restic

# Verify dashboard import
curl -H "Authorization: Bearer $GRAFANA_TOKEN" \
  http://localhost:3000/api/dashboards/uid/restic
```

### Network Issues

#### Monitoring Network
```bash
# Check if monitoring network exists
docker network ls | grep monitoring

# Create if missing
docker network create monitoring

# Verify containers are on the network
docker network inspect monitoring
```

#### Firewall Rules
Ensure these ports are open:
- `8001` (exporter metrics)
- `9090` (Prometheus)
- `3000` (Grafana)

## Maintenance

### Updating the Role

```bash
# Re-run the playbook to update configuration
ansible-playbook -i inventory.yml playbooks/restic_exporter.yml --vault-password-file .vault_pass
```

### Scaling to New Hosts

1. Add new hosts to `restic_hosts` group in inventory
2. Run playbook with `--limit` for new hosts
3. Prometheus will automatically discover new targets

### Backup and Recovery

The role creates these important files:
- Docker Compose: `/opt/kimdev/backup/config/docker-compose.yml`
- Prometheus config: `/opt/monitoring/prometheus/config/scrape_restic.yml`
- Alert rules: `/opt/monitoring/prometheus/rules/restic_rules.yml`
- Targets: `/opt/monitoring/prometheus/config/targets/restic_targets.json`

Backup these files for disaster recovery.

## Security Best Practices

1. **Use Ansible Vault** for all sensitive variables
2. **Restrict network access** to monitoring ports
3. **Regular updates** of exporter image and Ansible role
4. **Monitor access logs** for Prometheus and Grafana
5. **Use TLS** in production environments
6. **Rotate credentials** regularly

## Support

For issues or questions:
1. Check the role README: `roles/restic_exporter/README.md`
2. Review Ansible logs with `-vvv` flag
3. Check container and service logs
4. Verify network connectivity and firewall rules
