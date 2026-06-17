#!/usr/bin/env bash
# workspaces.sh — Create 10 KDE virtual desktops and bind Meta+1..0 to switch.
# Idempotent: reads current desktop count, adds only what's missing.

echo "==> Configuring KDE virtual desktops..."

# ── 1. Set desktop count to 10 via kwriteconfig6 ─────────────────────────────
# KWin reads NumberOfDesktops from kwinrc on startup / reconfigure.
CURRENT_COUNT=$(kreadconfig6 --file kwinrc --group "Desktops" --key "Number" 2>/dev/null || echo "1")
echo "  Current desktop count: $CURRENT_COUNT"

if (( CURRENT_COUNT < 10 )); then
    echo "  Setting desktop count to 10..."
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Number" "10"
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Rows" "1"
    # Also name the desktops
    for i in $(seq 1 10); do
        kwriteconfig6 --file kwinrc --group "Desktops" --key "Name_$i" "Desktop $i"
    done
else
    echo "  Already have $CURRENT_COUNT desktops — skipping creation."
fi

# # ── 2. Bind Meta+1..9,0 to "Switch to Desktop N" ─────────────────────────────
# echo "  Registering Meta+1..0 workspace switching shortcuts..."
#
# # Meta+1 through Meta+9
# for i in $(seq 1 9); do
#     kwriteconfig6 \
#         --file kglobalshortcutsrc \
#         --group "kwin" \
#         --key "Switch to Desktop $i" \
#         "Meta+$i,none,Switch to Desktop $i"
# done
#
# # Meta+0 → Desktop 10
# kwriteconfig6 \
#     --file kglobalshortcutsrc \
#     --group "kwin" \
#     --key "Switch to Desktop 10" \
#     "Meta+0,none,Switch to Desktop 10"
#
# # Meta+Shift+1..9,0 → Move window to desktop N
# for i in $(seq 1 9); do
#     kwriteconfig6 \
#         --file kglobalshortcutsrc \
#         --group "kwin" \
#         --key "Window to Desktop $i" \
#         "Meta+Shift+$i,none,Move Window to Desktop $i"
# done
# kwriteconfig6 \
#     --file kglobalshortcutsrc \
#     --group "kwin" \
#     --key "Window to Desktop 10" \
#     "Meta+Shift+0,none,Move Window to Desktop 10"

# ── 3. Reconfigure KWin to pick up new settings ───────────────────────────────
echo "  Reloading KWin..."
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true

echo "[OK]  10 virtual desktops created"
