#!/bin/bash
set -e

# List of domains to allow
DOMAINS=($(run-parts .devcontainer/allow_hosts.d/))

# Flush existing rules
iptables -F
iptables -X

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (port 53 UDP/TCP)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow HTTP/HTTPS for specific domains and CIDR ranges
for entry in "${DOMAINS[@]}"; do
  if [[ "$entry" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
    # Direct CIDR or IP
    iptables -A OUTPUT -p tcp -d "$entry" --dport 80 -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$entry" --dport 443 -j ACCEPT
  else
    # Domain name
    IPS=$(getent ahosts "$entry" | awk '{print $1}' | sort -u | grep -E '^[0-9.]+$')
    for ip in $IPS; do
      iptables -A OUTPUT -p tcp -d "$ip" --dport 80 -j ACCEPT
      iptables -A OUTPUT -p tcp -d "$ip" --dport 443 -j ACCEPT
      if [[ "$entry" == "github.com" ]]; then
        iptables -A OUTPUT -p tcp -d "$ip" --dport 22 -j ACCEPT
      fi
    done
  fi
done

# Default policy: DROP all other output
iptables -P OUTPUT DROP

echo "Firewall rules applied."
