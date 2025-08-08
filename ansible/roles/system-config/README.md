# System Configuration Role

This Ansible role configures basic system settings including timezone, NTP synchronization, and locale settings.

## Features

- Sets system timezone to UTC
- Configures and enables NTP synchronization using chrony
- Sets system locale
- Configures system hostname

## Requirements

- Ansible 2.9 or higher
- Target hosts must be running a Linux distribution

## Role Variables

The following variables can be overridden in your playbook:

```yaml
# Default system locale
system_locale: en_US.UTF-8

# NTP servers configuration
ntp_servers:
  - pool.ntp.org
  - time.google.com
  - time.windows.com

# System timezone (default to UTC)
timezone: UTC
```

## Example Playbook

```yaml
- hosts: servers
  roles:
    - system-config
```

## License

MIT
