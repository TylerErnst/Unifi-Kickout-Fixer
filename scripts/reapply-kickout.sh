#!/bin/bash
# Re-apply sta_kickout=320 on UniFi U7/E7 APs
# Reads APs from /etc/kickout-aps.txt (format: username IP)

SSH_KEY="/root/.ssh/unifi_ap"
CONFIG="/etc/kickout-aps.txt"

[ -f "$CONFIG" ] || { echo "No config: $CONFIG"; exit 1; }

while read -r user ip; do
  [ -z "$user" ] || [ -z "$ip" ] && continue
  echo "Applying to $ip ($user)..."
  if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
       "$user@$ip" \
       "iwpriv wifi0 sta_kickout 320; iwpriv wifi1 sta_kickout 320; iwpriv wifi2 sta_kickout 320; iwpriv wifi3 sta_kickout 320 && logger -t kickout-fix 'applied 320'"; then
    echo "$(date): OK: $ip" | tee -a /var/log/kickout-fix.log
  else
    echo "$(date): FAILED: $ip" | tee -a /var/log/kickout-fix.log
  fi
done < "$CONFIG"
