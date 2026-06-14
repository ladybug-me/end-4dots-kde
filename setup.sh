#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║        end-4 KDE Port — Unified Installer                   ║
# ║                                                              ║
# ║  Original Hyprland dots: end-4                               ║
# ║  KDE port & modifications: ladybug-me                        ║
# ║                                                              ║
# ║  Idempotent — safe to run multiple times.                    ║
# ╚══════════════════════════════════════════════════════════════╝

set -uo pipefail

# ── Paths ──────────────────────────────────────────────────────────────────────
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$BUNDLE_DIR/scripts"
export BUNDLE_DIR

# ── Download/Cache Configuration ───────────────────────────────────────────────
export CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/end4-kde"
export BUILDDIR="$CACHE_DIR/makepkg-build"
export PKGDEST="$CACHE_DIR/makepkg-packages"
export SRCDEST="$CACHE_DIR/makepkg-sources"
export SRCPKGDEST="$CACHE_DIR/makepkg-srcpackages"

# Ensure cache subdirectories exist
mkdir -p "$CACHE_DIR" "$BUILDDIR" "$PKGDEST" "$SRCDEST" "$SRCPKGDEST"

# ── Colors ─────────────────────────────────────────────────────────────────────
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"
CYAN="\033[0;36m"; RST="\033[0m"

die()  { echo -e "${RED}[FATAL] $*${RST}" >&2; exit 1; }
info() { echo -e "${CYAN}[INFO]  $*${RST}"; }
ok()   { echo -e "${GREEN}[OK]    $*${RST}"; }
warn() { echo -e "${YELLOW}[WARN]  $*${RST}"; }

# ── Pre-flight checks ──────────────────────────────────────────────────────────
if ! command -v pacman >/dev/null 2>&1; then
    die "pacman not found. This installer requires Arch Linux or an Arch-based distro."
fi

# ── Step runner ────────────────────────────────────────────────────────────────
# Runs a step script. On failure prints a warning and prompts for retry/ignore/exit.
run_step() {
    local name="$1" script="$2"
    while true; do
        echo
        info "Running: $name"
        if bash "$script"; then
            ok "$name — done"
            break
        else
            warn "$name — encountered errors"
            echo -e "${YELLOW}What would you like to do? [r]etry, [i]gnore, [e]xit:${RST} "
            read -r -t 60 step_action || step_action="i"
            case "${step_action,,}" in
                r|retry)
                    info "Retrying $name..."
                    ;;
                e|exit)
                    die "Aborting installation."
                    ;;
                *)
                    info "Ignoring error and continuing..."
                    break
                    ;;
            esac
        fi
    done
}

# ══════════════════════════════════════════════════════════════
#  BANNER
# ══════════════════════════════════════════════════════════════
bash "$SCRIPTS_DIR/00-banner.sh"

# ══════════════════════════════════════════════════════════════
#  ONE-TIME SUDO PASSWORD (kept alive for the full install)
# ══════════════════════════════════════════════════════════════
echo -e "${YELLOW}This installer needs sudo for package installation.${RST}"
read -s -p "Please enter your sudo password: " SUDO_PASS
echo
export SUDO_PASS

# Temporarily grant NOPASSWD to the user to prevent yay/makepkg from prompting
echo "$SUDO_PASS" | sudo -S sh -c "echo '$USER ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/end4-installer-temp"
sudo -S chmod 0440 /etc/sudoers.d/end4-installer-temp

trap 'echo "$SUDO_PASS" | sudo -S rm -f /etc/sudoers.d/end4-installer-temp 2>/dev/null' EXIT

