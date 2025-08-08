# Exporter Role Patterns

This document describes the standardized patterns for all monitoring exporters in the stack.

## 🎯 Design Principles

### ✅ Self-Contained Roles
- Each exporter role manages **only its own service**
- No cross-role dependencies or file modifications
- Clean separation of concerns

### ✅ Service Discovery Pattern
- Exporters communicate with Prometheus via **service discovery files**
- Prometheus automatically picks up changes within 30 seconds
- No restarts needed for target updates

### ✅ Fact-Based Communication
- Roles set Ansible facts for initial deployment coordination
- Facts are consumed by prometheus role during full stack deployment
- Clean alternative to direct file manipulation

## 📋 Exporter Categories

### 1. **Static Exporters** (No Dynamic Updates Needed)
- **Node Exporter**: Host metrics from fixed endpoint
- **cAdvisor**: Container metrics from fixed endpoint

**Pattern:**
```yaml
# Static configuration in prometheus.yml
- job_name: 'node_exporter'
  static_configs:
    - targets: ['host.docker.internal:9100']

# Optional service discovery for consistency
- job_name: 'node_exporter_sd'
  file_sd_configs:
    - files: ['/etc/prometheus/targets/node_exporter.yml']
```

### 2. **Dynamic Exporters** (Require Service Discovery)
- **Blackbox Exporter**: Endpoint monitoring with changing targets
- **Remote Monitoring**: Dynamic remote host discovery

**Pattern:**
```yaml
# Required service discovery
- job_name: 'blackbox_targets'
  metrics_path: /probe
  file_sd_configs:
    - files: ['/etc/prometheus/targets/blackbox_targets.yml']
      refresh_interval: 30s
```

## 🔧 Implementation Patterns

### Pattern 1: Service Discovery File Creation
```yaml
# In exporter tasks/main.yml
- name: Create {exporter} targets service discovery file
  template:
    src: {exporter}_targets.yml.j2
    dest: "{{ prometheus_config_dir }}/targets/{exporter}.yml"
    owner: "{{ prometheus_user_id }}"
    group: "{{ prometheus_group_id }}"
    mode: '0644'
  become: true
  when: {exporter}_service_discovery_enabled | default(true)
```

### Pattern 2: Fact Registration
```yaml
# In exporter tasks/main.yml
- name: Register {exporter} targets
  set_fact:
    monitoring_scrape_configs: "{{ monitoring_scrape_configs | default([]) + [scrape_config] }}"
  vars:
    scrape_config:
      job_name: '{exporter}'
      static_configs:
        - targets: ['{{ target_address }}']
```

### Pattern 3: Service Discovery Template
```yaml
# In templates/{exporter}_targets.yml.j2
---
- targets: ['{{ target_address }}']
  labels:
    job: {exporter}
    instance: '{{ ansible_default_ipv4.address }}'
    service: '{exporter}'
    hostname: '{{ inventory_hostname }}'
{% if {exporter}_labels is defined %}
{% for key, value in {exporter}_labels.items() %}
    {{ key }}: '{{ value }}'
{% endfor %}
{% endif %}
```

## 📊 Current Implementation Status

| Exporter | Type | Service Discovery | Cross-Role Deps | Status |
|----------|------|------------------|-----------------|--------|
| **Node Exporter** | Static | Optional | ❌ None | ✅ Fixed |
| **cAdvisor** | Static | Optional | ❌ None | ✅ Fixed |
| **Blackbox Exporter** | Dynamic | ✅ Required | ❌ None | ✅ Fixed |
| **Remote Monitoring** | Dynamic | ✅ Required | ❌ None | ✅ Fixed |

## 🚀 Usage Examples

### Running Individual Exporters
```bash
# Static exporters - no Prometheus restart needed
ansible-playbook node_exporter.yml
ansible-playbook cadvisor.yml

# Dynamic exporters - Prometheus auto-discovers changes
ansible-playbook blackbox_exporter.yml
ansible-playbook remote_monitoring.yml
```

### Full Stack Deployment
```bash
# Uses facts for initial config + service discovery for updates
ansible-playbook monitoring_stack.yml
```

### Service Discovery Configuration
```yaml
# Enable service discovery for static exporters
node_exporter_service_discovery_enabled: true
cadvisor_service_discovery_enabled: true

# Dynamic exporters always use service discovery
blackbox_endpoints:
  - url: "https://example.com"
    module: "http_2xx"
    labels:
      environment: "production"
```

## 🔧 Prometheus Configuration

### File-Based Service Discovery
```yaml
# prometheus.yml includes automatic service discovery
scrape_configs:
  - job_name: 'file_sd'
    file_sd_configs:
      - files: ['/etc/prometheus/targets/*.yml']
        refresh_interval: 30s
```

### Service Discovery Files Location
```
/opt/monitoring/prometheus/config/targets/
├── blackbox_targets.yml      # Dynamic blackbox targets
├── remote_monitoring.yml     # Dynamic remote targets
├── node_exporter.yml         # Optional static targets
└── cadvisor.yml              # Optional static targets
```

## ✅ Benefits Achieved

1. **No Cross-Role Dependencies**: Each role is completely self-contained
2. **No Service Restarts**: Prometheus picks up changes automatically
3. **Consistent Patterns**: All exporters follow the same design
4. **Flexible Configuration**: Static + dynamic targets supported
5. **Clean Architecture**: Facts for coordination, files for persistence

## 🎯 Best Practices

1. **Use service discovery** for any exporter with changing targets
2. **Keep static configs** in base prometheus.yml for performance
3. **Add labels** to service discovery targets for better organization
4. **Test individually** - each exporter should work standalone
5. **Validate configuration** - use prometheus config validation

This standardized approach ensures **maintainable**, **scalable**, and **conflict-free** monitoring infrastructure! 🎉