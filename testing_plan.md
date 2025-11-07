# Testing Plan for Ansible Roles
**Test Server:** ubuntu-4gb-hel1-4 (46.62.225.143)  
**Date:** Testing Session  
**Status:** In Progress

## Overview
This document outlines the systematic testing plan for all Ansible roles (excluding restic as requested) on the test Ubuntu server. Each role will be tested individually, verified for functionality, and then tested for persistence after server restart.

## Testing Methodology

### For Each Role:
1. **Syntax Check**: Verify playbook syntax
2. **Dry Run**: Run with `--check` mode to preview changes
3. **Execution**: Run the role on test server
4. **Verification**: 
   - Check service status
   - Verify files/directories created
   - Check ports/listeners
   - Review logs if applicable
5. **Idempotency**: Re-run to ensure no changes (should be idempotent)
6. **Persistence**: Restart server and verify services still work

### Testing Phases

## Phase 1: Core & Baseline Roles ⭐ (START HERE)
**Priority:** Highest - Foundation for all other roles

### 1.1 update
- **Purpose**: OS package updates
- **Expected**: System packages updated
- **Verification**: `apt list --upgradable` should show fewer or no upgrades needed
- **Persistence**: Not applicable (one-time update)

### 1.2 common
- **Purpose**: Base system configuration, users, packages
- **Expected**: 
  - Common users created
  - Base packages installed
  - Service directories created
- **Verification**: 
  - Check users: `id <username>`
  - Check directories: `ls -la /opt/`
  - Check installed packages
- **Persistence**: Users and directories persist after reboot

### 1.3 system-config
- **Purpose**: Kernel/sysctl/limits configuration
- **Expected**: System parameters configured
- **Verification**: 
  - Check sysctl: `sysctl -a | grep <key>`
  - Check limits: `ulimit -a`
- **Persistence**: Config files in /etc/sysctl.d/ persist

### 1.4 root_ssh_access
- **Purpose**: Hardened SSH configuration for root
- **Expected**: SSH config hardened
- **Verification**: 
  - Check SSH config: `cat /etc/ssh/sshd_config | grep -i PermitRootLogin`
  - Test SSH connection still works
- **Persistence**: SSH config persists

### 1.5 fail2ban
- **Purpose**: Brute-force protection
- **Expected**: fail2ban service running
- **Verification**: 
  - Service status: `systemctl status fail2ban`
  - Check jails: `fail2ban-client status`
- **Persistence**: Service enabled and starts on boot

**After Phase 1**: Restart server, verify all services still functional

---

## Phase 2: Networking & Container Runtime

### 2.1 tailscale
- **Purpose**: Private mesh VPN
- **Expected**: Tailscale installed and configured
- **Verification**: 
  - Service status: `systemctl status tailscaled`
  - Network status: `tailscale status`
- **Persistence**: Service enabled

### 2.2 docker
- **Purpose**: Container runtime (CRITICAL PREREQUISITE)
- **Expected**: Docker installed and running
- **Verification**: 
  - Service status: `systemctl status docker`
  - Docker version: `docker --version`
  - Test container: `docker run hello-world`
- **Persistence**: Service enabled and starts on boot

### 2.3 iptables
- **Purpose**: Firewall rules (must run after docker)
- **Expected**: Firewall configured
- **Verification**: 
  - Check rules: `iptables -L -n`
  - Check Docker chains: `iptables -L DOCKER-USER -n`
- **Persistence**: Rules persist (check if saved to /etc/iptables/)

### 2.4 dnsmasq
- **Purpose**: Lightweight DNS/DHCP service
- **Expected**: DNS service running
- **Verification**: 
  - Service status: `systemctl status dnsmasq`
  - Test DNS: `dig @127.0.0.1 <domain>`
- **Persistence**: Service enabled

### 2.5 wireguard
- **Purpose**: WireGuard VPN server
- **Expected**: WireGuard configured and running
- **Verification**: 
  - Interface: `ip addr show wg0`
  - Service: `systemctl status wg-quick@wg0` (if applicable)
- **Persistence**: Service enabled

### 2.6 wireguard_xray_gost_client
- **Purpose**: Client wrapper for WireGuard
- **Expected**: Client services running
- **Verification**: Check Docker containers or systemd services
- **Persistence**: Containers/services restart on boot

**After Phase 2**: Restart server, verify Docker and networking services

---

## Phase 3: Container Infrastructure Services

### 3.1 docker-registry
- **Purpose**: Private Docker registry
- **Expected**: Registry container running
- **Verification**: 
  - Container status: `docker ps | grep registry`
  - Test connection: `curl http://localhost:5000/v2/` (if exposed)
- **Persistence**: Container restarts on boot

### 3.2 traefik
- **Purpose**: Edge reverse-proxy / load balancer
- **Expected**: Traefik container running
- **Verification**: 
  - Container status: `docker ps | grep traefik`
  - Dashboard/API accessible
