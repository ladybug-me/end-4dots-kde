#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE="$REPO_ROOT/shell/services/UpdateChecker.qml"
DISCORD="$REPO_ROOT/shell/services/DiscordRPC.qml"
NOTIFS="$REPO_ROOT/shell/services/Notifs.qml"
VPN="$REPO_ROOT/shell/services/VPN.qml"

if [[ ! -f "$UPDATE" && ! -f "$NOTIFS" ]]; then
    skip_test "Upstream services not present in this flavor"
    exit 0
fi

test_the_periodic_update_check_survives_its_first_run() {
    assert_file_contains "$UPDATE" 'repeat: true' \
        "autoCheckTimer must keep firing every interval"
    assert_file_not_contains "$UPDATE" 'autoCheckTimer.restart()' \
        "gitProcess.onExited must not gate the next check on a timer that already fired"
}

test_discord_presence_survives_a_null_active_window() {
    assert_file_contains "$DISCORD" 'Kwin.activeWindow?.class' \
        "presence updates run exactly when the active window disappears"
}

test_a_corrupt_notification_file_does_not_kill_persistence() {
    assert_file_contains "$NOTIFS" 'JSON.parse(text())' "the parse still happens"
    assert_file_contains "$NOTIFS" 'saved notifications are corrupt, starting fresh' \
        "but a corrupt store degrades to a fresh list instead of a dead FileView"
    assert_file_contains "$NOTIFS" 'if (!Array.isArray(data))' \
        "valid but non-array JSON must also degrade to a fresh list"
}

test_vpn_registration_runs_once_per_auth_wall() {
    assert_file_contains "$VPN" 'property bool registerSent: false' \
        "needs-auth must be a transition, not a per-poll event"
    assert_file_contains "$VPN" 'property int statusGen: 0' \
        "and a provider switch must invalidate in-flight status output"
}

run_tests
