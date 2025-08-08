#!/bin/bash

# This script generates a WireGuard client configuration file with failover support.

# --- Functions ---

# Function to display an error message and exit
function error_exit {
    echo "Error: $1" >&2
    exit 1
}

# --- Main Script ---

# Check if running as root
if [[ "${EUID}" -ne 0 ]]; then
    error_exit "This script must be run as root."
fi

# Check if wg command is available
if ! command -v wg &> /dev/null; then
    error_exit "WireGuard tools are not installed. Please install them first."
fi

# --- User Input ---

read -rp "Enter a name for the new client (e.g., my-laptop): " CLIENT_NAME
if [[ -z "$CLIENT_NAME" ]]; then
    error_exit "Client name cannot be empty."
fi

# --- Configuration ---

# Path to the WireGuard server configuration directory
WG_DIR="/etc/wireguard"
SERVER_CONFIG="$WG_DIR/wg0.conf" # Assumes your server config is wg0.conf

# Check if the server configuration file exists
if [[ ! -f "$SERVER_CONFIG" ]]; then
    error_exit "Server configuration file not found at $SERVER_CONFIG"
fi

# --- Key Generation ---

# Generate client keys
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# --- Server Information ---

# Get server public key from the server's configuration file
SERVER_PUBLIC_KEY=$(grep -oP 'PrivateKey\s*=\s*\K.*' "$SERVER_CONFIG" | wg pubkey)
if [[ -z "$SERVER_PUBLIC_KEY" ]]; then
    error_exit "Could not retrieve the server's public key."
fi

# Get the server's public IP address
# Try multiple methods to get IPv4 address reliably
SERVER_ENDPOINT_IP=""

