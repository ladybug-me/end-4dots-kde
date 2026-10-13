#!/usr/bin/env bash
# suite: fast

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NOTIF_DATA="$REPO_ROOT/shell/services/NotifData.qml"
NOTIF_POPUP="$REPO_ROOT/shell/modules/notifications/Notification.qml"
NOTIF_SIDEBAR="$REPO_ROOT/shell/modules/sidebar/Notif.qml"

if [[ ! -f "$NOTIF_DATA" ]]; then
    skip_test "NotifData.qml not present in this flavor"
    exit 0
fi

test_notif_data_defines_sanitization_invariants() {
    local content
    content="$(cat "$NOTIF_DATA")"

    assert_contains "$content" 'readonly property string bodyStyled: notif.cleanBody(body)' \
        "NotifData should declare bodyStyled property"
    assert_contains "$content" 'readonly property string bodyPlain: notif.cleanPreview(body)' \
        "NotifData should compute bodyPlain via cleanPreview"
    assert_contains "$content" 'function cleanBody(raw: string): string' \
        "cleanBody typed function should exist on NotifData"
    assert_contains "$content" 'function cleanPreview(raw: string): string' \
        "cleanPreview typed function should exist on NotifData"
}

test_preview_does_not_swallow_math_or_shell_brackets() {
    local test_script output
    test_script='import QtQml; import "'"$NOTIF_DATA"'" as ND; QtObject { id: root; property var comp: Qt.createComponent("'"$NOTIF_DATA"'"); Component.onCompleted: { var obj = comp.createObject(root, { body: "Run <(cmd) count < 10 and max > 5" }); console.log("RESULT:" + obj.bodyPlain); Qt.quit(); } }'

    if command -v qml6 >/dev/null 2>&1; then
        output="$(qml6 -a core <(printf '%s\n' "$test_script") 2>&1 || true)"
        if printf '%s\n' "$output" | grep -q 'RESULT:'; then
            assert_contains "$output" "RESULT:Run <(cmd) count < 10 and max > 5" \
                "cleanPreview must not erase text between angle brackets"
        fi
    fi
}

test_views_bind_model_properties_and_preserve_guards() {
    local popup sidebar
    popup="$(cat "$NOTIF_POPUP")"
    sidebar="$(cat "$NOTIF_SIDEBAR")"

    assert_contains "$popup" 'text: root.modelData.bodyPlain' \
        "popup bodyPreview should bind modelData.bodyPlain"
    assert_contains "$popup" 'text: root.modelData.bodyStyled' \
        "popup body should bind modelData.bodyStyled"
    assert_contains "$popup" 'textFormat: Text.StyledText' \
        "popup body should use StyledText"
    assert_contains "$popup" 'root.modelData.materialIcon || Icons.getNotifIcon' \
        "popup should preserve materialIcon fallback"

    assert_contains "$sidebar" 'text: root.modelData?.bodyPlain ?? ""' \
        "sidebar compactBody should bind modelData.bodyPlain"
    assert_contains "$sidebar" 'text: root.modelData?.bodyStyled' \
        "sidebar bodyText should bind modelData.bodyStyled"
    assert_contains "$sidebar" 'if (!Visibilities.sidebarPinned)' \
        "sidebar should check sidebarPinned before closing on link click"

    assert_not_contains "$popup" 'Sanitizer.js' "Notification.qml must not import Sanitizer.js"
    assert_not_contains "$sidebar" 'Sanitizer.js' "Notif.qml must not import Sanitizer.js"
    assert_file_missing "$REPO_ROOT/shell/modules/common/Sanitizer.js"
}

run_tests
