# Unifi Kickout Fixer

Persistent workaround for random client disconnects on UniFi U7/E7 (Qualcomm ath11k) access points.

## Background

Some UniFi U7/E7 APs kick clients due to an overly aggressive `sta_kickout` threshold in the Qualcomm firmware. Setting it to `320` via `iwpriv` reduces false disconnects, but the setting does not survive AP reboots or reprovisions.

This container re-applies the fix on boot and every 15 minutes, and logs kickout events for analysis.

## Repository layout

```
scripts/          → install to /usr/local/bin/
config/           → copy examples to /etc/
etc/              → append bashrc-snippet.sh to /root/.bashrc
```

## Quick setup

```bash
# 1. Copy scripts
cp scripts/* /usr/local/bin/
chmod +x /usr/local/bin/*

# 2. Create config
cp config/kickout-aps.txt.example /etc/kickout-aps.txt
cp config/kickout-names.txt.example /etc/kickout-names.txt
nano /etc/kickout-aps.txt   # add your APs

# 3. Add login prompt
cat etc/bashrc-snippet.sh >> /root/.bashrc

# 4. Cron
crontab -e
# add:
# @reboot sleep 30 && /usr/local/bin/reapply-kickout.sh
# */15 * * * * /usr/local/bin/reapply-kickout.sh
# */15 * * * * /usr/local/bin/log-kickouts.sh
```

## Config format

`/etc/kickout-aps.txt` — one line per AP:

```
OSNXVb0Va96J 192.168.1.251
```

## Notes

- SSH key expected at `/root/.ssh/unifi_ap`.
- CSV log: `/var/log/kickouts.csv` (deduplicated).
- Menu options return to the prompt (no re-login needed).
- Press `u` to auto-add MACs and edit names; `c` to edit the AP list.