# Method 1: Try to get IPv4 from external service
SERVER_ENDPOINT_IP=$(curl -s --max-time 5 --ipv4 ifconfig.me 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

# Method 2: If method 1 fails, try another service
if [[ -z "$SERVER_ENDPOINT_IP" ]]; then
    SERVER_ENDPOINT_IP=$(curl -s --max-time 5 --ipv4 icanhazip.com 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
fi

# Method 3: If external services fail, try to get from local interfaces
if [[ -z "$SERVER_ENDPOINT_IP" ]]; then
    # Get the default route interface
    DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -n "$DEFAULT_INTERFACE" ]]; then
        SERVER_ENDPOINT_IP=$(ip addr show "$DEFAULT_INTERFACE" | grep -oP 'inet \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
fi

if [[ -z "$SERVER_ENDPOINT_IP" ]]; then
    error_exit "Could not retrieve the server's public IPv4 address."
fi

echo "Using server endpoint IP: $SERVER_ENDPOINT_IP"

# Get the server's listening port
SERVER_PORT=$(grep -oP 'ListenPort\s*=\s*\K[0-9]+' "$SERVER_CONFIG")
if [[ -z "$SERVER_PORT" ]]; then
    error_exit "Could not retrieve the server's listening port."
fi

# Get server address to determine network
SERVER_ADDRESS=$(grep -oP 'Address\s*=\s*\K[0-9.]+/[0-9]+' "$SERVER_CONFIG")
if [[ -z "$SERVER_ADDRESS" ]]; then
    error_exit "Could not retrieve the server's address."
fi

# Extract network from server address (e.g., 10.0.0.1/24 -> 10.0.0)
NETWORK_PREFIX=$(echo "$SERVER_ADDRESS" | cut -d'.' -f1-3)

# --- Client Configuration ---

# Find next available IP in the network
LAST_IP=$(grep -oP "AllowedIPs\s*=\s*${NETWORK_PREFIX}\\.\K[0-9]+" "$SERVER_CONFIG" | sort -n | tail -1)

# If no previous peers exist, start assigning from 2.
if [[ -z "$LAST_IP" ]]; then
    NEXT_IP=2
else
    NEXT_IP=$((LAST_IP + 1))
fi

CLIENT_VPN_IP="${NETWORK_PREFIX}.${NEXT_IP}/32"

# --- Detect Failover Configuration ---

# Check if there are multiple peers configured (indicating failover setup)
PEER_COUNT=$(grep -c "^\[Peer\]" "$SERVER_CONFIG")
FAILOVER_ENABLED=false

if [[ $PEER_COUNT -gt 0 ]]; then
    echo "Detected site-to-site configuration with $PEER_COUNT peer(s)."
    read -rp "Enable failover support for this client? (y/N): " ENABLE_FAILOVER
    if [[ "$ENABLE_FAILOVER" =~ ^[Yy]$ ]]; then
        FAILOVER_ENABLED=true
    fi
fi

# --- Create Client Config File ---

CLIENT_CONFIG_FILE="$WG_DIR/$CLIENT_NAME.conf"

cat > "$CLIENT_CONFIG_FILE" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_VPN_IP
# Use internal DNS for VPN-only domains with fallback
DNS = ${NETWORK_PREFIX}.1, 8.8.8.8, 1.1.1.1

[Peer]
# Primary Server
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT_IP:$SERVER_PORT
EOF

if [[ "$FAILOVER_ENABLED" == "true" ]]; then
    # For failover, allow access to all networks
    echo "AllowedIPs = 10.0.0.0/24, 10.0.1.0/24" >> "$CLIENT_CONFIG_FILE"
    
    # Add failover peer configuration
    echo "PersistentKeepalive = 25" >> "$CLIENT_CONFIG_FILE"
    echo "" >> "$CLIENT_CONFIG_FILE"
    
    # Extract failover peer information from server config
    FAILOVER_PUBLIC_KEY=$(grep -A 10 "^\[Peer\]" "$SERVER_CONFIG" | grep -oP 'PublicKey\s*=\s*\K.*' | head -1)
    FAILOVER_ENDPOINT=$(grep -A 10 "^\[Peer\]" "$SERVER_CONFIG" | grep -oP 'Endpoint\s*=\s*\K.*' | head -1)
    
    if [[ -n "$FAILOVER_PUBLIC_KEY" && -n "$FAILOVER_ENDPOINT" ]]; then
        cat >> "$CLIENT_CONFIG_FILE" << EOF
[Peer]
# Failover Server
PublicKey = $FAILOVER_PUBLIC_KEY
Endpoint = $FAILOVER_ENDPOINT
AllowedIPs = 10.0.0.0/24, 10.0.1.0/24
PersistentKeepalive = 25
EOF
    fi
else
    # Split-tunnel: Only route server network through VPN
    echo "AllowedIPs = ${NETWORK_PREFIX}.0/24" >> "$CLIENT_CONFIG_FILE"
    echo "PersistentKeepalive = 25" >> "$CLIENT_CONFIG_FILE"
fi

# --- Add Peer to Server Config ---

# Add the new client as a peer to the server configuration
cat >> "$SERVER_CONFIG" << EOF

[Peer]
# Client: $CLIENT_NAME
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_VPN_IP
EOF

# --- Restart WireGuard Service and Display Info ---

echo "Restarting WireGuard service to apply changes..."
systemctl restart wg-quick@wg0

# --- Final Output ---

echo
echo "=================================================="
if [[ "$FAILOVER_ENABLED" == "true" ]]; then
    echo "Failover VPN Client Created Successfully!"
    echo "=================================================="
    echo
    echo "FAILOVER MODE:"
    echo "✅ Automatic failover between servers"
    echo "✅ Access to both test and prod networks"
    echo "✅ High availability VPN connection"
else
    echo "Split-Tunnel VPN Client Created Successfully!"
    echo "=================================================="
    echo
    echo "SPLIT-TUNNEL MODE:"
    echo "✅ Access to server and VPN-only services via VPN"
    echo "✅ Internet traffic uses your regular connection"
    echo "✅ Only server network (${NETWORK_PREFIX}.0/24) routed through VPN"
fi
echo
echo "Configuration file saved at:"
echo "  $CLIENT_CONFIG_FILE"
echo
echo "Use this file for Windows, macOS, and Linux clients."
echo
echo "--- OR ---"
echo
echo "Scan the QR code below for mobile clients:"
echo

# Install qrencode if not already installed
if ! command -v qrencode &> /dev/null; then
    echo "Installing qrencode to display a QR code..."
    # Add package manager command for your distribution (e.g., apt, yum)
    apt-get update && apt-get install -y qrencode
fi

# Display QR code in the terminal
qrencode -t ansiutf8 < "$CLIENT_CONFIG_FILE"
echo