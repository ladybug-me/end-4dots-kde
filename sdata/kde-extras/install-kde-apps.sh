#!/usr/bin/env bash
# install-kde-apps.sh — Standalone installer for KDE-specific programs
# that have .config entries in repo-base: kvantum, kde-material-you-colors.
#
# Can be run independently or sourced from install.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="${BUNDLE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

log()  { echo; echo "==> $*"; }
ok()   { echo "  [OK]   $*"; }
skip() { echo "  [SKIP] $*"; }
warn() { echo "  [WARN] $*" >&2; }

pkg_installed() { pacman -Qi "$1" >/dev/null 2>&1; }

install_aur() {
    local pkg="$1"
    pkg_installed "$pkg" && { skip "$pkg (already installed)"; return 0; }
    log "Installing $pkg..."
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm --sudoloop "$pkg" && ok "$pkg" || warn "Failed: $pkg"
    else
        sudo pacman -S --needed --noconfirm "$pkg" && ok "$pkg" || warn "Failed: $pkg"
    fi
}

# ── Kvantum ───────────────────────────────────────────────────────────────────
log "Kvantum (Qt style engine)"
install_aur kvantum
install_aur kvantum-qt5 || true

# Set Kvantum theme to MaterialAdw (configs deployed by 03-deploy-configs.sh)
if command -v kvantummanager >/dev/null 2>&1; then
    kvantummanager --set MaterialAdw 2>/dev/null && ok "Kvantum theme set to MaterialAdw" || true
fi

# ── kde-material-you-colors ───────────────────────────────────────────────────
log "kde-material-you-colors"
install_aur kde-material-you-colors

# Add systemd user unit if available, else add .desktop autostart
if systemctl --user list-unit-files 2>/dev/null | grep -q "kde-material-you-colors"; then
    systemctl --user enable --now kde-material-you-colors.service 2>/dev/null && \
        ok "kde-material-you-colors systemd unit enabled" || true
else
    # Create autostart .desktop
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/kde-material-you-colors.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=KDE Material You Colors
Comment=Dynamic Material You color theming from wallpaper
Exec=kde-material-you-colors
Icon=preferences-desktop-color
Hidden=false
X-KDE-AutostartPhase=2
EOF
    ok "kde-material-you-colors autostart .desktop created"
fi

# ── Darkly ────────────────────────────────────────────────────────────────────
log "Darkly theme"
install_aur darkly-bin || install_aur darkly || true

echo
echo "======================================"
echo "  KDE apps installation complete."
echo "======================================"
