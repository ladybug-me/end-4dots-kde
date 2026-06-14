#!/usr/bin/env bash
# 03-deploy-configs.sh — Deploy configuration files to ~/.config and ~/.local
#
# Strategy (clean + idempotent):
#   1. Backup existing configs that will be touched.
#   2. REMOVE the target dirs that match our source (clean slate).
#   3. Copy src/repo-base/.config/* → ~/.config/
#   4. Copy src/repo-base/.local/*  → ~/.local/
#   5. Copy src/config/* → ~/.config/ (KDE overrides — these overwrite repo-base)
#   6. Deploy bridge files (bin, applications, systemd, kwin script)
#   7. Set default wallpaper in quickshell config.json
#   8. Set wallpaper for kde-material-you-colors

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"
SRC_DIR="$BUNDLE_DIR/src"
BACKUP_DIR="$BUNDLE_DIR/backups/$(date +%Y%m%d_%H%M%S)"

echo
echo "════════════════════════════════════════"
echo "  Step 3/9 — Config Deployment"
echo "════════════════════════════════════════"

mkdir -p "$BACKUP_DIR/config" "$BACKUP_DIR/local"

# ── Step A: Backup anything we'll overwrite ───────────────────────────────────
echo "  Backing up existing configs to $BACKUP_DIR ..."
for item in "$SRC_DIR"/config/*; do
    name="$(basename "$item")"
    [[ -e "$HOME/.config/$name" ]] && cp -r "$HOME/.config/$name" "$BACKUP_DIR/config/" 2>/dev/null || true
done
for item in "$SRC_DIR"/repo-base/.config/*; do
    name="$(basename "$item")"
    [[ -e "$HOME/.config/$name" ]] && cp -r "$HOME/.config/$name" "$BACKUP_DIR/config/" 2>/dev/null || true
done
for item in "$SRC_DIR"/repo-base/.local/share/*; do
    name="$(basename "$item")"
    [[ -e "$HOME/.local/share/$name" ]] && cp -r "$HOME/.local/share/$name" "$BACKUP_DIR/local/" 2>/dev/null || true
done
# Also backup kglobalshortcutsrc and kwinrc
cp ~/.config/kglobalshortcutsrc "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.config/kwinrc "$BACKUP_DIR/" 2>/dev/null || true
echo "  [OK]  Backup complete."

# ── Step B: Remove target dirs that match source (clean slate) ────────────────
echo "  Removing old config dirs that will be replaced..."
for item in "$SRC_DIR"/config/*; do
    name="$(basename "$item")"
    if [[ -e "$HOME/.config/$name" ]]; then
        rm -rf "$HOME/.config/$name"
        echo "    Removed: ~/.config/$name"
    fi
done
for item in "$SRC_DIR"/repo-base/.config/*; do
    name="$(basename "$item")"
    if [[ -e "$HOME/.config/$name" ]]; then
        rm -rf "$HOME/.config/$name"
        echo "    Removed: ~/.config/$name"
    fi
done
for item in "$SRC_DIR"/repo-base/.local/share/*; do
    name="$(basename "$item")"
    if [[ -e "$HOME/.local/share/$name" ]]; then
        rm -rf "$HOME/.local/share/$name"
        echo "    Removed: ~/.local/share/$name"
    fi
done
echo "  [OK]  Old config dirs removed."

# ── Step C: Deploy repo-base configs ─────────────────────────────────────────
echo "  Deploying repo-base configs..."
if [[ -d "$SRC_DIR/repo-base/.config" ]]; then
    cp -r "$SRC_DIR/repo-base/.config/." "$HOME/.config/" 2>/dev/null || true
fi
if [[ -d "$SRC_DIR/repo-base/.local" ]]; then
    mkdir -p "$HOME/.local/share"
    cp -r "$SRC_DIR/repo-base/.local/." "$HOME/.local/" 2>/dev/null || true
fi
echo "  [OK]  repo-base configs deployed."

# ── Step D: Deploy KDE-specific overrides (overwrite repo-base) ───────────────
echo "  Deploying KDE config overrides (src/config → ~/.config)..."
if [[ -d "$SRC_DIR/config" ]]; then
    for item in "$SRC_DIR/config/"*; do
        name="$(basename "$item")"
        if [[ -d "$item" ]]; then
            mkdir -p "$HOME/.config/$name"
            cp -r "$item/." "$HOME/.config/$name/"
        else
            cp "$item" "$HOME/.config/$name"
        fi
        echo "    Deployed override: $name"
    done
fi
echo "  [OK]  KDE overrides deployed."

# ── Step E: Deploy Bridge Files ───────────────────────────────────────────────
echo "  Deploying bridge files (bin, applications, systemd, kwin script)..."
mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.local/share/applications" \
    "$HOME/.config/systemd/user" \
    "$HOME/.local/share/kwin/scripts"

# bin scripts
if [[ -d "$SRC_DIR/bin" ]]; then
    cp "$SRC_DIR/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/hyprctl" \
              "$HOME/.local/bin/hyprpicker" \
              "$HOME/.local/bin/qs-kwin-bridge.py" 2>/dev/null || true
fi

# .desktop files
if [[ -d "$SRC_DIR/keyboardshortcuts/applications" ]]; then
    cp "$SRC_DIR/keyboardshortcuts/applications/"*.desktop \
       "$HOME/.local/share/applications/" 2>/dev/null || true
fi

# systemd user service
if [[ -f "$SRC_DIR/systemd/qs-kwin-bridge.service" ]] && \
   [[ -s "$SRC_DIR/systemd/qs-kwin-bridge.service" ]]; then
    cp "$SRC_DIR/systemd/qs-kwin-bridge.service" \
       "$HOME/.config/systemd/user/"
fi

# KWin script
if [[ -d "$SRC_DIR/kwin/quickshell-kde-bridge" ]]; then
    cp -r "$SRC_DIR/kwin/quickshell-kde-bridge" \
          "$HOME/.local/share/kwin/scripts/"
fi

# Update desktop database
update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
echo "  [OK]  Bridge files deployed."

# ── Step F: Set default wallpaper in quickshell config.json ───────────────────
echo "  Setting default wallpaper for Quickshell..."
DEFAULT_WALLPAPER="$SRC_DIR/config/quickshell/ii/assets/images/default_wallpaper.png"
QS_CONFIG="$HOME/.config/illogical-impulse/config.json"

if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    mkdir -p "$(dirname "$QS_CONFIG")"
    # Use python3 to safely merge JSON
    python3 - "$QS_CONFIG" "$DEFAULT_WALLPAPER" <<'PYEOF'
import json, sys

config_path = sys.argv[1]
wallpaper_path = sys.argv[2]

try:
    with open(config_path, 'r') as f:
        config = json.load(f)
except Exception:
    config = {}

config.setdefault('background', {})['wallpaperPath'] = wallpaper_path
config.setdefault('background', {})['thumbnailPath'] = ''

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"  Wrote wallpaperPath: {wallpaper_path}")
PYEOF
    echo "  [OK]  Quickshell default wallpaper set."
elif [[ ! -f "$DEFAULT_WALLPAPER" ]]; then
    echo "  [WARN] Default wallpaper not found at: $DEFAULT_WALLPAPER"
else
    echo "  [WARN] Quickshell config.json not found (will be created on first run)."
fi

# ── Step G: Set wallpaper for kde-material-you-colors ─────────────────────────
echo "  Setting wallpaper for kde-material-you-colors..."
KMYC_CONFIG="$HOME/.config/kde-material-you-colors/config.conf"

if [[ -f "$DEFAULT_WALLPAPER" ]]; then
    mkdir -p "$(dirname "$KMYC_CONFIG")"
    if [[ -f "$KMYC_CONFIG" ]]; then
        # Update existing config — replace or add light/dark wallpaper paths
        sed -i "s|^light=.*|light=$DEFAULT_WALLPAPER|" "$KMYC_CONFIG" 2>/dev/null || true
        sed -i "s|^dark=.*|dark=$DEFAULT_WALLPAPER|" "$KMYC_CONFIG" 2>/dev/null || true
        # Add keys if they don't exist
        grep -q "^light=" "$KMYC_CONFIG" 2>/dev/null || echo "light=$DEFAULT_WALLPAPER" >> "$KMYC_CONFIG"
        grep -q "^dark="  "$KMYC_CONFIG" 2>/dev/null || echo "dark=$DEFAULT_WALLPAPER" >> "$KMYC_CONFIG"
    else
        # Create minimal config pointing to our wallpaper
        cat > "$KMYC_CONFIG" <<EOF
[General]
light=$DEFAULT_WALLPAPER
dark=$DEFAULT_WALLPAPER
EOF
    fi
    echo "  [OK]  kde-material-you-colors wallpaper configured."
else
    echo "  [SKIP] Default wallpaper missing — skipping kde-material-you-colors setup."
fi

echo "[OK]  Config deployment complete."
