# Fail2ban Role

This Ansible role installs and configures Fail2ban, an intrusion prevention software framework that protects computer servers from brute-force attacks.

## Description

Fail2ban monitors log files for suspicious activity and automatically bans IP addresses that show malicious behavior. This role provides a basic setup with SSH protection enabled by default and options to enable protection for other services.

## Default Configuration

The role comes with the following default settings:

- Ban time: 1 hour
- Find time: 10 minutes
- Max retries: 5
- Protected services:
  - SSH (enabled by default)

## Variables

The following variables can be set to customize the Fail2ban configuration:

```yaml
# Enable/disable specific services
fail2ban_enable_nginx: false

# Custom jail configuration
fail2ban_jail_local: {}
```

## Usage

Include the role in your playbook:

```yaml
- hosts: servers
  roles:
    - fail2ban
```

To enable additional services, set the corresponding variables:

```yaml
- hosts: servers
  roles:
    - role: fail2ban
      vars:
        fail2ban_enable_nginx: true
```

## Requirements

- Ansible 2.9 or higher
- Debian/Ubuntu-based systems (uses apt package manager)

## Dependencies

None

## License

MIT

## Author Information
