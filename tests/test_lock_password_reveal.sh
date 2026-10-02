#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PILL="$REPO_ROOT/src/kde/shells/caelestia.desktop/contents/lockscreen/components/PasswordPill.qml"

# The greeter is a Plasma shell package of our own, not the upstream Quickshell lock
# module, so nothing upstream can restore this feature for us: the reveal toggle exists
# here and only here, and these assertions are what keeps it from being dropped.
test_the_reveal_starts_hidden() {
    local qml
    qml="$(cat "$PILL")"

    assert_contains "$qml" 'property bool showPassword: false' "the pill should start without the password revealed"
}

test_typing_replaces_the_shapes_with_the_password() {
    local qml
    qml="$(cat "$PILL")"

    assert_contains "$qml" 'visible: !root.showPassword' "the shape list should hide while the password is shown"
    assert_contains "$qml" 'text: root.showPassword ? passwordBox.text : ""' "the plain text should only carry the password while revealed"
}

test_the_leading_icon_toggles_the_reveal() {
    local qml
    qml="$(cat "$PILL")"

    assert_contains "$qml" '"visibility"' "the icon should show the visibility glyph while revealed"
    assert_contains "$qml" 'onClicked: if (root.canReveal) root.showPassword = !root.showPassword' "the icon should toggle the reveal"
    assert_contains "$qml" 'readonly property bool canReveal: !root.graceLocked && !root.isAuthenticating' "the reveal should be closed while an attempt is in flight"
}

test_the_reveal_clears_with_the_password() {
    local qml
    qml="$(cat "$PILL")"

    assert_eq "1" "$(printf '%s\n' "$qml" | grep -c 'if (text.length === 0) root.showPassword = false;')" "emptying the field should close the reveal"
    assert_eq "1" "$(printf '%s\n' "$qml" | grep -c '^        root.showPassword = false;$')" "clearing the password should close the reveal"
}

run_tests
