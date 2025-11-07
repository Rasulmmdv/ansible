# Ansible Infrastructure Automation

A comprehensive Ansible repository for deploying and managing infrastructure services, including monitoring, containers, CI/CD, and security tools.

## Repository Structure

- `roles/` - Ansible roles for various services and tools
- `playbooks/` - Individual playbooks for specific deployments
- `group_vars/` - Configuration variables
- `all/` - Inventory and host definitions
- `ansible.cfg` - Ansible configuration

## Available Roles

### Core Infrastructure
- **update** - OS package updates
- **common** - Base system configuration
- **docker** - Docker runtime and containers
- **system-config** - Kernel and system settings
- **tailscale** - Private mesh VPN

### Security & Access
- **fail2ban** - Brute-force protection
- **iptables** - Firewall configuration
- **root_ssh_access** - Hardened SSH configuration
- **wireguard** - WireGuard VPN server

### Monitoring Stack
- **monitoring-stack** - Monitoring network and base configuration
- **prometheus** - Metrics collection
- **grafana** - Visualization dashboards
- **loki** - Log aggregation
- **alertmanager** - Alert management
- **node_exporter** - Node metrics
- **blackbox_exporter** - Black-box monitoring
- **cadvisor** - Container metrics

### Services
- **jenkins-docker** - Jenkins CI/CD server
- **traefik** - Reverse proxy and load balancer
- **portainer** - Docker container management
- **postgres** - PostgreSQL database
- **docker-registry** - Private Docker registry

## Usage

### Run All Roles
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml -e run_all_roles=true
```

### Run Specific Roles
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml -e "roles_enabled=['docker', 'prometheus']"
```

### Run with Tags
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml -e "roles_enabled=['docker']" -t install
```

### Dry Run (Check Mode)
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml --check -e run_all_roles=true
```

## Individual Playbooks

Run specific services directly:
```bash
ansible-playbook -i all/inventory.yml playbooks/docker.yml
ansible-playbook -i all/inventory.yml playbooks/monitoring_stack.yml
ansible-playbook -i all/inventory.yml playbooks/jenkins-docker.yml
```

## Configuration

- Main configuration: `group_vars/all/main.yml`
- Role dependencies and execution order are defined centrally
- Environment-specific variables can be added to `group_vars/`

## Requirements

- Ansible 2.9+
- SSH access to target hosts
- sudo privileges on target hosts

## Development Workflow

1. **Discovery & Analysis** - Scan existing roles and identify dependencies
2. **Orchestration & Configuration** - Use central config for role management
3. **Tagging & Tasking** - All tasks have consistent tags (install, configure, validate, cleanup)
4. **Testing & Validation** - Always test with `--syntax-check` and `--check`
5. **Documentation & Finalization** - Keep README and testing logs updated

## Automation & Monitoring

### Automated Health Checks
Run periodic health checks on all services:
```bash
ansible-playbook -i all/inventory.yml playbooks/health_check.yml
```

### Configuration Drift Detection
Detect when actual system state differs from desired state:
```bash
# Manual check
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml --check --diff

# Automated drift detection (via common role)
# Configured via systemd timer
```

### Automation Status
See `AUTOMATION_ROBUSTNESS.md` for:
- Current automation level assessment
- Recommendations for enhanced robustness
- Implementation roadmap
- Quick wins for immediate improvement

**Current Automation Level**: ~70%
- ✅ Deployment: Fully automated
- ✅ Monitoring: Good coverage  
- ✅ Backups: Automated
- ⚠️ Self-healing: Basic (needs enhancement)
- ⚠️ Alerting: Configured but needs verification

## Security Notes

- Never commit secrets or credentials
- Use `--extra-vars` or `host_vars/` for sensitive data
- Roles are designed to be idempotent and check-mode safe
