# System Update Role

This Ansible role performs system updates and package management on Debian/Ubuntu systems.

## Description

The role handles system updates by:
- Updating the apt cache
- Upgrading all installed packages
- Removing unnecessary packages
- Cleaning the package cache
- Optionally rebooting the system if required
- Ensuring Docker service is running after reboot

## Variables

The following variables can be set to customize the update behavior:

```yaml
# Whether to reboot the system if required after updates
update_reboot: false
```

## Usage

Basic usage in your playbook:

```yaml
- hosts: servers
  roles:
    - update
```

With automatic reboot enabled:

```yaml
- hosts: servers
  roles:
    - role: update
      vars:
        update_reboot: true
```

## Features

- Full system update and upgrade
- Automatic removal of unnecessary packages
- Package cache cleanup
- Optional automatic reboot if required
- Docker service management after reboot
- Safe update process with proper delays

## Requirements

- Ansible 2.9 or higher
- Debian/Ubuntu-based systems
- Root or sudo privileges

## Dependencies

None, but works well with:
- docker role (for Docker service management)

## Notes

- The role will only reboot if both `update_reboot` is true and a reboot is required
- A 30-second delay is added after reboot to ensure system stability
- Docker service is automatically started after reboot if it was previously running

## License

MIT
