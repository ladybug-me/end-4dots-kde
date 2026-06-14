#!/usr/bin/env bash
# 08-kde-apps.sh — Install KDE-specific applications:
#   - kvantum + kvantum-qt5 (Qt style engine for Material You look)
#   - kde-material-you-colors (AUR widget/daemon for wallpaper-adaptive colors)
#
# Idempotent: checks pacman -Qi before installing.

echo
echo "════════════════════════════════════════"
echo "  Step 8/9 — KDE Extra Apps"
echo "════════════════════════════════════════"

install_if_missing() {
    local pkg="$1"
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        echo "  [SKIP] $pkg already installed."
        return 0
    fi
    echo "  Installing $pkg..."
    yay -S --needed ${CONFIRM_ARG:-} "$pkg" 2>/dev/null || \
    sudo pacman -S --needed ${CONFIRM_ARG:-} "$pkg" 2>/dev/null || {
        echo "  [WARN] Could not install $pkg — skipping."
        return 1
    }
    echo "  [OK]  $pkg installed."
}

# ── Kvantum ───────────────────────────────────────────────────────────────────
install_if_missing kvantum
install_if_missing kvantum-qt5 || true   # optional qt5 support

# ── kde-material-you-colors ───────────────────────────────────────────────────
install_if_missing kde-material-you-colors

# ── darkly (plasma theme) ─────────────────────────────────────────────────────
# (darkly is installed via illogical-impulse-fonts-themes in installDP.sh)

echo "[OK]  KDE extra apps step complete."
