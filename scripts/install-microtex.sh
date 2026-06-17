#!/usr/bin/env bash
# install-microtex.sh — Build and install MicroTeX from source with compatibility fixes.

set -euo pipefail

# Find BUNDLE_DIR if not set
if [[ -z "${BUNDLE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BUNDLE_DIR="$(dirname "$SCRIPT_DIR")"
fi

CACHE_DIR="${CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-installer}"
mkdir -p "$CACHE_DIR"

# Import helper functions if available
if [[ -f "$BUNDLE_DIR/pkginstall.sh" ]]; then
    # We just need log and warn and step_skip from pkginstall, but it executes code on source.
    # So we'll define our own minimal ones.
    true
fi

log() { echo -e "\n\033[1;34m==>\033[0m \033[1m$1\033[0m"; }
warn() { echo -e "\033[0;31m[WARN]\033[0m $1" >&2; }
step_ok() { echo -e "  \033[1;32m[OK]\033[0m  $1"; }
step_skip() { echo -e "  \033[1;30m[SKIP]\033[0m $1"; }

clone_or_update() {
    local repo="$1"
    local dest="$2"
    if [[ -d "$dest/.git" ]]; then
        git -C "$dest" pull --rebase || true
    else
        git clone "$repo" "$dest"
    fi
}

log "MicroTeX"

if [[ -x /opt/MicroTeX/LaTeX ]] || command -v LaTeX >/dev/null 2>&1 || command -v microtex >/dev/null 2>&1; then
    step_skip "MicroTeX already installed"
    exit 0
fi

# Check if installed via PKGBUILD/RPM already
if [[ "$BASE_DISTRO" == "arch" ]]; then
    if pacman -Qi illogical-impulse-microtex-git >/dev/null 2>&1 || pacman -Qi microtex-git >/dev/null 2>&1; then
        step_skip "MicroTeX installed via PKGBUILD"
        exit 0
    fi
elif [[ "$BASE_DISTRO" == "fedora" ]]; then
    if dnf list --installed illogical-impulse-microtex-git >/dev/null 2>&1 || dnf list --installed microtex-git >/dev/null 2>&1 || dnf list --installed microtex >/dev/null 2>&1; then
        step_skip "MicroTeX installed via RPM"
        exit 0
    fi
fi

dir="$CACHE_DIR/MicroTeX"
clone_or_update https://github.com/NanoMichael/MicroTeX.git "$dir" || {
    warn "MicroTeX clone failed — skipping"
    exit 1
}

(
    set -euo pipefail
    cd "$dir"

    # GTKSourceView4 compatibility
    find . -type f \( -name "CMakeLists.txt" -o -name "*.cmake" -o -name "meson.build" \) \
        -exec sed -i 's/gtksourceviewmm-3.0/gtksourceviewmm-4.0/g' {} + 2>/dev/null || true

    # Fontconfig fcfreetype.h fix (missing include in upstream)
    if ! grep -q 'fontconfig/fcfreetype.h' \
        "$dir/src/platform/cairo/graphic_cairo.cpp" 2>/dev/null; then
        sed -i '/fontconfig\/fontconfig.h/a #include <fontconfig\/fcfreetype.h>' \
            "$dir/src/platform/cairo/graphic_cairo.cpp" 2>/dev/null || true
    fi

    rm -rf build; mkdir build; cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/MicroTeX
    make -j"$(nproc)"

    [[ -f LaTeX ]] || { echo "MicroTeX build failed — LaTeX binary not found"; exit 1; }
    
    sudo install -dm755 /opt/MicroTeX
    sudo cp LaTeX /opt/MicroTeX/
    [[ -d ../res ]] && sudo cp -r ../res /opt/MicroTeX/
) && step_ok "MicroTeX built and installed" || {
    warn "MicroTeX build failed — skipping"
    exit 1
}
