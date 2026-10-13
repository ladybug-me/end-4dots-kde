#!/usr/bin/env bash
# suite: fast

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$REPO_ROOT/scripts/lib/virtual-desktops.sh"
LOG_LIB="$REPO_ROOT/scripts/lib/log.sh"

RUN_CALLS=""
RUN_OUTPUT=""

run_ensure() {
    local number="$1" fresh="$2" dir body
    dir="$(new_tmpdir)"
    mkdir -p "$dir/bin"
    stub_bin "$dir/bin" kreadconfig6 "printf '%s\n' '$number'"
    recording_stub "$dir/bin" kwriteconfig6 "$dir/calls"

    body="source '$LOG_LIB'
source '$LIB'
ensure_five_virtual_desktops"

    RUN_CALLS="$dir/calls"
    if [[ "$fresh" == "1" ]]; then
        RUN_OUTPUT="$(env "PATH=$dir/bin:$PATH" CAELESTIA_FRESH_INSTALL=1 bash -c "$body" 2>&1)"
    else
        RUN_OUTPUT="$(env -u CAELESTIA_FRESH_INSTALL "PATH=$dir/bin:$PATH" bash -c "$body" 2>&1)"
    fi
}

written() {
    calls_to "$RUN_CALLS" kwriteconfig6
}

test_a_fresh_install_with_no_count_gets_five() {
    run_ensure "" 1

    assert_contains "$(written)" "--file kwinrc --group Desktops --key Rows 1" \
        "the desktops should be laid out in one row"
    assert_contains "$(written)" "--file kwinrc --group Desktops --key Number 5" \
        "a system that never set a desktop count should be given five"
    assert_contains "$(written)" "--file kwinrc --group Desktops --key Name_5 Desktop 5" \
        "every desktop should be named"
}

test_a_fresh_install_at_kwins_default_of_one_gets_five() {
    run_ensure "1" 1

    assert_contains "$(written)" "--file kwinrc --group Desktops --key Number 5" \
        "kwinrc carrying KWin's own default of one desktop is not a user's configuration"
    assert_contains "$(written)" "--file kwinrc --group Desktops --key Name_1 Desktop 1" \
        "the desktops should be named"
}

test_a_fresh_install_keeps_a_count_the_user_chose() {
    run_ensure "3" 1

    assert_eq "" "$(written)" "the desktops a user configured should be left alone"
    assert_contains "$RUN_OUTPUT" "Keeping the existing 3 virtual desktops." \
        "the step should report why it stood down"
}

test_a_fresh_install_already_at_five_is_not_rewritten() {
    run_ensure "5" 1

    assert_eq "" "$(written)" "a configured count needs no rewrite"
}

test_an_update_at_kwins_default_of_one_changes_nothing() {
    run_ensure "1" ""

    assert_eq "" "$(written)" "an update must not touch the desktop count"
    assert_contains "$RUN_OUTPUT" "Not an install" "the step should report that it stood down"
}

test_an_update_without_the_flag_changes_nothing() {
    run_ensure "" ""

    assert_eq "" "$(written)" "an update must not be read as an install"
}

test_both_step_scripts_apply_the_helper() {
    local script content
    for script in 06-services.sh 09-system-tweaks.sh; do
        content="$(cat "$REPO_ROOT/scripts/$script")"
        assert_contains "$content" "lib/virtual-desktops.sh" "$script should source the helper"
        assert_contains "$content" "ensure_five_virtual_desktops" "$script should apply the helper"
    done
}

test_the_install_entries_mark_the_run_and_the_update_does_not() {
    assert_contains "$(cat "$REPO_ROOT/installer/tui/Runner.cpp")" \
        'setenv("CAELESTIA_FRESH_INSTALL", "1", 1);' \
        "the TUI installer should mark the run it runs the steps for"
    assert_contains "$(cat "$REPO_ROOT/src/bin/caelestia")" \
        'CAELESTIA_FRESH_INSTALL="${CAELESTIA_FRESH_INSTALL:-1}"' \
        "a packaged install should mark the run"
    assert_contains "$(cat "$REPO_ROOT/src/bin/caelestia-update")" \
        'CAELESTIA_FRESH_INSTALL=0' \
        "the updater re-applying a packaged install must not mark it"
}

run_tests
