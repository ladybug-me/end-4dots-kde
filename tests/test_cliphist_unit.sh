#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KDE_SCRIPT="$REPO_ROOT/scripts/04-deploy-kde.sh"

SERVICE_SOURCE="$(extract_function "$KDE_SCRIPT" write_cliphist_service)"

if [[ -z "$SERVICE_SOURCE" ]]; then
    fail "could not find write_cliphist_service in scripts/04-deploy-kde.sh"
    run_tests
    exit 1
fi

LOG_STUBS='
ok() { :; }
info() { :; }
warn() { :; }
skip() { :; }
'

write_service() {
    local home="$1"
    HOME="$home" bash -c "${LOG_STUBS}${SERVICE_SOURCE}
write_cliphist_service" 2>&1
}

unit_path() {
    printf '%s\n' "$1/.config/systemd/user/cliphist.service"
}

runner_path() {
    printf '%s\n' "$1/.local/bin/caelestia-cliphist"
}

start_service() {
    local home="$1" stub_dir="$2"
    HOME="$home" PATH="$stub_dir" "$(runner_path "$home")" >"$home/runner.log" 2>&1
    printf '%s\n' "$?"
}

stub_helpers() {
    local root="$1"
    recording_stub "$root/bin" wl-paste "$root/watchers.log"
    stub_bin "$root/bin" cliphist 'exit 0'
    stub_bin "$root/bin" wl-clip-persist "printf '%s\n' \"\$@\" > '$root/persister-argv.txt'"
}

have_python() {
    if command -v python3 >/dev/null 2>&1; then
        return 0
    fi
    skip_test "python3 not installed"
    return 1
}

filter_verdicts() {
    local filter="$1"
    shift
    python3 - "$filter" "$@" <<'PYEOF'
import re
import sys

pattern, pairs = sys.argv[1], sys.argv[2:]
try:
    regex = re.compile(pattern)
except re.error as err:
    print(f"the filter is not a regex a regex engine can compile: {err}")
    sys.exit(1)

wrong = []
for pair in pairs:
    wanted, mime = pair.split("=", 1)
    matches = "yes" if regex.match(mime) else "no"
    if matches != wanted:
        wrong.append(f"{mime} (wanted {wanted}, got {matches})")
if wrong:
    print("filter verdict wrong for: " + ", ".join(wrong))
    sys.exit(1)
PYEOF
}

test_the_unit_runs_the_runner_the_step_installs() {
    local home unit runner
    home="$(new_tmpdir)"
    write_service "$home" >/dev/null
    unit="$(cat "$(unit_path "$home")")"
    runner="$(runner_path "$home")"

    assert_contains "$unit" 'ExecStart=%h/.local/bin/caelestia-cliphist' "the unit should run the installed runner"
    assert_contains "$unit" 'Restart=always' "which it recovers from"
    assert_contains "$unit" 'WantedBy=default.target' "and which is still wanted by the default target"
    assert_not_contains "$unit" 'wl-paste' "the pipeline should live in the runner, not in the unit"
    assert_file_exists "$runner"
}

test_the_runner_starts_both_watchers_and_the_persister() {
    local home root status
    root="$(new_tmpdir)"
    home="$root/home"
    mkdir -p "$home"
    write_service "$home" >/dev/null
    stub_helpers "$root"

    status="$(start_service "$home" "$root/bin")"

    assert_status 0 "$status" "a runner whose helpers are all installed should exit cleanly"
    assert_eq "--type image --watch cliphist store
--type text --watch cliphist store" \
        "$(calls_to "$root/watchers.log" wl-paste | sort)" \
        "both clipboard watchers should keep feeding cliphist"
    assert_eq "--clipboard" "$(sed -n 1p "$root/persister-argv.txt")" \
        "the persister should still take over the regular clipboard"
}

test_a_missing_helper_is_reported() {
    local home root status
    root="$(new_tmpdir)"
    home="$root/home"
    mkdir -p "$home"
    write_service "$home" >/dev/null
    stub_helpers "$root"
    rm -f "$root/bin/wl-clip-persist"

    status="$(start_service "$home" "$root/bin")"

    assert_status 1 "$status" "the unit should fail rather than run half a clipboard stack"
    assert_contains "$(cat "$home/runner.log")" 'missing: wl-clip-persist' \
        "the journal should name the helper that is missing"
}

test_the_private_formats_are_left_to_their_owner() {
    have_python || return 0

    local home root filter output status
    root="$(new_tmpdir)"
    home="$root/home"
    mkdir -p "$home"
    write_service "$home" >/dev/null
    stub_helpers "$root"
    start_service "$home" "$root/bin" >/dev/null

    assert_eq "--all-mime-type-regex" "$(sed -n 3p "$root/persister-argv.txt")" \
        "the persister should still be told which selection events to leave alone"
    assert_eq "4" "$(grep -c '' "$root/persister-argv.txt")" \
        "the filter should reach the tool as one argument, not as words the shell split"

    filter="$(sed -n 4p "$root/persister-argv.txt")"
    assert_ne "" "$filter" "the filter should not be empty"

    output="$(filter_verdicts "$filter" \
        "no=application/x-krita-node-internal-pointer" \
        "no=application/x-krita-krita-node-data" \
        "no=image/x-inkscape-svg" \
        "yes=text/plain" \
        "yes=text/plain;charset=utf-8" \
        "yes=UTF8_STRING" \
        "yes=image/png" \
        "yes=application/zip")"
    status=$?

    assert_status 0 "$status" "the filter should skip only the private formats ($output)"
}

test_the_step_still_installs_and_starts_the_unit() {
    local script
    script="$(cat "$KDE_SCRIPT")"

    grep -qx 'write_cliphist_service' "$KDE_SCRIPT" ||
        fail "the step should call write_cliphist_service"
    assert_contains "$script" 'systemctl --user daemon-reload' "the unit still gets reloaded"
    assert_contains "$script" 'systemctl --user enable --now cliphist.service' "and still gets started"
}

run_tests
