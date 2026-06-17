#!/usr/bin/env bash
# 09-finalize.sh — Final step: installation summary and instructions.

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
RST="\033[0m"

echo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${RST}"
echo -e "${GREEN}║${RST}                                                          ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  ${GREEN}✅  Installation complete!${RST}                              ${GREEN}║${RST}"
echo -e "${GREEN}║                                                          ║${RST}"
echo -e "${GREEN}║${RST}  What was set up:                                        ${GREEN}║${RST}"
if [[ "$BASE_DISTRO" == "arch" ]]; then
    echo -e "${GREEN}║${RST}  • System updated (pacman -Syu)                          ${GREEN}║${RST}"
else
    echo -e "${GREEN}║${RST}  • System updated (dnf upgrade)                          ${GREEN}║${RST}"
fi
echo -e "${GREEN}║${RST}  • Packages installed (PKGBUILDs + fonts + dependencies) ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • Configs (repo-base + KDE overrides, clean deploy)     ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • Default wallpaper configured                          ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • Darkly theme (plasma + app + window decoration)       ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • Kvantum + MaterialAdw widget style                    ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • 10 virtual desktops (Meta+1..0 to switch)             ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • Keyboard shortcuts (Kde native + keyd)                ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • Quickshell + kde-material-you-colors autostart        ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}  • KDE OSDs disabled (volume/brightness popups)          ${GREEN}║${RST}"
echo -e "${GREEN}║${RST}                                                          ${GREEN}║${RST}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${RST}"
echo

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${YELLOW}  ⚠  ACTION REQUIRED — Please do the following:${RST}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo
echo -e "  ${MAGENTA}1. LOG OUT now${RST} and log back in."
echo -e "     A fresh login is required to fully apply all KDE and"
echo -e "     Quickshell changes."
echo -e "  ${YELLOW}WARNING:${RST}If a kernel update occured, ${YELLOW}===reboot===${RST} immediately."
echo
echo -e "  ${MAGENTA}2. REMOVE ALL KDE PANELS${RST} after logging back in."
echo -e "     Right-click the panel → \"Panel configuration\" → remove"
echo -e "     every existing KDE panel for optimal behaviour with"
echo -e "     the Quickshell bar."
echo

echo -e "  ${MAGENTA}3. TO ENTER EDIT MODE NEXT TIME${RST}"
echo -e "     Press Super+D → \"Right Click on Desktop\" → Enter Edit mode"
echo
echo -e "${CYAN}  You can re-run this installer at any time — it is idempotent.${RST}"
echo
echo -e "${CYAN}  Shortcuts not working or other problems? Check the troubleshooting steps on github."
echo -e

# Prompt user for immediate logout
read -p "Would you like to log out now? (y/N): " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        echo "Logging out..."
        qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null
        ;;
    *)
        echo "Exiting script. Please remember to log out manually later."
        exit 0
        ;;
esac
