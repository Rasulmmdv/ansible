# node_exporter Ansible Role

This role deploys node_exporter as a systemd service to expose host-level metrics for Prometheus.

## Features
- Installs node_exporter using systemd
- **Secure by default** - binds to localhost only (127.0.0.1:9100)
- **No internet exposure** - metrics are only accessible locally
- **Docker network integration** - Prometheus containers can scrape via `host.docker.internal:9100`
- **Simple and focused** - only handles node_exporter installation and configuration
- Creates required users, groups, and directories

## Security Features

### ✅ **SECURE: Localhost Binding**
- node_exporter binds to `127.0.0.1:9100` by default
- **No external internet access** to metrics
- Only Docker containers can reach the host metrics endpoint

### ✅ **No Firewall Configuration**
- **No iptables conflicts** - firewall handled by existing iptables role
- **Proper separation of concerns** - each role does what it's designed for

## Usage
Include this role in your playbook:
```yaml
- hosts: all
  roles:
    - node_exporter
```

## Configuration

### Security Variables
```yaml
# Security configuration (defaults are secure)
node_exporter_bind_address: "127.0.0.1"  # Only localhost
node_exporter_port: "9100"                # Standard port

# Installation configuration
node_exporter_version: "1.9.0"
node_exporter_extra_args: ""

# Service discovery configuration
node_exporter_service_discovery_enabled: true
node_exporter_prometheus_config_dir: "/opt/monitoring/prometheus/config"
```

### Custom Configuration
```yaml
# Only if you need custom binding (NOT recommended for security)
node_exporter_bind_address: "192.168.1.100"  # Specific IP
node_exporter_port: "19100"                   # Custom port

# Extra arguments
node_exporter_extra_args: "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector"
```

## Integration
- Prometheus scrapes metrics from node_exporter via `host.docker.internal:9100`
- Metrics are visualized in Grafana via Prometheus
- **No need to expose port 9100 to the internet**
- **No need to configure iptables** - handled by existing iptables role

## Network Architecture

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

## Verification

### Check Service Status
```bash
systemctl status node_exporter
```

### Verify Binding (Should show 127.0.0.1:9100)
```bash
netstat -tlnp | grep 9100
ss -tlnp | grep 9100
```

### Test from Prometheus Container
```bash
docker exec -it prometheus curl http://host.docker.internal:9100/metrics
```

## Security Notes

⚠️ **IMPORTANT**: 
- **NEVER add port 9100 to `iptables_allowed_tcp_ports`**
- This would expose your metrics to the internet
- Use the secure Docker networking approach instead
- **Firewall configuration is handled by the existing iptables role**

## Tags
- `install` - Installation tasks
- `configure` - Configuration tasks

## Dependencies
- Docker (for container networking)
- iptables role (for firewall rules)

## See Also
- [SECURITY.md](SECURITY.md) - Security configuration guide
- [SOLUTION_SUMMARY.md](SOLUTION_SUMMARY.md) - Problem and solution summary
- [monitoring-stack](../monitoring-stack/) - Complete monitoring stack orchestration 