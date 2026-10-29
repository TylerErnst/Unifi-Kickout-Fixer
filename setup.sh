#!/bin/bash
# Unifi Kickout Fixer — initial setup
# Run from the repo root after cloning: sudo ./setup.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  Unifi Kickout Fixer — Setup Wizard"
echo "============================================"
echo
echo "This will install scripts, configure your APs,"
echo "and set up SSH access."
echo

# 1. Install scripts
echo "[1/5] Installing scripts to /usr/local/bin/..."
cp "$REPO_DIR/scripts/"* /usr/local/bin/
chmod +x /usr/local/bin/reapply-kickout.sh \
         /usr/local/bin/log-kickouts.sh \
         /usr/local/bin/kickout-summary \
         /usr/local/bin/kickout-help \
         /usr/local/bin/update-kickout-names
echo "      Done."

# 2. Config files
echo
echo "[2/5] Setting up config files..."
[ -f /etc/kickout-aps.txt ] || cp "$REPO_DIR/config/kickout-aps.txt.example" /etc/kickout-aps.txt
[ -f /etc/kickout-names.txt ] || cp "$REPO_DIR/config/kickout-names.txt.example" /etc/kickout-names.txt
echo "      Done."

# 3. AP list — multi-controller
echo
echo "[3/5] Configure your Access Points"
echo
echo "UniFi uses one SSH username per controller."
echo "Find it in: UniFi Devices → Device Updates and Settings → Device SSH Settings"
echo
echo "You can add APs from multiple controllers."
echo "Leave the username blank to finish."
echo

> /etc/kickout-aps.txt
controller=1
while true; do
  echo
  read -p "Controller $controller SSH username (blank to finish): " ssh_user
  [ -z "$ssh_user" ] && break

  echo "  Enter AP IPs for this controller. Blank IP to finish this controller."
  while true; do
    read -p "    AP IP: " ip
    [ -z "$ip" ] && break
    echo "$ssh_user $ip" >> /etc/kickout-aps.txt
    echo "    → Added: $ssh_user @ $ip"
  done

  controller=$((controller + 1))
done

if [ ! -s /etc/kickout-aps.txt ]; then
  echo
  echo "  No APs configured. You can edit /etc/kickout-aps.txt later."
fi

# 4. SSH key
echo
echo "[4/5] SSH Key Setup"
echo
if [ ! -f /root/.ssh/unifi_ap ]; then
  echo "No SSH key found. Generating one..."
  mkdir -p /root/.ssh
  ssh-keygen -t ed25519 -f /root/.ssh/unifi_ap -N "" -q
  echo
  echo "┌─────────────────────────────────────────────────────────┐"
  echo "│  Add this public key in each UniFi controller           │"
  echo "└─────────────────────────────────────────────────────────┘"
  echo
  cat /root/.ssh/unifi_ap.pub
  echo
  echo "Where to paste it (on each controller):"
  echo "  UniFi Devices → Device Updates and Settings"
  echo "  → Device SSH Settings → SSH Key"
  echo
  echo "Save/Apply on each controller."
  echo
  read -p "Press Enter once the key is added..."
else
  echo "SSH key already exists at /root/.ssh/unifi_ap"
  echo
  echo "Public key (add to any new controllers):"
  cat /root/.ssh/unifi_ap.pub
  echo
fi

# 5. bashrc snippet
echo
echo "[5/5] Login prompt"
if ! grep -q "KICKOUT_PROMPT_DONE" /root/.bashrc 2>/dev/null; then
  echo "Adding interactive menu to /root/.bashrc..."
  cat "$REPO_DIR/etc/bashrc-snippet.sh" >> /root/.bashrc
  echo "      Done. Log out and back in to see it."
else
  echo "Login prompt already present in .bashrc"
fi

# 6. Cron
echo
echo "────────────────────────────────────────────"
echo "Optional: Automatic scheduling"
echo "────────────────────────────────────────────"
echo
echo "These cron jobs re-apply the fix and collect logs:"
echo "  @reboot sleep 30 && /usr/local/bin/reapply-kickout.sh"
echo "  */15 * * * * /usr/local/bin/reapply-kickout.sh"
echo "  */15 * * * * /usr/local/bin/log-kickouts.sh"
echo
read -p "Add them to root's crontab now? (y/N): " addcron
if [ "$addcron" = "y" ] || [ "$addcron" = "Y" ]; then
  (crontab -l 2>/dev/null | grep -v kickout; \
   echo "@reboot sleep 30 && /usr/local/bin/reapply-kickout.sh"; \
   echo "*/15 * * * * /usr/local/bin/reapply-kickout.sh"; \
   echo "*/15 * * * * /usr/local/bin/log-kickouts.sh") | crontab -
  echo "Cron updated."
else
  echo "Skipped. Add them later with: crontab -e"
fi

echo
echo "============================================"
echo "  Setup complete"
echo "============================================"
echo
echo "Next steps:"
echo "  • Log out and back in to see the menu"
echo "  • Test with: /usr/local/bin/reapply-kickout.sh"
echo "  • Edit APs anytime: nano /etc/kickout-aps.txt"
echo "  • Edit device names: nano /etc/kickout-names.txt"
echo