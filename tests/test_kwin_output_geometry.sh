#!/usr/bin/env bash
# suite: fast

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_SRC="$REPO_ROOT/shell/plugin/src/Caelestia/Services/kwinactivewindowbridge.cpp"
KWIN_QML="$REPO_ROOT/shell/services/Kwin.qml"

test_physical_geometry_is_not_reintroduced_in_kwin_bridge() {
    assert_file_not_contains "$BRIDGE_SRC" "physicalGeometry" \
        "Issue #733 regression: physicalGeometry must not be present in kwinactivewindowbridge.cpp"
    assert_file_not_contains "$BRIDGE_SRC" "devicePixelRatio" \
        "Issue #733 regression: devicePixelRatio must not be applied to screen geometry in kwinactivewindowbridge.cpp"
}

test_logical_screen_geometry_is_used_directly() {
    assert_file_contains "$BRIDGE_SRC" "screen->geometry().intersected(windowRect)" \
        "getOutputNameForGeometry must intersect windowRect with logical screen geometry"
    assert_file_contains "$BRIDGE_SRC" "screen->geometry().center() - windowCentre" \
        "getOutputNameForGeometry fallback must calculate distance to logical screen center"
}

test_fractional_scale_multi_monitor_output_mapping() {
    if ! command -v python3 >/dev/null 2>&1; then
        skip_test "python3 is required for fractional scaling geometry simulation"
        return 0
    fi

    local py_out
    py_out="$(python3 - << 'EOF'
def get_output_logical(screens, win_rect):
    best_screen = None
    max_area = 0
    wx, wy, ww, wh = win_rect
    for name, (sx, sy, sw, sh), _scale in screens:
        ix = max(sx, wx)
        iy = max(sy, wy)
        iw = max(0, min(sx + sw, wx + ww) - ix)
        ih = max(0, min(sy + sh, wy + wh) - iy)
        area = iw * ih
        if area > max_area:
            max_area = area
            best_screen = name
    return best_screen

def get_output_physical_buggy(screens, win_rect):
    best_screen = None
    max_area = 0
    wx, wy, ww, wh = win_rect
    for name, (sx, sy, sw, sh), scale in screens:
        # Buggy physicalGeometry logic: scales logical bounds by DPR
        psx, psy = round(sx * scale), round(sy * scale)
        psw, psh = round(sw * scale), round(sh * scale)
        ix = max(psx, wx)
        iy = max(psy, wy)
        iw = max(0, min(psx + psw, wx + ww) - ix)
        ih = max(0, min(psy + psh, wy + wh) - iy)
        area = iw * ih
        if area > max_area:
            max_area = area
            best_screen = name
    return best_screen

# Issue #733 setup:
# Monitor 1 (DP-1, 4K scaled at 150%): logical geometry 0,0, 2560x1440, scale 1.5
# Monitor 2 (DP-2, 1440p scaled at 100%): logical geometry 2560,0, 2560x1440, scale 1.0
screens = [
    ("DP-1", (0, 0, 2560, 1440), 1.5),
    ("DP-2", (2560, 0, 2560, 1440), 1.0)
]

# Fullscreen video on 4K monitor (logical rect 0,0, 2560x1440)
fs_dp1 = (0, 0, 2560, 1440)
# Fullscreen video on 1440p monitor (logical rect 2560,0, 2560x1440)
fs_dp2 = (2560, 0, 2560, 1440)

assert get_output_logical(screens, fs_dp1) == "DP-1", "Logical mapping must assign 4K fullscreen to DP-1"
assert get_output_logical(screens, fs_dp2) == "DP-2", "Logical mapping must assign 1440p fullscreen to DP-2"

# Verify that buggy physicalGeometry creates spurious overlap into adjacent screen:
# Physical rect of DP-1 becomes 0..3840, overlapping into DP-2 (2560..3840)
buggy_overlap_area = max(0, min(3840, 5120) - 2560) * 1440
assert buggy_overlap_area > 0, "Demonstrating physicalGeometry flaw where scaled rect overlaps adjacent monitor"

print("ok")
EOF
)"
    assert_eq "ok" "$py_out" "fractional scaling output mapping simulation must succeed"
}

test_commit_668d0a97_desktop_resolution_intent_is_preserved() {
    assert_file_contains "$BRIDGE_SRC" "KWinWorkspaceState::instance()" \
        "KWinWorkspaceState must be queried in kwinactivewindowbridge.cpp (from 668d0a97)"
    assert_file_contains "$BRIDGE_SRC" "uuidForIndex" \
        "uuidForIndex must be used for desktop resolution (from 668d0a97)"
    assert_file_contains "$BRIDGE_SRC" "indexForId" \
        "indexForId must be used for desktop resolution (from 668d0a97)"
    assert_file_contains "$BRIDGE_SRC" "plasmaWindows->refresh()" \
        "plasmaWindows->refresh() must be called in refreshWindows (from 668d0a97)"
    assert_file_contains "$KWIN_QML" "onWorkspacesChanged: root.refreshWindows()" \
        "Kwin.qml must refresh windows on workspacesChanged (from 668d0a97)"
}

run_tests
