# WireGuard VPN Server Role

This Ansible role sets up a production-ready WireGuard VPN server with automatic peer management and safety features.

## Description

This role provides a complete WireGuard VPN server solution with:
- **Traditional wg-quick configuration** (stable and reliable)
- **Script-based peer management** with automatic IP assignment
- **Emergency iptables recovery** to prevent SSH lockouts
- **Private key preservation** across deployments
- **QR code generation** for mobile clients
- **NAT masquerading** for internet access

## Features

### 🔐 **Security & Safety**
- Emergency iptables recovery prevents SSH lockouts
- Private keys are preserved across Ansible runs
- Secure file permissions (0600 for configs, 0700 for directories)
- All key operations are hidden from logs

### 🚀 **Easy Client Management**
- Interactive script for adding new clients
- Automatic IP address assignment (10.0.0.2, 10.0.0.3, etc.)
- QR code generation for mobile devices
- Config file generation for desktop clients

### ⚡ **Production Ready**
- Traditional wg-quick systemd service
- Automatic NAT masquerading via PostUp/PostDown
- IP forwarding enabled
- Iptables integration with safety mechanisms

## Architecture

```
┌─────────────────────┐    ┌─────────────────────┐
│   WireGuard Client  │    │   WireGuard Server  │
│   (10.0.0.2/32)     │◄──►│   (10.0.0.1/24)     │
└─────────────────────┘    └─────────────────────┘
                                      │
                           ┌─────────────────────┐
                           │     Internet        │
                           │   (via NAT)         │
                           └─────────────────────┘
```

## Quick Start

### 1. Deploy WireGuard Server
```bash
ansible-playbook -i inventory.yml playbooks/wireguard.yml
```

### 2. Add Clients
```bash
ssh root@your-server
create_wg_client.sh
# Enter client name (e.g., "my-phone")
# Script will generate config and QR code
```

## Variables

Configure in `environments/all/group_vars/wireguard_servers.yml`:

```yaml
# Server configuration
wireguard_interface: wg0           # Interface name
wireguard_port: 51820              # UDP port
wireguard_address: "10.0.0.1/24"  # Server VPN IP

# Optional advanced settings
wireguard_mtu: ~                   # Custom MTU
wireguard_fwmark: ~               # Firewall mark
wireguard_table: ~                # Routing table
```

## Client Management

### Adding Clients

The role deploys `/usr/local/bin/create_wg_client.sh` for easy client management:

```bash
# SSH to your server
ssh root@your-server

# Create new client interactively
create_wg_client.sh

# Example session:
# Enter a name for the new client: john-laptop
# Client created successfully!
# Configuration file saved at: /etc/wireguard/john-laptop.conf
# QR code displayed for mobile setup
```

### Client Configuration

The script generates two types of configurations:

**Desktop/Laptop (config file):**
```ini
[Interface]
PrivateKey = <generated_private_key>
Address = 10.0.0.3/32
DNS = 1.1.1.1, 1.0.0.1

[Peer]
PublicKey = <server_public_key>
Endpoint = your-server.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

**Mobile (QR Code):**
- Scan with WireGuard mobile app
- Automatic configuration import

## Safety Features

### Emergency Iptables Recovery

The role includes automatic SSH lockout protection:

```
┌─────────────────────┐
│  Ansible Playbook  │
│     Starts          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Schedule Emergency  │
│ Recovery (3 min)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐    SUCCESS    ┌─────────────────────┐
│  Apply iptables     │──────────────►│ Cancel Emergency    │
│  Rules Safely       │               │ Job                 │
└──────────┬──────────┘               └─────────────────────┘
           │
           │ FAILURE/DISCONNECT
           ▼
┌─────────────────────┐
│ Auto-restore SSH    │
│ Access (3 minutes)  │
└─────────────────────┘
```

### What Happens on Disconnect:
1. Emergency job triggers after 3 minutes
2. Flushes all iptables rules
3. Restores SSH access
4. Logs recovery to `/var/log/iptables-recovery.log`
5. Notifies all users via `wall`

## Directory Structure

```
/etc/wireguard/
├── wg0.conf                    # Server configuration
├── client1.conf               # Client configs (generated by script)
└── client2.conf

/usr/local/bin/
└── create_wg_client.sh         # Client management script

