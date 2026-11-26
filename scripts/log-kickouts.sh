#!/bin/bash
# Pull unique kickout events from APs into CSV
# Survives AP reboots by tracking boot time

SSH_KEY="/root/.ssh/unifi_ap"
CONFIG="/etc/kickout-aps.txt"
CSV="/var/log/kickouts.csv"
STATE="/var/log/kickouts.state"

[ -f "$CONFIG" ] || exit 1
[ -f "$CSV" ] || echo "timestamp,ap_ip,mac,reason,dmesg_ts" > "$CSV"

declare -A LAST_TS
declare -A LAST_BOOT

# Load previous state (format: ip=ts|boot)
if [ -f "$STATE" ]; then
  while IFS='=' read -r ap rest; do
    ts="${rest%%|*}"
    boot="${rest#*|}"
    LAST_TS["$ap"]="$ts"
    LAST_BOOT["$ap"]="$boot"
  done < "$STATE"
fi

while read -r user ip; do
  # Skip blank lines and comments
  [[ -z "$user" || "$user" =~ ^# || -z "$ip" ]] && continue

  # Get current boot time from the AP (seconds since epoch via /proc/stat btime)
  boot=$(ssh -n -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
           "$user@$ip" "awk '/btime/ {print \$2}' /proc/stat" 2>/dev/null)
  [ -z "$boot" ] && continue

  last_ts="${LAST_TS[$ip]:-0}"
  last_boot="${LAST_BOOT[$ip]:-0}"

  # If the AP rebooted, reset the timestamp watermark
  if [ "$boot" != "$last_boot" ]; then
    last_ts=0
  fi

  max_ts="$last_ts"

  while IFS= read -r line; do
    dmesg_ts=$(echo "$line" | sed -n 's/^\[\([0-9.]*\)\].*/\1/p')
    if awk -v a="$dmesg_ts" -v b="$last_ts" 'BEGIN { exit !(a > b) }'; then
      mac=$(echo "$line" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1)
      reason=$(echo "$line" | sed -n 's/.*reason: \(.*\), associd.*/\1/p')
      ts=$(date -u +"%Y-%m-%d %H:%M:%S")
      if [ -n "$mac" ] && [ -n "$dmesg_ts" ]; then
        echo "$ts,$ip,$mac,\"$reason\",$dmesg_ts" >> "$CSV"
        if awk -v a="$dmesg_ts" -v b="$max_ts" 'BEGIN { exit !(a > b) }'; then
          max_ts="$dmesg_ts"
        fi
      fi
    fi
  done < <(ssh -n -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
             "$user@$ip" "dmesg | grep -i 'ol_peer_sta_kickout_event_handler'" 2>/dev/null)

  LAST_TS["$ip"]="$max_ts"
  LAST_BOOT["$ip"]="$boot"
done < "$CONFIG"

# Write state back
: > "$STATE"
for ap in "${!LAST_TS[@]}"; do
  echo "$ap=${LAST_TS[$ap]}|${LAST_BOOT[$ap]}" >> "$STATE"
done
