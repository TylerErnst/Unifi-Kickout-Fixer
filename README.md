# Unifi Kickout Fixer

Persistent workaround for random client disconnects on UniFi U7/E7 (Qualcomm ath11k) access points.

## Background

Some UniFi U7/E7 APs kick clients due to an overly aggressive `sta_kickout` threshold in the Qualcomm firmware. Setting it to `320` via `iwpriv` reduces false disconnects, but the setting does not survive AP reboots or reprovisions.

This container re-applies the fix on boot and every 15 minutes, and logs kickout events for analysis.

## Files

| File | Purpose |
|------|---------|
| `reapply-kickout.sh` | Applies `sta_kickout 320` to all radios via SSH |
| `log-kickouts.sh` | Pulls unique kickout events from AP `dmesg` into CSV |
| `kickout-summary` | Login summary with aligned drop counts and device names |
| `kickout-help` | Shows example `awk` queries for the CSV log |
| `update-kickout-names` | Auto-adds MACs from the last 7 days to the names file |
| `bashrc-snippet.sh` | Interactive all-letter login prompt (f/l/s/h/u/r/w/a) |
| `kickout-names.txt` | Optional MAC → friendly name mapping |

## Quick setup

1. Create a minimal Debian LXC (or VM) on Proxmox.
2. Copy the scripts to `/usr/local/bin/` and `chmod +x` them.
3. Set up SSH key auth to your APs.
4. Edit the `APS` array in the scripts with your AP IPs.
5. Optionally edit `/etc/kickout-names.txt` for device names.
6. Add the cron jobs and append `bashrc-snippet.sh` to `/root/.bashrc`.

## Cron

```cron
@reboot sleep 30 && /usr/local/bin/reapply-kickout.sh
*/15 * * * * /usr/local/bin/reapply-kickout.sh
*/15 * * * * /usr/local/bin/log-kickouts.sh
```

## Notes

- The fix is applied per-radio (`wifi0`–`wifi3`).
- CSV log is at `/var/log/kickouts.csv` (deduplicated by dmesg timestamp).
- Drop counts are right-aligned for readability.
- Menu options pause and return to the prompt (no re-login needed).
- Press `u` to auto-add new MACs and edit names in nano.
- See `kickout-help` for query examples.