# ══════════════════════════════════════════════════════════════
#  STEP 0 — System update (first thing after auth)
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 0 — System Update (pacman -Syu)${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo
info "Running sudo pacman -Syu to bring the system up to date first..."
if sudo pacman -Syu --noconfirm; then
    ok "System is up to date."
else
    warn "pacman -Syu encountered errors. Continuing anyway..."
fi

# ══════════════════════════════════════════════════════════════
#  ASK USER PREFERENCES
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Installer preferences${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"

# Polonium tiling WM — ask user
echo
echo -e "${YELLOW}Polonium is a KDE tiling window manager plugin.${RST}"
echo -e "Would you like to enable Polonium tiling? [y/N]: "
read -r -t 15 polonium_answer || polonium_answer="n"
case "${polonium_answer,,}" in
    y|yes) export POLONIUM_ENABLED="true";  echo "  → Polonium will be ENABLED." ;;
    *)     export POLONIUM_ENABLED="false"; echo "  → Polonium will be DISABLED (default)." ;;
esac

# Auto-confirm package installation — ask user
echo
echo -e "${YELLOW}Would you like package installation to proceed automatically without confirmation?${RST}"
echo -e "If you select No, you will be prompted to confirm each pacman/yay transaction. [Y/n]: "
read -r -t 15 confirm_answer || confirm_answer="y"
case "${confirm_answer,,}" in
    n|no) export CONFIRM_ARG="";            echo "  → Manual confirmation ENABLED." ;;
    *)    export CONFIRM_ARG="--noconfirm"; echo "  → Automated installation ENABLED (--noconfirm)." ;;
esac

# Clean up downloaded package cache and build files — ask user
echo
echo -e "${YELLOW}Would you like to remove the downloaded packages and build files after a successful installation? [y/N]:${RST} "
read -r -t 15 clean_answer || clean_answer="n"
case "${clean_answer,,}" in
    y|yes) export REMOVE_CACHE="true";  echo "  → Downloaded packages/cache will be REMOVED." ;;
    *)     export REMOVE_CACHE="false"; echo "  → Downloaded packages/cache will be KEPT (default)." ;;
esac


# ══════════════════════════════════════════════════════════════
#  STEP 1 — Ensure yay is installed
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 1/9 — AUR Helper (yay)${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "Ensure yay" "$SCRIPTS_DIR/01-ensure-yay.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 2 — Install KDE extra apps (kvantum, darkly, kde-material-you-colors)
#           Done BEFORE packages so theming is available
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 2/9 — KDE Theme Apps${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "KDE theme apps" "$SCRIPTS_DIR/08-kde-apps.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 3 — Packages (PKGBUILDs + supplemental)
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 3/9 — Package Installation${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "Package installation" "$SCRIPTS_DIR/02-packages.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 4 — Deploy configs
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 4/9 — Config Deployment${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "Config deployment" "$SCRIPTS_DIR/03-deploy-configs.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 5 — Apply KDE settings (Darkly, Kvantum, polonium)
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 5/9 — KDE Settings${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "KDE settings" "$SCRIPTS_DIR/04-deploy-kde.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 6 — Keyboard shortcuts & workspaces
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 6/9 — Keyboard Shortcuts & Workspaces${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "Keyboard shortcuts" "$BUNDLE_DIR/src/keyboardshortcuts/register.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 7 — Autostart (Quickshell + kde-material-you-colors)
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 7/9 — Autostart${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "Autostart" "$SCRIPTS_DIR/06-autostart.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 8 — Enable services & reload KWin
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 8/9 — Services${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "Services" "$SCRIPTS_DIR/07-services.sh"

# ══════════════════════════════════════════════════════════════
#  STEP 8.5 — Apply live system tweaks
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 8.5/9 — System Tweaks${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "System tweaks" "$SCRIPTS_DIR/10-system-tweaks.sh"

# ══════════════════════════════════════════════════════════════
#  CLEANUP CACHE
# ══════════════════════════════════════════════════════════════
if [[ "${REMOVE_CACHE:-}" == "true" ]]; then
    echo
    info "Cleaning up downloaded packages and build files..."
    rm -rf "$CACHE_DIR"
    ok "Downloaded packages and build files removed."
fi

# ══════════════════════════════════════════════════════════════
#  STEP 9 — Finalize (summary + logout instructions)
# ══════════════════════════════════════════════════════════════
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${CYAN}  Step 9/9 — Finalize${RST}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
run_step "Finalize" "$SCRIPTS_DIR/09-finalize.sh"
