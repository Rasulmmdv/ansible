# node_exporter Ansible Role

This role deploys node_exporter as a Docker container to expose host-level metrics for Prometheus.

## Features
- Installs node_exporter using Docker Compose
- Exposes metrics on port 9100
- Creates required users, groups, and directories

## Usage
Include this role in your playbook:
```yaml
- hosts: all
  roles:
    - node_exporter
```

## Integration
- Prometheus scrapes metrics from node_exporter
- Metrics are visualized in Grafana via Prometheus 