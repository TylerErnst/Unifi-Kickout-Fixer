#!/bin/bash
# Re-apply sta_kickout=320 on UniFi U7/E7 APs

SSH_USER="OSNXVb0Va96J"
SSH_KEY="/root/.ssh/unifi_ap"
APS=("192.168.1.251")

for ap in "${APS[@]}"; do
  echo "Applying to $ap..."
  if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
       "$SSH_USER@$ap" \
       "iwpriv wifi0 sta_kickout 320; iwpriv wifi1 sta_kickout 320; iwpriv wifi2 sta_kickout 320; iwpriv wifi3 sta_kickout 320 && logger -t kickout-fix 'applied 320'"; then
    echo "$(date): OK: $ap" | tee -a /var/log/kickout-fix.log
  else
    echo "$(date): FAILED: $ap" | tee -a /var/log/kickout-fix.log
  fi
done
