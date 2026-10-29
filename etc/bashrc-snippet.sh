# Colors for kickout prompt
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Interactive kickout prompt
if [ -t 0 ] && [ -z "$KICKOUT_PROMPT_DONE" ]; then
  export KICKOUT_PROMPT_DONE=1

  show_prompt() {
    clear
    /usr/local/bin/kickout-summary
    echo
    echo -e "  ${CYAN}f${NC}) ${YELLOW}run the fix now${NC}"
    echo -e "  ${CYAN}l${NC}) ${YELLOW}logs${NC} ${CYAN}›${NC}"
    echo -e "  ${CYAN}s${NC}) ${YELLOW}show schedule${NC}"
    echo -e "  ${CYAN}c${NC}) ${YELLOW}config${NC} ${CYAN}›${NC}"
    echo -e "  ${CYAN}w${NC}) ${YELLOW}watch${NC}"
    echo -e "  ${CYAN}a${NC}) ${YELLOW}about${NC}"
    echo -e "  ${CYAN}Enter${NC}) ${GREEN}continue${NC}"
    echo
    read -p "$(echo -e ${BOLD}Choice:${NC}) " ans
    case "$ans" in
      f|F)
        /usr/local/bin/reapply-kickout.sh
        echo; read -n 1 -p "Press any key to return..."
        show_prompt ;;
      l|L) show_logs ;;
      s|S)
        crontab -l
        echo; read -n 1 -p "Press any key to return..."
        show_prompt ;;
      c|C) show_config ;;
      w|W)
        while true; do
          clear
          /usr/local/bin/kickout-summary 50
          echo -e "\n${YELLOW}Auto-refreshing every 30s — press any key to stop${NC}"
          read -t 30 -n 1 && break
        done
        show_prompt ;;
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
        read -n 1 -p "Press any key to return..."
        show_prompt ;;
      *) ;;
    esac
  }

  show_logs() {
    clear
    /usr/local/bin/kickout-summary
    echo
    echo -e "${BOLD}${CYAN}Logs${NC}"
    echo
    echo -e "  ${CYAN}r${NC}) ${YELLOW}recent fix runs${NC}"
    echo -e "  ${CYAN}q${NC}) ${YELLOW}query examples${NC}"
    echo -e "  ${CYAN}b${NC}) ${YELLOW}back${NC}"
    echo
    read -p "$(echo -e ${BOLD}Choice:${NC}) " ans
    case "$ans" in
      r|R) tail -20 /var/log/kickout-fix.log; echo; read -n 1 -p "Press any key..."; show_logs ;;
      q|Q) kickout-help; echo; read -n 1 -p "Press any key..."; show_logs ;;
      b|B) show_prompt ;;
      *) show_logs ;;
    esac
  }

  show_config() {
    clear
    /usr/local/bin/kickout-summary
    echo
    echo -e "${BOLD}${CYAN}Config${NC}"
    echo
    echo -e "  ${CYAN}a${NC}) ${YELLOW}edit AP list${NC}"
    echo -e "  ${CYAN}n${NC}) ${YELLOW}edit device names${NC}"
    echo -e "  ${CYAN}k${NC}) ${YELLOW}edit cron jobs${NC}"
    echo -e "  ${CYAN}b${NC}) ${YELLOW}back${NC}"
    echo
    read -p "$(echo -e ${BOLD}Choice:${NC}) " ans
    case "$ans" in
      a|A) nano /etc/kickout-aps.txt; show_config ;;
      n|N) /usr/local/bin/update-kickout-names; echo; nano /etc/kickout-names.txt; show_config ;;
      k|K)
        echo
        echo -e "${BOLD}Recommended cron entries:${NC}"
        echo "  @reboot sleep 30 && /usr/local/bin/reapply-kickout.sh"
        echo "  */15 * * * * /usr/local/bin/reapply-kickout.sh"
        echo "  */15 * * * * /usr/local/bin/log-kickouts.sh"
        echo
        read -n 1 -p "Press any key to open crontab..."
        crontab -e
        show_config ;;
      b|B) show_prompt ;;
      *) show_config ;;
    esac
  }

  show_prompt
fi
