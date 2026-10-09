#!/usr/bin/env bash

MATUGEN_HELPER=""
for candidate in \
    "${CAELESTIA_DATA_DIR:-}/scripts/lib/matugen.sh" \
    "${CAELESTIA_LIB_DIR:-}/scripts/lib/matugen.sh" \
    "$HOME/.local/lib/caelestia/scripts/lib/matugen.sh" \
    "/usr/share/caelestia/scripts/lib/matugen.sh" \
    "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2>/dev/null && pwd)/scripts/lib/matugen.sh"; do
    if [[ -f "$candidate" ]]; then
        MATUGEN_HELPER="$candidate"
        break
    fi
done

if [[ -n "$MATUGEN_HELPER" ]]; then
    if [[ -f "/usr/local/bin/matugen" && ! -L "/usr/local/bin/matugen" ]] || [[ -f "$HOME/.cargo/bin/matugen" ]]; then
        notify-send "Caelestia" "Requesting permission to remove older matugen..." -i dialog-password 2>/dev/null || true
    fi

    # shellcheck source=scripts/lib/matugen.sh
    source "$MATUGEN_HELPER"
    if ensure_matugen; then
        echo "StartupTasks: Ensured matugen"
        exit 0
    fi
fi

exit 0
