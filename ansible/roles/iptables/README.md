# UFW + iptables (DOCKER-USER) Role

This role configures a host-level firewall with UFW (simple and readable) and uses raw iptables only for the Docker `DOCKER-USER` chain where UFW cannot help.

## Description

The role enables UFW with a deny-by-default incoming policy and allows configurable ports. For containers, it manages the `DOCKER-USER` chain in iptables to surgically control external access to containers. Other roles can include the Docker snippet directly and pass extra ports/sources.

## Default Configuration

The role implements the following default rules:

Managed by UFW (host-level, Ubuntu default):
- Deny incoming by default; allow configured TCP/UDP ports (e.g. 22/80/443, 51820).

Managed by iptables (containers only):
- `DOCKER-USER` chain created/cleaned; allows ESTABLISHED,RETURN; allows whitelisted sources and public container ports; drops remainder.

## Variables

The following variables can be set to customize the firewall configuration:

```yaml
# Master switch
iptables_manage_firewall: true

# Persistence (iptables-save) is disabled by default since UFW manages host rules
iptables_persistent_save: false

# Safety delay for auto-recovery
iptables_emergency_recovery_delay_minutes: 3

# Docker integration
iptables_enable_docker_chain: true
iptables_restart_docker_on_change: false

# Simple port lists
iptables_allowed_tcp_ports: [22, 80, 443]
iptables_allowed_udp_ports: [51820]

# UFW custom ports (preferred for host-level rules)
ufw_custom_ports: []

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

## License

MIT
