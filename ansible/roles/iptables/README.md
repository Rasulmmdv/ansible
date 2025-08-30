# IPtables Role

This Ansible role configures and manages IPtables firewall rules for Linux servers, providing a secure default configuration with customizable port access.

## Description

The role sets up a secure firewall configuration with sensible defaults while allowing customization of allowed ports and services. It implements a configurable default policy (deny-by-default recommended) and includes optional integration with Docker via the DOCKER-USER chain.

## Default Configuration

The role implements the following default rules:

- Default policy (customizable):
  - INPUT: DROP
  - FORWARD: ACCEPT
  - OUTPUT: ACCEPT
- Allowed incoming TCP ports:
  - 22 (SSH)
  - 80 (HTTP)
  - 443 (HTTPS)
- Allowed incoming UDP ports:
  - 51820 (WireGuard)
- Additional rules:
  - Allows established and related connections
  - Allows loopback interface traffic
  - Optional: Manages Docker DOCKER-USER chain to restrict/allow inbound to containers

## Variables

The following variables can be set to customize the firewall configuration:

```yaml
# Master switch
iptables_manage_firewall: true

# Policies
iptables_policy_input: "DROP"
iptables_policy_forward: "ACCEPT"
iptables_policy_output: "ACCEPT"

# Persistence
iptables_persistent_save: true

# Safety delay for auto-recovery
iptables_emergency_recovery_delay_minutes: 3

# Docker integration
iptables_enable_docker_chain: true
iptables_restart_docker_on_change: false

# Simple port lists
iptables_allowed_tcp_ports: [22, 80, 443]
iptables_allowed_udp_ports: [51820]

# Unified custom rules (optional)
iptables_custom_rules: []
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

Notes:
- The role honors Ansible check mode; mutating tasks are skipped in check mode.
- When changing firewall rules, an emergency recovery job is scheduled and removed upon success.

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
