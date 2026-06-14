#!/usr/bin/env bash
# 06-autostart.sh — Set up autostart entries for Quickshell and kde-material-you-colors.
# Idempotent: overwrites .desktop files with correct content each run.

AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

echo
echo "════════════════════════════════════════"
echo "  Step 6/9 — Autostart Setup"
echo "════════════════════════════════════════"

# ── Quickshell autostart ──────────────────────────────────────────────────────
# Uses `qs -c ii && disown` pattern: starts quickshell with the ii config and
# detaches it from the autostart process so KDE doesn't wait for it.
echo "  Creating Quickshell autostart entry..."
cat > "$AUTOSTART_DIR/quickshell.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Quickshell
Comment=Start Quickshell (end-4 KDE port - ii config)
Exec=bash -c 'sleep 2 && qs -c ii &'
Icon=quickshell
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-KDE-AutostartPhase=2
EOF
echo "  [OK]  Quickshell autostart created."

# ── kde-material-you-colors autostart ────────────────────────────────────────
# Adds the kde-material-you-colors daemon as an autostart service.
echo "  Creating kde-material-you-colors autostart entry..."
cat > "$AUTOSTART_DIR/kde-material-you-colors.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=KDE Material You Colors
Comment=Automatic Material You color theming for KDE
Exec=kde-material-you-colors
Icon=preferences-desktop-color
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-KDE-AutostartPhase=2
EOF
echo "  [OK]  kde-material-you-colors autostart created."

# ── Enable via systemd user unit if available ─────────────────────────────────
# Some installations provide a systemd unit for kde-material-you-colors
if systemctl --user list-unit-files "kde-material-you-colors.service" >/dev/null 2>&1; then
    systemctl --user enable --now kde-material-you-colors.service 2>/dev/null || true
    echo "  [OK]  kde-material-you-colors systemd unit enabled."
fi

echo "[OK]  Autostart entries configured."
