#!/bin/bash
# Pull unique kickout events from APs into CSV
# Reads APs from /etc/kickout-aps.txt (format: username IP)

SSH_KEY="/root/.ssh/unifi_ap"
CONFIG="/etc/kickout-aps.txt"
CSV="/var/log/kickouts.csv"
STATE="/var/log/kickouts.state"

[ -f "$CONFIG" ] || exit 1
[ -f "$CSV" ] || echo "timestamp,ap_ip,mac,reason,dmesg_ts" > "$CSV"

declare -A LAST_TS
[ -f "$STATE" ] && while IFS='=' read -r ap ts; do LAST_TS["$ap"]="$ts"; done < "$STATE"

while read -r user ip; do
  [ -z "$user" ] || [ -z "$ip" ] && continue
  last="${LAST_TS[$ip]:-0}"
  max_ts="$last"

  while IFS= read -r line; do
    dmesg_ts=$(echo "$line" | sed -n 's/^\[\([0-9.]*\)\].*/\1/p')
    if awk -v a="$dmesg_ts" -v b="$last" 'BEGIN { exit !(a > b) }'; then
      mac=$(echo "$line" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1)
      reason=$(echo "$line" | sed -n 's/.*reason: \(.*\), associd.*/\1/p')
      ts=$(date -u +"%Y-%m-%d %H:%M:%S")
      if [ -n "$mac" ] && [ -n "$dmesg_ts" ]; then
        echo "$ts,$ip,$mac,\"$reason\",$dmesg_ts" >> "$CSV"
        awk -v a="$dmesg_ts" -v b="$max_ts" 'BEGIN { exit !(a > b) }' && max_ts="$dmesg_ts"
      fi
    fi
  done < <(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
             "$user@$ip" "dmesg | grep -i 'ol_peer_sta_kickout_event_handler'" 2>/dev/null)

  LAST_TS["$ip"]="$max_ts"
done < "$CONFIG"

: > "$STATE"
for ap in "${!LAST_TS[@]}"; do echo "$ap=${LAST_TS[$ap]}" >> "$STATE"; done