- **Persistence**: Container restarts

### 3.3 portainer
- **Purpose**: Portainer UI (needs docker & traefik)
- **Expected**: Portainer container running
- **Verification**: 
  - Container status: `docker ps | grep portainer`
  - Web UI accessible
- **Persistence**: Container restarts

### 3.4 portainer-agent
- **Purpose**: Portainer agent side-car
- **Expected**: Agent container running
- **Verification**: Container status in Docker
- **Persistence**: Container restarts

**After Phase 3**: Restart server, verify all containers restart properly

---

## Phase 4: Monitoring Infrastructure

### 4.1 monitoring-stack
- **Purpose**: Create monitoring network and base configs
- **Expected**: Docker network created, base configs in place
- **Verification**: 
  - Network: `docker network ls | grep monitoring`
  - Config directories exist
- **Persistence**: Docker network persists

### 4.2 prometheus
- **Purpose**: Metric collection
- **Expected**: Prometheus container running
- **Verification**: 
  - Container status: `docker ps | grep prometheus`
  - Web UI: `curl http://localhost:9090` (if exposed)
- **Persistence**: Container restarts

### 4.3 alertmanager
- **Purpose**: Prometheus alerting
- **Expected**: Alertmanager container running
- **Verification**: Container status and web UI
- **Persistence**: Container restarts

### 4.4 loki
- **Purpose**: Log aggregation
- **Expected**: Loki container running
- **Verification**: Container status and API access
- **Persistence**: Container restarts

### 4.5 grafana
- **Purpose**: Dashboards
- **Expected**: Grafana container running
- **Verification**: 
  - Container status: `docker ps | grep grafana`
  - Web UI accessible
- **Persistence**: Container restarts

### 4.6 node_exporter
- **Purpose**: Node metrics exporter
- **Expected**: Node exporter container running
- **Verification**: Container status and metrics endpoint
- **Persistence**: Container restarts

### 4.7 blackbox_exporter
- **Purpose**: Black-box probing exporter
- **Expected**: Blackbox exporter container running
- **Verification**: Container status
- **Persistence**: Container restarts

### 4.8 cadvisor
- **Purpose**: Container metrics exporter
- **Expected**: cAdvisor container running
- **Verification**: Container status and metrics endpoint
- **Persistence**: Container restarts

### 4.9 remote_monitoring
- **Purpose**: Remote probes
- **Expected**: Remote monitoring setup configured
- **Verification**: Check configuration and probes active
- **Persistence**: Config persists

### 4.10 alloy
- **Purpose**: Lightweight OTEL collector
- **Expected**: Alloy container/service running
- **Verification**: Container status or service status
- **Persistence**: Restarts on boot

**After Phase 4**: Restart server, verify all monitoring containers restart and collect data

---

## Phase 5: Additional Services

### 5.1 pgexporter
- **Purpose**: PostgreSQL metrics exporter
- **Expected**: Exporter running (connects to existing PostgreSQL)
- **Verification**: Container/service status and metrics endpoint
- **Persistence**: Restarts on boot

### 5.2 jenkins-docker
- **Purpose**: Jenkins CI/CD server
- **Expected**: Jenkins container running
- **Verification**: 
  - Container status: `docker ps | grep jenkins`
  - Web UI accessible
- **Persistence**: Container restarts, data persists in volumes

### 5.3 jenkins-ssh-agent-docker
- **Purpose**: SSH agent for Jenkins builds
- **Expected**: SSH agent container running
- **Verification**: Container status and Jenkins connectivity
- **Persistence**: Container restarts

**After Phase 5**: Final restart, complete system verification

---

## Phase 6: Final Verification

### Complete System Check:
1. Restart server: `sudo reboot`
2. Wait for server to come back online
3. SSH into server
4. Verify all services:
   - System services: `systemctl list-units --type=service --state=running`
   - Docker containers: `docker ps`
   - Docker networks: `docker network ls`
   - Open ports: `netstat -tulnp`
5. Test critical services:
   - Docker: Run test container
   - Traefik: Check dashboard
   - Monitoring: Check Grafana, Prometheus
   - Jenkins: Check web UI (if deployed)

---

## Test Log Format

For each role test, log:
- **Role**: [role name]
- **Phase**: [phase number]
- **Date/Time**: [timestamp]
- **Execution**: [success/failure]
- **Issues**: [any errors or warnings]
- **Verification**: [pass/fail with details]
- **Idempotency**: [pass/fail]
- **Notes**: [additional observations]

---

## Skipped Roles
- **restic**: Skipped as per request

---

## Notes
- Each phase should be completed before moving to the next
- Server restarts should be performed between major phases
- Document any issues in `testing_log.md`
- Fix issues before proceeding to next role
- Maintain idempotency - re-running should make no changes


