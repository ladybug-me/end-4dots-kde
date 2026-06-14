#!/usr/bin/env bash
# 00-banner.sh — Display the installer greeting and credits.

print_banner() {
    local CYAN="\033[0;36m"
    local BLUE="\033[0;34m"
    local MAGENTA="\033[0;35m"
    local YELLOW="\033[1;33m"
    local WHITE="\033[1;37m"
    local DIM="\033[2m"
    local RST="\033[0m"

    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${RST}"
    echo -e "${CYAN}║${RST}                                                                  ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${WHITE}✦  end-4 dots — KDE Plasma 6 Port  ✦${RST}                            ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}                                                                  ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${DIM}Original Hyprland dotfiles by:${RST}                                  ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${YELLOW}  end-4${RST}  ${DIM}→${RST}  ${BLUE}https://github.com/end-4/dots-hyprland${RST}              ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}                                                                  ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${DIM}KDE port and modifications by:${RST}                                  ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${YELLOW}  ladybug-me${RST}                                                    ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}                                                                  ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${DIM}Quickshell KDE bridge, Custom hyrpctl for KDE,${RST}                  ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${DIM}usability first features support, workspace support, shortcuts,${RST} ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}  ${DIM}brightness/volume scroll, Material You theming and more.${RST}        ${CYAN}║${RST}"
    echo -e "${CYAN}║${RST}                                                                  ${CYAN}║${RST}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${RST}"
    echo

    echo -e "  ${DIM}This installer is idempotent — safe to run multiple times.${RST}"
    echo -e "  ${DIM}Existing configs will be backed up to installer folder before any changes.${RST}"
    echo
}

print_banner
