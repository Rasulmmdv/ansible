# 🛰️ WireGuard + Xray + Gost CLIENT Stack

> **Note**: This is a **CLIENT-ONLY** role. It installs WireGuard client tools (`wireguard` + `wireguard-tools`) and configuration to connect to an external WireGuard server. It does NOT set up a WireGuard server, PostUp/PostDown scripts, NAT masquerading, or server key generation.

## Overview

This stack enables clients to:

- Use a **SOCKS5 proxy** (`127.0.0.1:10808`) to tunnel traffic through a **German server**
- Bypass restrictions with **WireGuard tunneled over Xray (VLESS + Reality + TCP)**
- Forward both **TCP and UDP traffic** using `gost` as a translator
- Get a **German IPv4 address** as their public IP

---

## 📜 Ansible Tasks Summary

```yaml
- Install client packages: curl, unzip, wireguard, wireguard-tools, resolvconf
- Install Xray and deploy VLESS + Reality config
- Download and install Gost
- Add iptables rule to redirect UDP 51820 to TCP 51821
- Deploy and enable gost systemd service
- Deploy user-provided WireGuard client config (wg0.conf)
- Enable WireGuard client service (wg-quick@wg0)
```

## 🧪 Verification

**🔍 One-liner test (Linux terminal):**

```bash
echo "[✈️  No proxy IPv4]"; curl -4 -s http://ifconfig.me; echo;
echo "[🧦 SOCKS5 IPv4]"; curl -4 --socks5-hostname 127.0.0.1:10808 -s http://ifconfig.me; echo;
echo "[🧦 SOCKS5 IPv6]"; curl -6 --socks5-hostname 127.0.0.1:10808 -s http://ifconfig.me; echo
```

**Expected:**

```scss
[✈️  No proxy IPv4]
<local or ISP IP>
[🧦 SOCKS5 IPv4]
<German IP>
[🧦 SOCKS5 IPv6]
(blank or error)
```

## 🗂️ Required Files
You must provide these files when using the Ansible role:

- `xray_config.json`  
  Your VLESS + Reality config (with domain, private key, short ID, etc.)
- `wg0.conf`  
  Your WireGuard client configuration (pointing to Xray server)
- `gost.service`

**Example:**

```ini
[Unit]
Description=Gost SOCKS5 Proxy over TCP for WireGuard
After=network.target

[Service]
ExecStart=/usr/local/bin/gost -L=ss+udp://:51821 -F=socks5://:10808
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## 🌐 Architecture Diagram

```less
[ Client App ]
     |
     |  SOCKS5 (127.0.0.1:10808)
     v
[ Gost: UDP ➜ TCP ]
     |
     |  TCP (40152)
     v
[ Xray (VLESS + Reality) ]
     |
     |  WireGuard (10.0.0.0/24)
     v
[ Internet via German IPv4 ]
```

## 💡 Notes
- UDP traffic is tunneled via TCP using gost, allowing WireGuard to work without native UDP.
- WireGuard is forwarded from UDP 51820 ➜ TCP 51821 by iptables:

```bash
iptables -t nat -A PREROUTING -p udp --dport 51820 -j REDIRECT --to-ports 51821
```

- This is ideal for clients behind restrictive networks, or ISPs blocking UDP or VPNs.
- To persist iptables rules across reboot, use:

```bash
apt install iptables-persistent
```

## 🧰 Troubleshooting
Make sure:
- `xray.service`, `gost.service`, and `wg-quick@wg0.service` are active
- Domain in Reality config resolves properly
- `short_id` and `private_key` match between client/server

Check logs:

```bash
journalctl -u xray -f
journalctl -u gost -f
```

---

## 🧩 Components

| Component | Description |
|----------|-------------|
| **WireGuard** | Encrypted tunnel interface between client and server |
| **Xray (VLESS + Reality)** | Secure TCP-based transport, masquerading as HTTPS |
| **Gost** | Translates UDP into TCP and provides SOCKS5 proxy |
| **iptables** | Redirects UDP WireGuard traffic to gost TCP port |
| **Ansible Role** | Automates the full server setup |

---

## 🖥️ Use Case

This setup is useful when clients are:

- Behind firewalls, NAT, or blocked UDP
- In restrictive countries like Russia
- Need a stable IPv4 address from Germany

Clients route their app traffic via:
```bash
curl --socks5-hostname 127.0.0.1:10808 http://ifconfig.me
````


