# Unifi Kickout Fixer

Persistent workaround for random client disconnects on UniFi U7/E7 (Qualcomm ath11k) access points.

## Background

Some UniFi U7/E7 APs kick clients due to an overly aggressive `sta_kickout` threshold in the Qualcomm firmware. Setting it to `320` via `iwpriv` reduces false disconnects, but the setting does not survive AP reboots or reprovisions.

This container re-applies the fix on boot and every 15 minutes, and logs kickout events for analysis.

## Repository layout

```
setup.sh          → run this for guided install
scripts/          → install to /usr/local/bin/
config/           → copy examples to /etc/
etc/              → append bashrc-snippet.sh to /root/.bashrc
```

## Quick setup

```bash
git clone https://github.com/TylerErnst/unifi-kickout-fixer.git
cd unifi-kickout-fixer
sudo ./setup.sh
```

The wizard will:
1. Install the scripts to `/usr/local/bin/`
2. Ask for each controller’s SSH username, then its AP IPs
3. Generate an SSH key (if needed) and tell you where to paste it in UniFi
4. Add the interactive login menu to `/root/.bashrc`
5. Optionally install the cron jobs

Leave the username blank to finish adding controllers.

## Manual setup

```bash
cp scripts/* /usr/local/bin/
chmod +x /usr/local/bin/*
cp config/kickout-aps.txt.example /etc/kickout-aps.txt
cp config/kickout-names.txt.example /etc/kickout-names.txt
nano /etc/kickout-aps.txt
cat etc/bashrc-snippet.sh >> /root/.bashrc
```

Then add cron jobs:

```cron
@reboot sleep 30 && /usr/local/bin/reapply-kickout.sh
*/15 * * * * /usr/local/bin/reapply-kickout.sh
*/15 * * * * /usr/local/bin/log-kickouts.sh
```

## Config format

`/etc/kickout-aps.txt` — one line per AP:

```
ui 192.168.1.251
ui 192.168.1.252
othercontroller 10.0.0.5
```

The username is the Device SSH username from the UniFi controller that manages that AP  
(UniFi Devices → Device Updates and Settings → Device SSH Settings).

## Files

| File | Purpose |
|------|---------|
| `setup.sh` | Guided installer |
| `scripts/reapply-kickout.sh` | Applies `sta_kickout 320` via SSH |
| `scripts/log-kickouts.sh` | Pulls unique kickout events into CSV |
| `scripts/kickout-summary` | Login summary with drop counts |
| `scripts/kickout-help` | Example log queries |
| `scripts/update-kickout-names` | Auto-adds MACs from the last 7 days |
| `etc/bashrc-snippet.sh` | Interactive menu (append to `.bashrc`) |
| `config/*.example` | Example config files |

## Notes

- SSH key expected at `/root/.ssh/unifi_ap`.
- CSV log: `/var/log/kickouts.csv` (deduplicated by dmesg timestamp).
- Menu options return to the prompt (no re-login needed).
- Press `u` to auto-add MACs and edit names; `c` to edit the AP list.
- Device names are optional (`/etc/kickout-names.txt`).
