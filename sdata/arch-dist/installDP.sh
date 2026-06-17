#!/usr/bin/env bash
# installDP.sh — Install illogical-impulse local PKGBUILDs for the end-4 KDE port.
# Idempotent: skips packages already installed. Failproof: continues on error.

set -uo pipefail

# Keep sudo alive for this script to prevent password prompts during makepkg
sudo -v || exit 1
(while true; do sudo -n true; sleep 55; done) 2>/dev/null &
SUDO_LOOP_PID=$!
trap 'kill $SUDO_LOOP_PID 2>/dev/null || true' EXIT

# ── Resolve paths relative to this script, not the caller's CWD ──────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"   # local sdata/arch-dist directory

# ── Package list ─────────────────────────────────────────────────────────────
# illogical-impulse-hyprland is excluded by default for KDE port (no hyprland).
# Quickshell is installed via illogical-impulse-quickshell-git (git/pinned build),
# which conflicts with the plain 'quickshell' package — only one is installed.
PACKAGES=(
    illogical-impulse-audio
    illogical-impulse-backlight
    illogical-impulse-basic
    illogical-impulse-fonts-themes
    illogical-impulse-kde
    illogical-impulse-portal
    illogical-impulse-python
    illogical-impulse-screencapture
    illogical-impulse-toolkit
    illogical-impulse-widgets
    illogical-impulse-quickshell-git
    illogical-impulse-bibata-modern-classic-bin
)

PROTECTED=(
    systemd glibc linux linux-lts linux-zen linux-hardened linux-headers
    pipewire wireplumber mesa pacman bash sudo xdg-desktop-portal
)

# ── Counters ─────────────────────────────────────────────────────────────────
INSTALLED=0
SKIPPED=0
FAILED=0
FAILED_PKGS=()

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo; echo "==> $*"; }
warn() { echo -e "\033[0;31m[WARN] $*\033[0m" >&2; }
err()  { echo -e "\033[0;31m[ERR]  $*\033[0m" >&2; }

is_protected() {
    local pkg="$1"
    for p in "${PROTECTED[@]}"; do
        [[ "$pkg" == "$p" ]] && return 0
    done
    return 1
}

is_installed() {
    # Check both the exact name and any provides alias
    pacman -Qi "$1" >/dev/null 2>&1
}

ensure_yay() {
    if command -v yay >/dev/null 2>&1; then return; fi
    log "yay not found — installing..."
    sudo pacman -S --needed ${CONFIRM_ARG:-} base-devel git
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir"
    (
        cd "$tmpdir"
        makepkg -si ${CONFIRM_ARG:-}
    )
    rm -rf "$tmpdir"
}

remove_conflicts() {
    # $1 = PKGBUILD directory (already sourced)
    if ! declare -p conflicts >/dev/null 2>&1; then return; fi
    for conflict in "${conflicts[@]}"; do
        # Strip version constraints
        conflict="${conflict%%>=*}"; conflict="${conflict%%<=*}"
        conflict="${conflict%%>*}";  conflict="${conflict%%<*}"
        conflict="${conflict%%=*}"
        [[ -z "$conflict" ]] && continue
        if pacman -Q "$conflict" >/dev/null 2>&1; then
            if is_protected "$conflict"; then
                warn "Skipping protected conflicting package: $conflict"
                continue
            fi
            log "Removing conflicting package: $conflict"
            sudo pacman -Rdd ${CONFIRM_ARG:-} "$conflict" || true
        fi
    done
}

install_dependencies() {
    local deps=()
    declare -p depends    >/dev/null 2>&1 && deps+=("${depends[@]}")
    declare -p makedepends >/dev/null 2>&1 && deps+=("${makedepends[@]}")
    if (( ${#deps[@]} )); then
        log "Installing dependencies for $pkgname..."
        yay -S --needed ${CONFIRM_ARG:-} --asdeps "${deps[@]}" || true
    fi
}

install_pkgbuild() {
    local dir="$1"
    local name
    name="$(basename "$dir")"

    echo
    echo "=================================================="
    echo "Processing: $name"
    echo "=================================================="

    if [[ ! -d "$dir" ]]; then
        warn "Directory not found: $dir — skipping."
        (( SKIPPED++ )) || true
        return
    fi

    if [[ ! -f "$dir/PKGBUILD" ]]; then
        warn "No PKGBUILD in $dir — skipping."
        (( SKIPPED++ )) || true
        return
    fi

    # Source PKGBUILD in a subshell to extract pkgname without polluting env
    local resolved_pkgname
    resolved_pkgname="$(
        unset pkgname depends makedepends conflicts provides replaces
        # shellcheck disable=SC1091
        source "$dir/PKGBUILD" 2>/dev/null
        echo "${pkgname:-$name}"
    )"

    # Idempotency: skip if already installed
    if is_installed "$resolved_pkgname"; then
        echo "  [SKIP] $resolved_pkgname is already installed."
        (( SKIPPED++ )) || true
        return
    fi

    # Install in a subshell so failures don't abort the outer loop
    while true; do
        if (
            set -euo pipefail
            cd "$dir"
            unset pkgname depends makedepends conflicts provides replaces
            # shellcheck disable=SC1091
            source ./PKGBUILD
            install_dependencies
            remove_conflicts
            makepkg -Afsi ${CONFIRM_ARG:-} 2>&1
            
        ); then
            echo "  [OK]  $resolved_pkgname installed successfully."
            (( INSTALLED++ )) || true
            break
        else
            err "$resolved_pkgname installation FAILED."
            echo -e "\033[1;33mWhat would you like to do? [r]etry, [i]gnore, [e]xit:\033[0m "
            read -r -t 60 step_action || step_action="i"
            case "${step_action,,}" in
                r|retry)
                    echo "Retrying $resolved_pkgname..."
                    ;;
                e|exit)
                    err "Aborting installation."
                    exit 1
                    ;;
                *)
                    echo "Ignoring error and continuing with remaining packages..."
                    (( FAILED++ )) || true
                    FAILED_PKGS+=("$resolved_pkgname")
                    break
                    ;;
            esac
        fi
    done
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    if ! command -v pacman >/dev/null 2>&1; then
        err "pacman not found. This script requires Arch Linux or an Arch-based distro."
        exit 1
    fi

    ensure_yay

    log "Syncing package databases..."
    sudo pacman -Syu ${CONFIRM_ARG:-} || true

    for pkg in "${PACKAGES[@]}"; do
        install_pkgbuild "$BASE_DIR/$pkg"
    done

    echo
    echo "======================================================"
    echo "  Installation summary"
    echo "======================================================"
    echo "  Installed : $INSTALLED"
    echo "  Skipped   : $SKIPPED (already present)"
    echo "  Failed    : $FAILED"
    if (( ${#FAILED_PKGS[@]} )); then
        echo
        echo "  Failed packages:"
        for p in "${FAILED_PKGS[@]}"; do
            echo "    - $p"
        done
        echo
        echo "  Re-run this script to retry failed packages."
    fi
    echo "======================================================"
}

main "$@"
