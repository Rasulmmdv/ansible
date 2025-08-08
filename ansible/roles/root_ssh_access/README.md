# Root SSH Access Role

This Ansible role manages SSH access for the root user by configuring authorized keys.

## Description

The role sets up secure SSH access for the root user by:
- Creating the `/root/.ssh` directory with proper permissions
- Adding authorized SSH keys for root access
- Maintaining proper security permissions (0700 for directory)

## Variables

The following variable is required:

```yaml
# List of SSH public keys to add to root's authorized_keys
root_authorized_keys:
  - "ssh-rsa AAAA..."  # Your public key
  - "ssh-rsa BBBB..."  # Another public key
```

## Usage

Basic usage in your playbook:

```yaml
- hosts: servers
  roles:
    - role: root_ssh_access
      vars:
        root_authorized_keys:
          - "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
```

## Security Notes

- This role should be used with caution as it enables root SSH access
- Ensure only trusted public keys are added
- Consider using this role only in controlled environments
- The role maintains proper file permissions for security

## Requirements

- Ansible 2.9 or higher
- Root or sudo privileges
- SSH public keys to be added

## Dependencies

None

## License

MIT
