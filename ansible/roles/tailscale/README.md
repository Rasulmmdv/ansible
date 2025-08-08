# Tailscale Ansible Role

This role installs and configures Tailscale VPN using the official installation script.

## Requirements

- Ansible 2.9+
- Internet connectivity to download the Tailscale install script
- Root or sudo access

## Role Variables

### Required Variables

None - all variables have sensible defaults.

### Optional Variables

#### Authentication
- `tailscale_auth_key`: Tailscale auth key for automatic authentication (default: `""`)
  - Generate one at https://login.tailscale.com/admin/settings/keys

#### Hostname Configuration
- `tailscale_hostname`: Custom hostname for this node in Tailscale (default: `""`)

#### Installation Settings
- `tailscale_install_url`: URL for Tailscale install script (default: `"https://tailscale.com/install.sh"`)
- `tailscale_install_script_path`: Local path for install script (default: `"/tmp/tailscale-install.sh"`)

#### Service Configuration
- `tailscale_service_name`: Systemd service name (default: `"tailscaled"`)
- `tailscale_service_enabled`: Enable service at boot (default: `true`)
- `tailscale_service_state`: Service state (default: `"started"`)

#### Network Configuration
- `tailscale_accept_dns`: Accept DNS settings from Tailscale (default: `true`)
- `tailscale_accept_routes`: Accept routes from Tailscale (default: `false`)
- `tailscale_shields_up`: Enable shields up mode (default: `false`)
- `tailscale_advertise_routes`: Routes to advertise to other nodes (default: `""`)
- `tailscale_advertise_tags`: Tags to advertise (default: `""`)

## Dependencies

None

## Example Playbook

### Basic Installation

```yaml
- hosts: servers
  roles:
    - tailscale
```

### With Authentication

```yaml
- hosts: servers
  vars:
    tailscale_auth_key: "tskey-auth-xxxxxxxxx"
    tailscale_hostname: "my-server"
  roles:
    - tailscale
```

### Advanced Configuration

```yaml
- hosts: servers
  vars:
    tailscale_auth_key: "tskey-auth-xxxxxxxxx"
    tailscale_hostname: "web-server"
    tailscale_accept_dns: true
    tailscale_accept_routes: true
    tailscale_advertise_routes: "192.168.1.0/24"
    tailscale_advertise_tags: "tag:web,tag:production"
  roles:
    - tailscale
```

### Edge Router Configuration

```yaml
- hosts: edge-routers
  vars:
    tailscale_auth_key: "tskey-auth-xxxxxxxxx"
    tailscale_hostname: "edge-router"
    tailscale_accept_routes: false
    tailscale_advertise_routes: "10.0.0.0/8,172.16.0.0/12"
    tailscale_advertise_tags: "tag:router"
  roles:
    - tailscale
```

## What This Role Does

1. **Downloads** the official Tailscale install script
2. **Installs** Tailscale using the script
3. **Starts and enables** the Tailscale daemon service
4. **Authenticates** the node (if auth key is provided)
5. **Configures** additional options like hostname, routes, and tags
6. **Cleans up** temporary installation files

## Manual Authentication

If you don't provide an auth key, you'll need to authenticate manually:

```bash
# On the target server
tailscale up
```

This will provide a URL to authenticate the device.

## Security Considerations

- **Auth Keys**: Store auth keys securely (consider using Ansible Vault)
- **Shields Up**: Enable `tailscale_shields_up: true` for additional security
- **Routes**: Be careful with `tailscale_advertise_routes` to avoid routing conflicts
- **Tags**: Use tags for access control and organization

## Troubleshooting

### Check Tailscale Status
```bash
tailscale status
```

### View Tailscale Logs
```bash
journalctl -u tailscaled -f
```

### Re-authenticate
```bash
tailscale logout
tailscale up
```

## License

MIT 