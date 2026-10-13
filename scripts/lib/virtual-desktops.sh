#!/usr/bin/env bash
if [[ -z "${CAELESTIA_VIRTUAL_DESKTOPS_SOURCED:-}" ]]; then
CAELESTIA_VIRTUAL_DESKTOPS_SOURCED=1

ensure_five_virtual_desktops() {
    if [[ "${CAELESTIA_FRESH_INSTALL:-0}" != "1" ]]; then
        skip "Not an install - leaving the virtual desktops alone."
        return 0
    fi

    local number
    number="$(kreadconfig6 --file kwinrc --group "Desktops" --key "Number" 2>/dev/null || true)"

    if [[ -n "$number" && "$number" != "1" ]]; then
        skip "Keeping the existing $number virtual desktops."
        return 0
    fi

    info "Configuring 5 virtual desktops..."
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Number" "5"
    kwriteconfig6 --file kwinrc --group "Desktops" --key "Rows" "1"
    for i in $(seq 1 5); do
        kwriteconfig6 --file kwinrc --group "Desktops" --key "Name_$i" "Desktop $i"
    done
    ok "5 virtual desktops configured."
}

fi
