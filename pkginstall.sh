#!/usr/bin/env bash
# pkginstall.sh — Supplemental package installer for end-4 KDE port.
# Installs fonts, cursors, and Python venv that are not covered by the
# local PKGBUILDs in sdata/arch-dist (installDP.sh handles those).
#
# Idempotent: checks before installing. Failproof: warns on error, continues.

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
CACHE_DIR="${CACHE_DIR:-$REPO_ROOT/cache}"

mkdir -p "$CACHE_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()      { echo; echo "==> $*"; }
warn()     { echo "[WARN] $*" >&2; }
step_ok()  { echo "  [OK]  $*"; }
step_skip(){ echo "  [SKIP] $*"; }

# Try pacman, then yay. Returns 0 on success.
install_pkg() {
    local pkg="$1"
    if sudo pacman -S --needed ${CONFIRM_ARG:-} "$pkg" >/dev/null 2>&1; then
        step_ok "$pkg (pacman)"; return 0
    fi
    if command -v yay >/dev/null 2>&1; then
        if yay -S --needed ${CONFIRM_ARG:-} "$pkg" >/dev/null 2>&1; then
            step_ok "$pkg (AUR)"; return 0
        fi
    fi
    warn "Could not install $pkg — skipping."
    return 1
}

# Clone or update a git repo safely.
clone_or_update() {
    local url="$1" dir="$2"
    if [[ -d "$dir/.git" ]] && git -C "$dir" remote get-url origin >/dev/null 2>&1; then
        git -C "$dir" fetch --all --quiet
        local branch
        branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || echo main)"
        if git -C "$dir" rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
            git -C "$dir" reset --hard "origin/$branch" --quiet
        else
            rm -rf "$dir"; git clone --recursive "$url" "$dir" --quiet
        fi
        git -C "$dir" submodule update --init --recursive --quiet
    else
        rm -rf "$dir"
        git clone --recursive "$url" "$dir" --quiet
    fi
}

# ── Rubik font ────────────────────────────────────────────────────────────────
install_rubik() {
    log "Rubik variable font"
    if fc-list | grep -qi "Rubik"; then
        step_skip "Rubik already installed"; return 0
    fi
    install_pkg ttf-rubik-vf && return 0

    local dir="$CACHE_DIR/Rubik"
    clone_or_update https://github.com/googlefonts/rubik.git "$dir" || { warn "Rubik clone failed"; return 1; }
    sudo install -dm755 /usr/local/share/fonts/TTF
    sudo cp "$dir/fonts/variable/Rubik"*.ttf /usr/local/share/fonts/TTF/ 2>/dev/null || true
    sudo install -dm755 /usr/local/share/licenses/ttf-rubik
    sudo cp "$dir/OFL.txt" /usr/local/share/licenses/ttf-rubik/LICENSE 2>/dev/null || true
    fc-cache -fv >/dev/null 2>&1
    step_ok "Rubik installed from source"
}

# ── Gabarito font ─────────────────────────────────────────────────────────────
install_gabarito() {
    log "Gabarito font"
    if fc-list | grep -qi "Gabarito"; then
        step_skip "Gabarito already installed"; return 0
    fi
    install_pkg ttf-gabarito && return 0

    local dir="$CACHE_DIR/Gabarito"
    clone_or_update https://github.com/naipefoundry/gabarito.git "$dir" || { warn "Gabarito clone failed"; return 1; }
    sudo install -dm755 /usr/local/share/fonts/TTF
    sudo cp "$dir/fonts/ttf/Gabarito"*.ttf /usr/local/share/fonts/TTF/ 2>/dev/null || true
    sudo install -dm755 /usr/local/share/licenses/ttf-gabarito
    sudo cp "$dir/OFL.txt" /usr/local/share/licenses/ttf-gabarito/LICENSE 2>/dev/null || true
    fc-cache -fv >/dev/null 2>&1
    step_ok "Gabarito installed from source"
}

# ── Bibata cursor ─────────────────────────────────────────────────────────────
install_bibata() {
    log "Bibata cursor theme"
    if [ -d "/usr/share/icons/Bibata-Modern-Classic" ] || \
       [ -d "/usr/local/share/icons/Bibata-Modern-Classic" ]; then
        step_skip "Bibata already installed"; return 0
    fi
    install_pkg bibata-cursor-theme && return 0

    local dir="$CACHE_DIR/bibata-cursor"
    local name="Bibata-Modern-Classic"
    local file="${name}.tar.xz"
    mkdir -p "$dir"
    rm -f "$dir/$file" "$dir/$name" 2>/dev/null || true
    if curl -fL --retry 3 -o "$dir/$file" \
        "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/$file"; then
        tar -xf "$dir/$file" -C "$dir"
        sudo install -dm755 /usr/local/share/icons
        sudo rm -rf "/usr/local/share/icons/$name"
        sudo cp -r "$dir/$name" /usr/local/share/icons/
        step_ok "Bibata installed from GitHub release"
    else
        warn "Bibata download failed — skipping cursor theme"
    fi
}


# ── Python venv ───────────────────────────────────────────────────────────────
install_python_packages() {
    log "Python packages (uv venv)"
    local venv="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"

    if ! command -v uv >/dev/null 2>&1; then
        warn "'uv' not found. Install it first (it should be in the PKGBUILD deps)."
        return 1
    fi

    uv venv "$venv" -p python3 --quiet

    # shellcheck disable=SC1091
    source "$venv/bin/activate"

    if [[ -f "$REPO_ROOT/sdata/uv/requirements.txt" ]]; then
        uv pip install -r "$REPO_ROOT/sdata/uv/requirements.txt" --quiet
        step_ok "Python packages installed into $venv"
    else
        warn "No requirements.txt found at sdata/uv/requirements.txt"
    fi

    deactivate
}

# ── Polonium ──────────────────────────────────────────────────────────────────
install_polonium() {
    if [[ "${POLONIUM_ENABLED:-false}" == "true" ]]; then
        log "Polonium tiling WM plugin"
        
        if [ -d "$HOME/.local/share/kwin/scripts/polonium" ] || \
           [ -d "/usr/share/kwin/scripts/polonium" ]; then
            step_skip "Polonium already installed"
            return 0
        fi

        if install_pkg kwin-polonium; then
            return 0
        fi
        
        warn "kwin-polonium AUR package failed — falling back to GitHub release"
        local file="$CACHE_DIR/polonium.kwinscript"
        local url="https://github.com/zeroxoneafour/polonium/releases/latest/download/polonium.kwinscript"
        
        if curl -fL --retry 3 -o "$file" "$url"; then
            kpackagetool6 --type=KWin/Script -i "$file" 2>/dev/null || \
            kpackagetool6 --type=KWin/Script -u "$file" >/dev/null 2>&1
            step_ok "Polonium installed from GitHub release"
        else
            warn "Polonium download failed — skipping"
        fi
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    install_rubik    || true
    install_gabarito || true
    install_bibata   || true

    install_python_packages || true
    install_polonium        || true

    echo
    echo "Supplemental packages step complete."
}

main "$@"
