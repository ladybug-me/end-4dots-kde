#!/usr/bin/env bash
# 07-services.sh — Enable systemd user services and reload KWin.

echo
echo "════════════════════════════════════════"
echo "  Step 7/9 — Services & KWin"
echo "════════════════════════════════════════"

# ── qs-kwin-bridge systemd service ────────────────────────────────────────────
if [[ -f "$HOME/.config/systemd/user/qs-kwin-bridge.service" ]] && \
   [[ -s "$HOME/.config/systemd/user/qs-kwin-bridge.service" ]]; then
    echo "  Enabling qs-kwin-bridge service..."
    systemctl --user daemon-reload
    systemctl --user enable --now qs-kwin-bridge.service 2>/dev/null || true
    echo "  [OK]  qs-kwin-bridge enabled."
else
    echo "  [SKIP] qs-kwin-bridge.service is empty/missing — skipping."
fi

# ── Reload KWin and KGlobalAccel ─────────────────────────────────────────────
echo "  Reloading KWin..."
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "  Restarting plasma-kglobalaccel..."
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true

echo "[OK]  Services configured."
