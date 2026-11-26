#!/bin/bash
# Re-apply sta_kickout=320 on UniFi U7/E7 APs
# Reads APs from /etc/kickout-aps.txt (format: username IP)

SSH_KEY="/root/.ssh/unifi_ap"
CONFIG="/etc/kickout-aps.txt"
LOG="/var/log/kickout-fix.log"

[ -f "$CONFIG" ] || { echo "No config: $CONFIG"; exit 1; }

while read -r user ip; do
  # Skip blank lines and comments
  [[ -z "$user" || "$user" =~ ^# || -z "$ip" ]] && continue

  echo "Applying to $ip ($user)..."

  if ssh -n -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
       "$user@$ip" \
       'applied=0; for iface in wifi0 wifi1 wifi2 wifi3; do
          [ -d "/sys/class/net/$iface" ] && iwpriv "$iface" sta_kickout 320 && applied=1
        done
        [ "$applied" -eq 1 ] && logger -t kickout-fix "applied 320"'; then
    echo "$(date): OK: $ip" | tee -a "$LOG"
  else
    echo "$(date): FAILED: $ip" | tee -a "$LOG"
  fi
done < "$CONFIG"
