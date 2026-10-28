# UniFi Kickout Fixer

Automatically re-applies the Qualcomm `sta_kickout` threshold fix on UniFi U7/E7 access points.

## Background

Certain UniFi U7 and E7 access points (Qualcomm-based) aggressively kick clients with the reason:

```
ol_peer_sta_kickout_event_handler: Station ... kicked out reason: Excessive Retries (1)
```

This causes random disconnects, especially for weaker or IoT clients. The community-discovered workaround is to raise the threshold:

```bash
iwpriv wifi0 sta_kickout 320
iwpriv wifi1 sta_kickout 320
iwpriv wifi2 sta_kickout 320
```

The change is lost on reboot, firmware upgrade, or reprovision. This project re-applies it automatically.

## Requirements

- A Linux host that can SSH to your UniFi APs (an LXC container on Proxmox works well)
- SSH key authentication set up for the APs
- The device SSH credentials/key added in UniFi Network under  
  **Devices → Device Updates and Settings → Device SSH Settings**

## Installation

1. Copy `reapply-kickout.sh` to `/usr/local/bin/` and make it executable:
   ```bash
   chmod +x /usr/local/bin/reapply-kickout.sh
   ```

2. Edit the script and set:
   - `SSH_USER` — the device SSH username from UniFi
   - `SSH_KEY` — path to your private key
   - `APS` — array of your AP IP addresses

3. Test it:
   ```bash
   /usr/local/bin/reapply-kickout.sh
   ```

4. Schedule it with cron:
   ```bash
   crontab -e
   ```
   Add:
   ```cron
   @reboot sleep 30 && /usr/local/bin/reapply-kickout.sh
   */15 * * * * /usr/local/bin/reapply-kickout.sh
   ```

## Optional: Login banner

Copy the contents of the `motd` file to `/etc/motd` on the host that runs the script. It shows the purpose and useful commands on login.

## Logs

The script writes timestamped results to `/var/log/kickout-fix.log`.

## Notes

- `sta_kickout` is set-only on current UniFi firmware (no getter).
- The value `320` matches the threshold used by upstream ath11k and has been widely reported as effective.
- You can add more APs by extending the `APS` array.

## License

MIT
