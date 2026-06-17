#!/usr/bin/env bash
# 10-system-tweaks.sh — Apply live system configuration tweaks to the running KDE session.
#
# This script ONLY writes config values and reloads KDE daemons.
# It does NOT copy any files. It is designed to be:
#   - Run standalone at any time: bash scripts/10-system-tweaks.sh
#   - Called by the main installer (after deploying files)
#   - Easily extended: add new tweak_* functions below, then call them in main()
#
# Usage:
#   bash scripts/10-system-tweaks.sh           # Apply all tweaks
#   bash scripts/10-system-tweaks.sh --list    # List available tweaks

set -uo pipefail

CYAN="\033[0;36m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RST="\033[0m"
info() { echo -e "${CYAN}[INFO]  $*${RST}"; }
ok()   { echo -e "${GREEN}[OK]    $*${RST}"; }
warn() { echo -e "${RED}[WARN]  $*${RST}"; }

echo
echo "════════════════════════════════════════════════════════"
echo "  end-4 KDE — Live System Tweaks"
echo "════════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────────────────────────
# TWEAK: Disable KDE OSD popups (volume, brightness notifications)
# ─────────────────────────────────────────────────────────────────────────────
tweak_disable_kde_osd() {
    info "Disabling KDE OSD popups (volume/brightness)..."

    # Plasma OSD daemon
    kwriteconfig6 --file plasmarc --group "OSD" --key "Enabled" "false" 2>/dev/null || true
    kwriteconfig6 --file plasmarc --group "OSD" --key "ShowOnActiveScreen" "false" 2>/dev/null || true

    # kdeglobals fallback key
    kwriteconfig6 --file kdeglobals --group "KDE" --key "OSDEnabled" "false" 2>/dev/null || true

    # plasma-volume OSD via notify
    kwriteconfig6 --file plasmanotifyrc --group "Notifications" \
        --key "LoudnessChangedOSD" "false" 2>/dev/null || true

    # powerdevil brightness OSD
    kwriteconfig6 --file powerdevilrc --group "BrightnessControl" \
        --key "showOSD" "false" 2>/dev/null || true
    kwriteconfig6 --file powerdevilrc --group "AC" \
        --key "brightnessosd" "false" 2>/dev/null || true

    # kmix OSD
    mkdir -p "$HOME/.config"
    if [[ -f "$HOME/.config/kmixrc" ]]; then
        sed -i 's/^ShowOSD=.*/ShowOSD=false/' "$HOME/.config/kmixrc" 2>/dev/null || true
        grep -q "^ShowOSD=" "$HOME/.config/kmixrc" || echo -e "\n[Global]\nShowOSD=false" >> "$HOME/.config/kmixrc"
    else
        cat > "$HOME/.config/kmixrc" <<'EOF'
[Global]
ShowOSD=false
EOF
    fi

    ok "KDE OSD popups disabled."
}

# ─────────────────────────────────────────────────────────────────────────────
# TWEAK: Create 10 virtual desktops
# ─────────────────────────────────────────────────────────────────────────────
tweak_ten_desktops() {
    info "Configuring 10 virtual desktops..."

    kwriteconfig6 --file kwinrc --group "Desktops" --key "Number" "10"
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Rows" "1"
    for i in $(seq 1 10); do
        kwriteconfig6 --file kwinrc --group "Desktops" --key "Name_$i" "Desktop $i"
    done

    ok "10 virtual desktops configured."
}

# ─────────────────────────────────────────────────────────────────────────────
# TWEAK: Register workspace switching shortcuts (Meta+1..0)
# ─────────────────────────────────────────────────────────────────────────────
tweak_workspace_shortcuts() {
    info "Registering Meta+1..0 workspace switching shortcuts..."

    # Meta+1..9 → Switch to Desktop N
    for i in $(seq 1 9); do
        kwriteconfig6 \
            --file kglobalshortcutsrc \
            --group "kwin" \
            --key "Switch to Desktop $i" \
            "Meta+$i,none,Switch to Desktop $i"
    done
    # Meta+0 → Desktop 10
    kwriteconfig6 \
        --file kglobalshortcutsrc \
        --group "kwin" \
        --key "Switch to Desktop 10" \
        "Meta+0,none,Switch to Desktop 10"

    # Meta+Shift+1..9,0 → Move window to desktop N
    for i in $(seq 1 9); do
        kwriteconfig6 \
            --file kglobalshortcutsrc \
            --group "kwin" \
            --key "Window to Desktop $i" \
            "Meta+Shift+$i,none,Move Window to Desktop $i"
    done
    kwriteconfig6 \
        --file kglobalshortcutsrc \
        --group "kwin" \
        --key "Window to Desktop 10" \
        "Meta+Shift+0,none,Move Window to Desktop 10"

    ok "Workspace shortcuts registered."
}

# ─────────────────────────────────────────────────────────────────────────────
# TWEAK: Reload KWin and KGlobalAccel to pick up config changes
# ─────────────────────────────────────────────────────────────────────────────
tweak_reload_kde() {
    info "Reloading KWin and plasma-kglobalaccel..."
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true
    kbuildsycoca6 --noincremental 2>/dev/null || true
    ok "KDE daemons reloaded."
}

# ─────────────────────────────────────────────────────────────────────────────
# ── ADD NEW TWEAKS ABOVE THIS LINE ──
# To add a new tweak:
#   1. Define a function: tweak_<name>() { ... }
#   2. Call it in the main() section below
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Main — apply all tweaks in order
# ─────────────────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--list" ]]; then
    echo
    echo "Available tweaks:"
    declare -F | awk '/^declare -f tweak_/ {print "  •", substr($3, 7)}' | sed 's/_/ /g'
    echo
    exit 0
fi

tweak_disable_kde_osd
tweak_ten_desktops
tweak_workspace_shortcuts
tweak_reload_kde

echo
echo -e "${GREEN}════════════════════════════════════════════════════════${RST}"
echo -e "${GREEN}  All system tweaks applied successfully.${RST}"
echo -e "${GREEN}════════════════════════════════════════════════════════${RST}"
echo
