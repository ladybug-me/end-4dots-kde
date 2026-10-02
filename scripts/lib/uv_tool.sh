#!/usr/bin/env bash
# Helper for managing uv installation and Quickshell Python virtual environment.
if [[ -z "${CAELESTIA_UV_TOOL_SOURCED:-}" ]]; then
CAELESTIA_UV_TOOL_SOURCED=1

# shellcheck source=scripts/lib/log.sh
source "${BUNDLE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/scripts/lib/log.sh" 2>/dev/null || true
# shellcheck source=scripts/lib/privileges.sh
source "${BUNDLE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/scripts/lib/privileges.sh" 2>/dev/null || true
# shellcheck source=scripts/lib/packages.sh
source "${BUNDLE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/scripts/lib/packages.sh" 2>/dev/null || true

uv_present() {
    command -v uv >/dev/null 2>&1
}

install_uv() {
    info "Installing uv..."
    case "${BASE_DISTRO:-unknown}" in
        arch)
            if command -v pacman >/dev/null 2>&1 && caelestia_sudo pacman -S --needed --noconfirm uv 2>/dev/null; then
                ok "uv installed via pacman."
                return 0
            fi
            ;;
        fedora)
            if command -v dnf >/dev/null 2>&1 && caelestia_sudo dnf install -y uv 2>/dev/null; then
                ok "uv installed via dnf."
                return 0
            fi
            ;;
        debian)
            if command -v apt-get >/dev/null 2>&1 && caelestia_sudo apt-get install -y uv 2>/dev/null; then
                ok "uv installed via apt-get."
                return 0
            fi
            ;;
    esac

    if curl -LsSf https://astral.sh/uv/install.sh | sh; then # ci:allow-curl-pipe
        export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
        if uv_present; then
            ok "uv installed via official installer script."
            return 0
        fi
    fi

    err "Failed to install uv."
    return 1
}

ensure_uv() {
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if uv_present; then
        ok "uv is installed."
        return 0
    fi
    install_uv
}

get_uv_venv_dir() {
    printf '%s\n' "${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$HOME/.local/state/quickshell/.venv}"
}

ensure_uv_venv() {
    ensure_uv || return 1

    local venv_dir requirements_file bundle_root
    venv_dir="$(get_uv_venv_dir)"
    bundle_root="${BUNDLE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
    requirements_file="$bundle_root/installer/uv/requirements.txt"

    if [[ ! -f "$requirements_file" ]]; then
        err "Requirements file not found: $requirements_file"
        return 1
    fi

    info "Setting up Python virtual environment at $venv_dir"
    mkdir -p "$(dirname "$venv_dir")"

    if [[ ! -d "$venv_dir" || ! -f "$venv_dir/bin/python" ]]; then
        info "Creating virtual environment..."
        if ! uv venv "$venv_dir" -p 3.12 2>/dev/null; then
            warn "Python 3.12 binary not explicitly found, creating venv with default Python..."
            uv venv "$venv_dir" || {
                err "Failed to create virtual environment with uv."
                return 1
            }
        fi
    fi

    info "Installing locked Python dependencies from requirements.txt..."
    if uv pip install -r "$requirements_file" --python "$venv_dir/bin/python"; then
        ok "Python dependencies installed successfully to $venv_dir"
        return 0
    else
        err "Failed to install Python dependencies via uv."
        return 1
    fi
}

fi
