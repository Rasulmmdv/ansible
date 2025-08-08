# Grafana Ansible Role

This role deploys Grafana as a Docker container for metrics visualization.

## Features
- Installs Grafana using Docker Compose
- Provisions Prometheus as the default data source
- Creates required users, groups, and directories

## Usage
Include this role in your playbook:
```yaml
- hosts: all
  roles:
    - grafana
```

## Integration
- Connects to Prometheus for metrics
- Visualizes host and container metrics from node_exporter and cAdvisor

## Architecture

```
+-------------------+        +-------------------+
|     Host 1        |        |     Host 2        |
|  +-------------+  |        |  +-------------+  |
|  | node_exporter| |        |  | node_exporter| |
|  +-------------+  |        |  +-------------+  |
|  |  cAdvisor   |  |        |  |  cAdvisor   |  |
|  +-------------+  |        |  +-------------+  |
+-------------------+        +-------------------+
         |   |                        |   |
         |   +------------------------+   |
         |                              |
         +------------------------------+
                        |
                        v
               +----------------+
               |  Prometheus    |
               +----------------+
                        |
                        v
               +----------------+
               |    Grafana     |
               +----------------+
```

- Each host runs node_exporter and cAdvisor, exposing metrics on ports 9100 and 8080
- Prometheus scrapes these endpoints from all hosts
- Grafana connects to Prometheus and provides dashboards for all collected metrics 