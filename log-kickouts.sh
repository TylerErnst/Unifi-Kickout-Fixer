#!/bin/bash
# Pull unique kickout events from APs into CSV

SSH_USER="OSNXVb0Va96J"
SSH_KEY="/root/.ssh/unifi_ap"
APS=("192.168.1.251")
CSV="/var/log/kickouts.csv"
STATE="/var/log/kickouts.state"

if [ ! -f "$CSV" ]; then
  echo "timestamp,ap_ip,mac,reason,dmesg_ts" > "$CSV"
fi

declare -A LAST_TS
if [ -f "$STATE" ]; then
  while IFS='=' read -r ap ts; do
    LAST_TS["$ap"]="$ts"
  done < "$STATE"
fi

for ap in "${APS[@]}"; do
  last="${LAST_TS[$ap]:-0}"
  max_ts="$last"

  while IFS= read -r line; do
    dmesg_ts=$(echo "$line" | sed -n 's/^\[\([0-9.]*\)\].*/\1/p')
    if awk -v a="$dmesg_ts" -v b="$last" 'BEGIN { exit !(a > b) }'; then
      mac=$(echo "$line" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1)
      reason=$(echo "$line" | sed -n 's/.*reason: \(.*\), associd.*/\1/p')
      ts=$(date -u +"%Y-%m-%d %H:%M:%S")
      if [ -n "$mac" ] && [ -n "$dmesg_ts" ]; then
        echo "$ts,$ap,$mac,\"$reason\",$dmesg_ts" >> "$CSV"
        if awk -v a="$dmesg_ts" -v b="$max_ts" 'BEGIN { exit !(a > b) }'; then
          max_ts="$dmesg_ts"
        fi
      fi
    fi
  done < <(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
             "$SSH_USER@$ap" "dmesg | grep -i 'ol_peer_sta_kickout_event_handler'" 2>/dev/null)

  LAST_TS["$ap"]="$max_ts"
done

: > "$STATE"
for ap in "${!LAST_TS[@]}"; do
  echo "$ap=${LAST_TS[$ap]}" >> "$STATE"
done
