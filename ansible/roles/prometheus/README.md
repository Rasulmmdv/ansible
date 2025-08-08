# Prometheus Ansible Role

This role deploys Prometheus as a Docker container for metrics aggregation and monitoring.

## Features
- Installs Prometheus using Docker Compose
- Configures static scrape jobs for:
  - Prometheus itself
  - node_exporter (host metrics)
  - cAdvisor (container metrics)
- Creates required users, groups, and directories

## Usage
Include this role in your playbook:
```yaml
- hosts: all
  roles:
    - prometheus
```

## Integration
- Scrapes metrics from node_exporter and cAdvisor on the same host
- Centralizes metrics for all hosts if configured accordingly
- Grafana connects to Prometheus for visualization 