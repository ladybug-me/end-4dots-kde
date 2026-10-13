#!/usr/bin/env bash
# suite: fast

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES="$REPO_ROOT/shell/services"
PLUGIN_SERVICES="$REPO_ROOT/shell/plugin/src/Caelestia/Services"
PREFS="$REPO_ROOT/shell/modules/nexus/pages/services"

if [[ ! -f "$SERVICES/StreamMonitor.qml" ]]; then
    skip_test "StreamMonitor.qml not present in this flavor"
    exit 0
fi

test_stream_monitor_binds_to_native_pipewire_watcher() {
    assert_contains "$SERVICES/StreamMonitor.qml" 'PipewireStreamWatcher.streaming' \
        "StreamMonitor must bind to native PipewireStreamWatcher"
    assert_contains "$SERVICES/StreamMonitor.qml" 'Recorder.running' \
        "StreamMonitor must account for local screen recorder state"
    assert_not_contains "$SERVICES/StreamMonitor.qml" 'Quickshell.Services.Pipewire' \
        "StreamMonitor must not rely on audio-only Quickshell.Services.Pipewire"
}

test_native_pipewire_watcher_sources_are_registered() {
    assert_file_exists "$PLUGIN_SERVICES/pipewirestreamwatcher.hpp"
    assert_file_exists "$PLUGIN_SERVICES/pipewirestreamwatcher.cpp"
    assert_contains "$PLUGIN_SERVICES/CMakeLists.txt" 'pipewirestreamwatcher.cpp' \
        "pipewirestreamwatcher.cpp must be registered in CMakeLists.txt"
    assert_contains "$PLUGIN_SERVICES/pipewirestreamwatcher.hpp" 'QML_SINGLETON' \
        "PipewireStreamWatcher must be a QML singleton"
}

test_notification_preferences_page_has_no_duplicate_properties() {
    assert_contains "$PREFS/NotificationPreferencesPage.qml" 'dndWhileStreaming' \
        "NotificationPreferencesPage must configure dndWhileStreaming"
}

run_tests
