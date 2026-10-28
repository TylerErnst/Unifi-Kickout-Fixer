# Colors for kickout prompt
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Interactive kickout prompt (only on interactive login)
if [ -t 0 ] && [ -z "$KICKOUT_PROMPT_DONE" ]; then
  export KICKOUT_PROMPT_DONE=1
  /usr/local/bin/kickout-summary
  echo
  echo -e "  ${CYAN}1${NC}) ${YELLOW}run the fix now${NC}          ${CYAN}/usr/local/bin/reapply-kickout.sh${NC}"
  echo -e "  ${CYAN}2${NC}) ${YELLOW}view recent fix runs${NC}     ${CYAN}tail -20 /var/log/kickout-fix.log${NC}"
  echo -e "  ${CYAN}3${NC}) ${YELLOW}show schedule${NC}            ${CYAN}crontab -l${NC}"
  echo -e "  ${CYAN}h${NC}) ${YELLOW}log query examples${NC}       ${CYAN}kickout-help${NC}"
  echo -e "  ${CYAN}a${NC}) ${YELLOW}about this system${NC}"
  echo -e "  ${CYAN}Enter${NC}) ${GREEN}continue${NC}"
  echo
  read -p "$(echo -e ${BOLD}Choice:${NC}) " ans
  case "$ans" in
    1) /usr/local/bin/reapply-kickout.sh ;;
    2) tail -20 /var/log/kickout-fix.log ;;
    3) crontab -l ;;
    h|H) kickout-help ;;
    a|A)
      echo
      echo -e "${BOLD}${CYAN}About Unifi Kickout Fixer${NC}"
      echo
      echo "This container re-applies a Qualcomm firmware workaround on UniFi U7/E7 APs."
      echo "Some clients get randomly disconnected due to an overly aggressive 'sta_kickout'"
      echo "threshold in the ath11k driver. Setting it to 320 reduces false kicks."
      echo
      echo "The setting does not survive AP reboots or reprovisions, so this container"
      echo "SSHes in and re-applies it on boot and every 15 minutes."
      echo
      echo "It also logs kickout events to /var/log/kickouts.csv so you can see which"
      echo "devices are being dropped and how often."
      echo
      ;;
    *) ;;
  esac
fi
