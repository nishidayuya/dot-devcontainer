#!/bin/sh

set -eu

# Flush existing rules in standard chains
iptables -w -F INPUT
iptables -w -F OUTPUT
iptables -w -X || true

# Allow loopback
iptables -w -A INPUT -i lo -j ACCEPT
iptables -w -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -w -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -w -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (port 53 UDP/TCP)
iptables -w -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -w -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow HTTP/HTTPS for specific domains and CIDR ranges
for entry in $(run-parts .devcontainer/allow_hosts.d/); do
  case "$entry" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*)
      # Direct CIDR or IP
      iptables -w -A OUTPUT -p tcp -d "$entry" --dport 80 -j ACCEPT
      iptables -w -A OUTPUT -p tcp -d "$entry" --dport 443 -j ACCEPT
      ;;
    *)
      # Domain name
      IPS=$(getent ahosts "$entry" | awk '{print $1}' | sort -u | grep -E '^[0-9.]+$')
      for ip in $IPS; do
        iptables -w -A OUTPUT -p tcp -d "$ip" --dport 80 -j ACCEPT
        iptables -w -A OUTPUT -p tcp -d "$ip" --dport 443 -j ACCEPT
        if [ "$entry" = "github.com" ]; then
          iptables -w -A OUTPUT -p tcp -d "$ip" --dport 22 -j ACCEPT
        fi
      done
      ;;
  esac
done

# Default policy: DROP all other output
iptables -w -P OUTPUT DROP

echo "Firewall rules applied."
