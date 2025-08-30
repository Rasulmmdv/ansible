# Monitoring Stack Meta-Role

This meta-role orchestrates the complete monitoring stack deployment and ensures proper configuration coordination between all monitoring components.

## Purpose

- **Eliminates cross-role dependencies** by centralizing configuration management
- **Ensures proper deployment order** through dependency management
- **Provides validation** of the complete monitoring stack
- **Simplifies deployment** with a single role invocation

## Components Managed

- **Prometheus** - Metrics collection and alerting
- **Grafana** - Visualization and dashboards
- **Alertmanager** - Alert routing and notifications
- **Loki** - Log aggregation
- **Alloy** - Log collection agent
- **Node Exporter** - Host metrics
- **cAdvisor** - Container metrics
- **Blackbox Exporter** - Endpoint monitoring

## Usage

### Basic Deployment

```yaml
- name: Deploy monitoring stack
  hosts: monitoring_servers
  roles:
    - monitoring-stack
```

### With Tags

```yaml
- name: Deploy only metrics components
  hosts: monitoring_servers
  roles:
    - role: monitoring-stack
      tags: ["metrics"]
```

### With Validation

```yaml
- name: Deploy and validate monitoring stack
  hosts: monitoring_servers
  roles:
    - monitoring-stack
  post_tasks:
    - include_role:
        name: monitoring-stack
        tasks_from: validate
      tags: ["validate"]
```

## Configuration

### Global Configuration

Configuration is centralized in `group_vars/monitoring.yml`:

```yaml
monitoring_stack:
  network_name: "monitoring"
  data_root: "/opt/monitoring"
  validation_enabled: true
```

### Service Discovery

Uses file-based service discovery for extensibility:

```yaml
# Roles register targets via facts
- name: Register service targets
  set_fact:
    monitoring_scrape_configs: "{{ monitoring_scrape_configs | default([]) + [my_service_config] }}"
```

## Architecture Benefits

### Before (Problematic)
```
alertmanager ──┐
               ├─► prometheus.yml (conflicts)
blackbox ──────┘

node_exporter ──┐
               ├─► iptables rules (conflicts)
prometheus ─────┘
```

### After (Fixed)
```
alertmanager ──┐
               ├─► monitoring_facts ──► prometheus.yml
blackbox ──────┘

node_exporter ──┐
               ├─► No firewall configuration (handled by iptables role)
prometheus ─────┘
```

## Firewall Configuration

The monitoring-stack role **does NOT handle firewall configuration** - this is properly managed by the existing `iptables` role:

### ✅ **Simple and Clean**
- **No duplicate firewall logic** - uses existing iptables role
- **No conflicts** - individual monitoring roles don't configure iptables
- **Proper separation of concerns** - each role does what it's designed for

### 🔒 **Security Features**
- **node_exporter binds to localhost only** (127.0.0.1:9100)
- **No internet exposure** of monitoring endpoints
- **Docker network integration** - Prometheus containers use `host.docker.internal:9100`
- **iptables role handles all firewall rules** consistently

### 🌐 **Network Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                    Host Server                              │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │   Prometheus    │    │        node_exporter            ││
│  │   Container     │────│     (127.0.0.1:9100)           ││
│  │                 │    │                                 ││
│  └─────────────────┘    └─────────────────────────────────┘│
│           │                        ▲                        │
│           │                        │                        │
│           └────────────────────────┘                        │
│                    Docker Network                           │
│                    (172.17.0.0/16)                         │
└─────────────────────────────────────────────────────────────┘
```

## Validation

The role includes comprehensive validation:

- **Configuration validation** - Validates Prometheus config syntax
- **Health checks** - Verifies all services are healthy
- **Target validation** - Ensures all scrape targets are reachable
- **Integration testing** - Validates service interactions

## Dependencies

- **Docker** - All services run in containers
- **Docker Compose** - Service orchestration
- **Monitoring network** - Shared Docker network

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `monitoring_stack.network_name` | `monitoring` | Docker network name |
| `monitoring_stack.data_root` | `/opt/monitoring` | Data directory root |
| `monitoring_config.validate_deployment` | `true` | Enable post-deployment validation |

## Tags

- `common` - Common setup tasks
- `metrics` - Prometheus, exporters
- `alerts` - Alertmanager
- `logs` - Loki, Alloy
- `visualization` - Grafana
- `validate` - Validation tasks

## Example Playbook

```yaml
---
- name: Deploy monitoring infrastructure
  hosts: monitoring_servers
  become: true
  
  pre_tasks:
    - name: Ensure Docker is installed
      package:
        name: docker.io
        state: present
  
  roles:
    - monitoring-stack
  
  post_tasks:
    - name: Display stack status
      debug:
        msg: "Monitoring stack deployed successfully"
```

## Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker network creation
2. **Configuration errors**: Run validation tasks
3. **Port conflicts**: Verify port availability
4. **Permission issues**: Check data directory ownership

### Validation Commands

```bash
# Validate Prometheus configuration
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Check service health
curl -f http://localhost:9090/-/ready  # Prometheus
curl -f http://localhost:3000/api/health  # Grafana
curl -f http://localhost:9093/-/healthy  # Alertmanager
curl -f http://localhost:3100/ready  # Loki
```

## Migration from Legacy Setup

If migrating from the old cross-role dependency setup:

1. Replace `monitoring_stack.yml` playbook with this meta-role
2. Update `group_vars/monitoring.yml` with centralized configuration
3. Run with validation enabled to ensure proper migration