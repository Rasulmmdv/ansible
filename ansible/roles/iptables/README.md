# IPtables Role

This Ansible role configures and manages IPtables firewall rules for Linux servers, providing a secure default configuration with customizable port access.

## Description

The role sets up a secure firewall configuration with sensible defaults while allowing customization of allowed ports and services. It implements a "deny by default" policy and includes integration with Docker and Fail2ban.

## Default Configuration

The role implements the following default rules:

- Default policy: DROP for INPUT, FORWARD, and OUTPUT chains
- Allowed incoming TCP ports:
  - 22 (SSH)
  - 80 (HTTP)
  - 443 (HTTPS)
- Allowed incoming UDP ports:
  - 51820 (WireGuard)
- Additional rules:
  - Allows established and related connections
  - Allows loopback interface traffic
  - Allows Docker bridge network (docker0) traffic
  - Integrates with Fail2ban (if present)

## Variables

The following variables can be set to customize the firewall configuration:

```yaml
# Note: iptables_install_when_docker_present variable has been removed due to recursive templating issues

# List of allowed TCP ports
iptables_allowed_tcp_ports:
  - 22   # SSH
  - 80   # HTTP
  - 443  # HTTPS

# List of allowed UDP ports
iptables_allowed_udp_ports:
  - 51820  # WireGuard
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
```

# Note: The iptables_install_when_docker_present variable has been removed due to recursive templating issues.
# The role now runs based on the check-mode condition and Docker detection logic.

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
