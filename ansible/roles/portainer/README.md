# Portainer Ansible Role

This role installs and configures Portainer.

## Requirements

- Docker
- Traefik

## Role Variables

See `defaults/main.yml`.

## Dependencies

- `docker`

## Example Playbook

```yaml
- hosts: servers
  roles:
     - { role: portainer }
``` 