/var/log/
├── iptables-recovery.log       # Emergency recovery logs
└── ssh-connectivity.log       # Connection monitoring
```

## Network Configuration

### Server Network: `10.0.0.0/24`
- **Server**: `10.0.0.1/24`
- **Clients**: `10.0.0.2/32`, `10.0.0.3/32`, etc.

### NAT & Routing
- Automatic NAT masquerading for internet access
- IP forwarding enabled
- Iptables rules managed by WireGuard PostUp/PostDown

### Firewall Rules
```bash
# Automatically applied by WireGuard:
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Plus UDP port 51820 allowed by iptables role
```

## Troubleshooting

### Check WireGuard Status
```bash
# Service status
systemctl status wg-quick@wg0

# Interface details
wg show wg0

# Connection logs
journalctl -u wg-quick@wg0 -f
```

### Emergency Recovery
```bash
# Manual emergency recovery
/usr/local/bin/emergency-iptables-recovery.sh

# Check recovery logs
tail -f /var/log/iptables-recovery.log

# View scheduled emergency jobs
atq
```

### Common Issues

**Clients can't connect:**
- Check server firewall: `iptables -L -n | grep 51820`
- Verify IP forwarding: `cat /proc/sys/net/ipv4/ip_forward`
- Check WireGuard logs: `journalctl -u wg-quick@wg0`

**SSH lockout prevention:**
- Emergency recovery runs automatically in 3 minutes
- Jobs are visible with `atq` command
- Recovery script at `/usr/local/bin/emergency-iptables-recovery.sh`

## Requirements

- **OS**: Ubuntu 17.10+ (tested on Ubuntu 22.04+)
- **Ansible**: 2.9+
- **Privileges**: Root or sudo access
- **Network**: Public IP with UDP port 51820 accessible

## Dependencies

- `ansible.builtin.iptables` module
- `at` package (for emergency recovery)
- `qrencode` package (for QR codes)

## Security Notes

- Private keys are **never exposed** in logs or output
- Configuration files have **restricted permissions** (0600)
- Emergency recovery **logs all actions** with timestamps
- Keys are generated using **cryptographically secure** methods
- Server private key is **preserved** across Ansible runs

## Example Playbook

```yaml
---
- name: Deploy WireGuard VPN Server
  hosts: wireguard_servers
  become: true
  roles:
    - wireguard
  post_tasks:
    - name: Show server public key
      shell: wg show wg0 public-key
      register: server_pubkey
      
    - name: Display setup complete message
      debug:
        msg: |
          ==========================================
          WireGuard VPN Server Setup Complete!
          ==========================================
          
          Server Public Key: {{ server_pubkey.stdout }}
          Server Endpoint: {{ ansible_host }}:51820
          
          To add clients, SSH to the server and run:
          create_wg_client.sh
```

## License

MIT

## Site-to-Site VPN Configuration

### Key Management and Idempotency

The WireGuard role now implements proper idempotency for site-to-site VPN configurations:

#### How It Works

1. **First Run**: Keys are generated on the Ansible control machine and stored in `/tmp/wireguard_keys/`
2. **Subsequent Runs**: Existing keys are reused, no regeneration occurs
3. **Forced Regeneration**: Set `wireguard_force_key_regeneration: true` to regenerate all keys

#### Key Storage

- **Control Machine**: Keys are temporarily stored in `/tmp/wireguard_keys/` during deployment
- **Target Servers**: Keys are deployed to `/etc/wireguard/` on each server
- **Persistence**: Keys persist on the control machine between runs for idempotency

#### Variables

```yaml
# Enable site-to-site VPN
wireguard_site_to_site_enabled: true

# Force regeneration of all keys (optional)
wireguard_force_key_regeneration: false  # Set to true to regenerate keys

# Define peers in host_vars
wireguard_peers:
  - name: "other-server-name"
    endpoint: "1.2.3.4:51820"
    allowed_ips: "10.0.1.0/24"
    persistent_keepalive: 25
```

#### Idempotency Behavior

✅ **Safe to run multiple times**: Keys are only generated once
✅ **No unnecessary changes**: Existing keys are preserved
✅ **Configurable regeneration**: Use `wireguard_force_key_regeneration: true` when needed
✅ **Cross-server consistency**: All servers get the same set of keys

#### Example Usage

```bash
# Initial deployment - generates keys
ansible-playbook -i inventory wireguard.yml

# Subsequent runs - reuses existing keys  
ansible-playbook -i inventory wireguard.yml

# Force key regeneration if needed
ansible-playbook -i inventory wireguard.yml -e wireguard_force_key_regeneration=true
```
