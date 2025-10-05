#!/bin/bash
# Emergency iptables recovery script
echo "$(date): Emergency iptables recovery activated" >> /var/log/iptables-recovery.log

# Flush all rules and set permissive policies
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Try to stop iptables-persistent service to avoid lockout
if systemctl is-active --quiet netfilter-persistent; then
  systemctl stop netfilter-persistent || true
fi
fi

# Add basic SSH rule (use ansible_port if available, fallback to 22)
# Check for ansible_port fact file or use default
if [ -f "/etc/ansible/facts.d/ansible_port.fact" ]; then
  SSH_PORT=$(cat /etc/ansible/facts.d/ansible_port.fact 2>/dev/null || echo "22")
else
  SSH_PORT="22"
fi
iptables -A INPUT -p tcp --dport "$SSH_PORT" -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

echo "$(date): Emergency recovery completed - SSH should be accessible" >> /var/log/iptables-recovery.log

# Send notification if possible
wall "EMERGENCY: iptables rules have been reset due to connectivity loss"


