#!/usr/bin/env bash
# 01-ensure-yay.sh — Ensure yay AUR helper is installed.
# Idempotent: exits immediately if yay is already present.

ensure_yay() {
    if command -v yay >/dev/null 2>&1; then
        echo "[OK]  yay is already installed."
        return 0
    fi

    echo "==> yay not found — installing..."

    if ! command -v pacman >/dev/null 2>&1; then
        echo "[ERR] pacman not found. This installer requires Arch Linux."
        exit 1
    fi

    sudo pacman -S --needed --noconfirm base-devel git

    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir"
    (
        cd "$tmpdir"
        makepkg -si --noconfirm
    )
    rm -rf "$tmpdir"
    echo "[OK]  yay installed."
}

ensure_yay

echo "==> Configuring yay sudo looping..."
yay --sudoloop --save 2>/dev/null || true
echo "[OK]  yay configured."
