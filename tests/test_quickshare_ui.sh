#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_DIR="$REPO_ROOT/shell"
SWITCH="$SHELL_DIR/services/QuickShare.qml"
SETUP="$SHELL_DIR/services/QuickShareSetup.qml"
PAGE="$SHELL_DIR/modules/nexus/pages/services/QuickSharePage.qml"
CARD="$SHELL_DIR/modules/utilities/cards/Toggles.qml"

if [[ ! -f "$PAGE" ]]; then
    skip_test "QuickSharePage.qml not present in this flavor"
    exit 0
fi

test_the_switch_state_has_one_home() {
    local file
    for file in "$CARD" "$PAGE"; do
        assert_contains "$(cat "$file")" "QuickShare.enabled" \
            "$(basename "$file") should read the switch state from the service"
    done

    local derived
    derived="$(grep -rn 'QuickShareService.isEnabled ||' "$SHELL_DIR/modules" --include='*.qml' || true)"
    assert_eq "" "$derived" "no view should re-derive whether Quick Share is on"
}

test_the_switch_is_asked_for_in_one_way() {
    local callers
    callers="$(grep -rn 'QuickShare\.\(toggle\|setEnabled\)' "$SHELL_DIR/modules" --include='*.qml' || true)"

    assert_not_contains "$callers" "QuickShare.toggle" \
        "the switch should have one way in, rather than a second entry point that reads the service"
    assert_contains "$callers" "QuickShare.setEnabled" \
        "and it should be the one the gate lives behind"
}

test_the_system_access_flow_has_one_owner() {
    assert_file_exists "$SETUP"

    local borrowed
    borrowed="$(grep -n 'shellPath\|--status\|SETUP=\|pkexec' "$SWITCH" || true)"
    assert_eq "" "$borrowed" "the prompt service should not own the system check"

    assert_contains "$(cat "$SETUP")" 'Quickshell.shellPath("scripts/quickshare_setup.sh")' \
        "the setup service should be the one that runs the helper"
    assert_contains "$(cat "$PAGE")" "QuickShareSetup.status" \
        "and the row should report what that service found"
    assert_contains "$(cat "$PAGE")" "QuickShareSetup.run()" \
        "with the row itself as the way to ask for it by hand"
}

run_tests
