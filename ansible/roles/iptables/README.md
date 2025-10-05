# iptables (DOCKER-USER) Role

This role configures a host-level firewall using raw iptables with persistence and manages the Docker `DOCKER-USER` chain for container access control.

## Description

The role enables iptables with a deny-by-default incoming policy and allows configurable ports. For containers, it manages the `DOCKER-USER` chain in iptables to surgically control external access to containers. Other roles can include the Docker snippet directly and pass extra ports/sources.

### Docker Networking Support

This role automatically configures iptables to allow Docker container outbound traffic by:
- Setting iptables forward policy to ACCEPT when Docker is present
- Allowing traffic from Docker allowed sources (including 172.17.0.0/16) to internet
- Allowing return traffic from internet to Docker containers (established/related connections)

This fixes common Docker networking issues where containers cannot reach the internet due to iptables blocking the FORWARD chain that Docker uses for NAT routing.

**Security Note**: This role is designed to work with Docker's iptables integration disabled (`"iptables": false` in `/etc/docker/daemon.json`). Instead of letting Docker manage iptables directly (which can be insecure), this role manually creates the necessary NAT and FORWARD rules while maintaining full control over firewall configuration.

### Private Subnet Support

The role allows unrestricted traffic within Docker allowed sources (which include private networks) by default. This is useful for:
- Internal network communication without firewall restrictions
- Development environments where services need to communicate freely
- VPN or mesh network setups where internal traffic should be trusted

By default, all traffic within private networks (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) is permitted in both directions.

## Default Configuration

The role implements the following default rules:

Managed by UFW (host-level, Ubuntu default):
- Deny incoming by default; allow configured TCP/UDP ports (e.g. 22/80/443, 51820).
- Accept forward by default when Docker is present; allows Docker container outbound traffic.
- Allow unrestricted traffic within Docker allowed sources (private networks).

Managed by iptables (containers only):
- `DOCKER-USER` chain created/cleaned; allows ESTABLISHED,RETURN; allows whitelisted sources and public container ports; drops remainder.

## Variables

The following variables can be set to customize the firewall configuration:

```yaml
# Master switch
iptables_manage_firewall: true

# Persistence (iptables-save) is enabled by default to ensure Docker rules persist
iptables_persistent_save: true

# Safety delay for auto-recovery
iptables_emergency_recovery_delay_minutes: 3

# Docker integration
iptables_enable_docker_chain: true
iptables_restart_docker_on_change: false

# Simple port lists
iptables_allowed_tcp_ports: [22, 80, 443]
iptables_allowed_udp_ports: [51820]

# Custom ports for host-level rules
iptables_custom_ports: []

# Per-call extensions when including Docker snippet
iptables_docker_public_tcp_ports_extra: []
iptables_docker_allowed_sources_extra: []
```

## Usage

Basic usage in your playbook:

```yaml
- hosts: servers
  roles:
    - iptables
```

Customizing allowed ports:

```yaml
- hosts: servers
  roles:
    - role: iptables
      vars:
        iptables_allowed_tcp_ports:
          - 22    # SSH
          - 80    # HTTP
          - 443   # HTTPS
          - 8080  # Custom port
        iptables_allowed_udp_ports:
          - 51820  # WireGuard
          - 500    # Custom UDP port
        iptables_custom_rules:
          - { chain: 'INPUT', protocol: 'tcp', dport: 8443, jump: 'ACCEPT', comment: 'Allow alt-HTTPS' }
          - { chain: 'OUTPUT', protocol: 'udp', dport: 53, jump: 'ACCEPT', comment: 'DNS queries' }
```

### Include from other roles

Add container ingress rules from another role via include_role:

```yaml
- name: Open container ports for my-service via DOCKER-USER
  include_role:
    name: iptables
    tasks_from: docker-firewall.yml
  vars:
    iptables_docker_public_tcp_ports_extra: [8080, 8443]
    iptables_docker_allowed_sources_extra: ['10.10.0.0/16']
  tags: [docker, iptables]
```

Notes:
- The role honors Ansible check mode; mutating tasks are skipped in check mode.
- When changing firewall rules, an emergency recovery job is scheduled and removed upon success.
- Emergency script will also disable UFW to recover access if needed.
- Rollback safety uses a systemd timer instead of 'at'.

## Requirements

- Ansible 2.9 or higher
- Linux-based systems with iptables support
- Root or sudo privileges

## Dependencies

None, but works well with:
- fail2ban role (for enhanced security)
- docker role (for container networking)

## Security Notes

- The role implements a "deny by default" policy for maximum security
- All rules are saved and automatically loaded on system boot
- Integration with Fail2ban provides additional protection against brute force attacks
- Docker bridge network access is allowed to ensure container functionality

## Removing Ports

### Understanding Role Behavior

The iptables role is **additive** - it only adds firewall rules for ports that are currently configured in the inventory file. It does **not** automatically remove rules for ports that were previously configured but are no longer in the inventory.

This behavior is intentional and provides better security and reliability:
- **Security**: Prevents accidental removal of critical firewall rules
- **Reliability**: Avoids service disruption from configuration errors
- **Persistence**: Rules survive reboots and configuration changes

### Manual Port Removal

To remove obsolete port rules:

1. **Identify the rules to remove:**
   ```bash
   iptables -L INPUT --line-numbers | grep "dpt:PORT_NUMBER"
   ```

2. **Remove the rules:**
   ```bash
   iptables -D INPUT LINE_NUMBER
   ```

3. **Save the configuration:**
   ```bash
   iptables-save > /etc/iptables/rules.v4
   systemctl reload netfilter-persistent
   ```

### Example: Removing Port 9001

```bash
# 1. Find the rule
iptables -L INPUT --line-numbers | grep "dpt:9001"
# Output: 25   ACCEPT     tcp  --  anywhere  anywhere  tcp dpt:9001

# 2. Remove the rule
iptables -D INPUT 25

# 3. Save the configuration
iptables-save > /etc/iptables/rules.v4
systemctl reload netfilter-persistent
```

### Alternative: Complete Reset

If you need to start fresh with only inventory-configured ports:

```bash
# 1. Stop the iptables role from managing firewall
# 2. Manually configure only the desired rules
# 3. Save the configuration
```

**Note**: Always test firewall changes in a development environment first, as incorrect rules can lock you out of the server.

## License

MIT
