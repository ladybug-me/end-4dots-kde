#!/usr/bin/env bash
if [[ -z "${CAELESTIA_INSTALL_KIND_SOURCED:-}" ]]; then
CAELESTIA_INSTALL_KIND_SOURCED=1

install_kind() {
    case "${CAELESTIA_INSTALL_KIND:-}" in
        source | package)
            printf '%s\n' "$CAELESTIA_INSTALL_KIND"
            return 0
            ;;
    esac

    # Where this file was sourced from is the whole answer: a package's copy lives under
    # /usr. An unresolvable directory is reported rather than answered as "source", which
    # is what an empty string would otherwise have quietly meant.
    local lib_dir
    if ! lib_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"; then
        printf '[ERR]   cannot resolve the directory %s was sourced from\n' "${BASH_SOURCE[0]}" >&2
        return 1
    fi

    case "$lib_dir" in
        /usr/*) printf 'package\n' ;;
        *) printf 'source\n' ;;
    esac
}

install_is_packaged() {
    # install_kind reports failure when it cannot tell where it was sourced from, and a
    # failure is not an answer: passing it on keeps the caller from reading "not a
    # package" into a question that was never answered.
    local kind
    kind="$(install_kind)" || return 1
    [[ "$kind" == "package" ]]
}

install_lib_dir() {
    if install_is_packaged; then
        printf '%s\n' /usr/lib/caelestia
    else
        printf '%s\n' "$HOME/.local/lib/caelestia"
    fi
}

install_bin_dir() {
    if install_is_packaged; then
        printf '%s\n' /usr/bin
    else
        printf '%s\n' "$HOME/.local/bin"
    fi
}

install_qml_import_path() {
    if install_is_packaged; then
        printf '%s\n' "/usr/lib/qt6/qml:/etc/xdg/quickshell/caelestia"
    else
        printf '%s\n' "$HOME/.local/lib/qt6/qml:$HOME/.config/quickshell/caelestia"
    fi
}

install_shell_config() {
    if install_is_packaged; then
        printf '%s\n' /etc/xdg/quickshell/caelestia/shell.qml
    else
        printf '%s\n' "$HOME/.config/quickshell/caelestia/shell.qml"
    fi
}

install_assets_dir() {
    printf '%s\n' "$(dirname -- "$(install_shell_config)")/assets"
}

fi
