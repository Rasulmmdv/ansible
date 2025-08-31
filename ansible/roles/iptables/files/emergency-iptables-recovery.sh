#!/bin/bash
# Emergency iptables recovery script
echo "$(date): Emergency iptables recovery activated" >> /var/log/iptables-recovery.log

# Flush all rules and set permissive policies
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Try to disable UFW to avoid lockout
if command -v ufw >/dev/null 2>&1; then
  ufw --force disable || true
fi

# Add basic SSH rule
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

echo "$(date): Emergency recovery completed - SSH should be accessible" >> /var/log/iptables-recovery.log

# Send notification if possible
wall "EMERGENCY: iptables rules have been reset due to connectivity loss"


