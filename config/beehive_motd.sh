#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Bee-Hive OS — MOTD / Welcome Banner v1.1.0
# Compatible: Kitty + Fish + Zsh + Bash
# ═══════════════════════════════════════════════════════════════

HONEY="\e[38;2;255;184;28m"   # #FFB81C
WHITE="\e[38;2;255;255;255m"  # #FFFFFF
GREY="\e[38;2;170;170;170m"   # #AAAAAA
BOLD="\e[1m"
RESET="\e[0m"

echo -e "${HONEY}${BOLD}"
cat << 'LOGO'
      ___________
     / ========= \
    / =+===+===+= \
   | =+==========+= |
   | =+===+===+===+= |      +-+-+-+
   | =+= BEE-HIVE =+= |     |B|E|E|
   | =+===+===+===+= |      +-+-+-+-+-+-+
   | =+==========+= |       |H|I|V|E|O|S|
    \ =+===+===+= /          +-+-+-+-+-+-+
     \ ========= /
      `---------`
       |=+=+=+=|
       | HONEY |
       |=+=+=+=|
        `-----`
LOGO
echo -e "${RESET}"
echo -e "${WHITE}${BOLD}  Bee-Hive OS${RESET}  ${GREY}by Marc & Maya 🐝${RESET}"
echo -e "${GREY}  Hyprland $(hyprctl version 2>/dev/null | grep -oP 'v[\d.]+' | head -1)  •  Quickshell  •  CachyOS${RESET}"
echo -e "${GREY}  Kernel $(uname -r | cut -d'-' -f1)  •  $(date '+%A %d %B %Y')${RESET}"
echo -e "${HONEY}  ─────────────────────────────────────────${RESET}"
echo ""
