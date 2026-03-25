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

# Allow HTTP/HTTPS for specific domains
for domain in "${DOMAINS[@]}"; do
  # Get all IP addresses for the domain (IPv4)
  IPS=$(getent ahosts "$domain" | awk '{print $1}' | sort -u | grep -E '^[0-9.]+$')
  for ip in $IPS; do
    iptables -A OUTPUT -p tcp -d "$ip" --dport 80 -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$ip" --dport 443 -j ACCEPT
    if [[ "$domain" == "github.com" ]]; then
      iptables -A OUTPUT -p tcp -d "$ip" --dport 22 -j ACCEPT
    fi
  done
done

# Default policy: DROP all other output
iptables -P OUTPUT DROP

echo "Firewall rules applied."
