pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell
import Quickshell.Io

/**
 * KDE Night Light service using KWin's NightLight DBus interface.
 *
 * DBus interface: org.kde.KWin.NightLight at /org/kde/KWin/NightLight
 *
 * Commands used:
 *   Preview temperature (live, reverts on stopPreview):
 *     qdbus6 org.kde.KWin.NightLight /org/kde/KWin/NightLight preview <temp>
 *
 *   Stop preview (revert to actual state):
 *     qdbus6 org.kde.KWin.NightLight /org/kde/KWin/NightLight stopPreview
 *
 *   Enable/disable Night Light persistently:
 *     kwriteconfig6 --file kwinrc --group NightColor --key Active true/false
 *     qdbus6 org.kde.KWin /KWin reconfigure
 *
 * Logic matrix:
 *   Toggle ON  + slider dragging  → preview <temp>; on release: commit temp via kwriteconfig6
 *   Toggle ON  + no drag          → Night Light active at saved colorTemperature
 *   Toggle OFF + slider dragging  → preview <temp> only; on release: stopPreview (no commit)
 *   Toggle OFF + no drag          → Night Light inactive
 */
Singleton {
    id: root

    signal gammaChangeAttempt()

    // ── Public state ─────────────────────────────────────────────────────────
    readonly property real gammaLowerLimit: 25
    property int gamma: 100  // Kept for API compat with gamma slider

    // Called by shell.qml on startup — state is already read by fetchProc (running:true)
    function load() {} // no-op; fetchProc auto-reads state on singleton init

    property string from: Config.options?.light?.night?.from ?? "19:00"
    property string to: Config.options?.light?.night?.to ?? "06:30"
    property bool automatic: Config.options?.light?.night?.automatic && (Config?.ready ?? true)
    property int colorTemperature: Config.options?.light?.night?.colorTemperature ?? 4500
    property int defaultColorTemperature: 6500

    // True when night light is currently active (toggle ON)
    property bool temperatureActive: false

    // True when the user is dragging the slider (preview mode)
    property bool isPreviewing: false

    // Internal state
    property bool shouldBeOn: false
    property bool firstEvaluation: true
    property var manualActive
    property int manualActiveHour
    property int manualActiveMinute

    property int fromHour: Number(from.split(":")[0])
    property int fromMinute: Number(from.split(":")[1])
    property int toHour: Number(to.split(":")[0])
    property int toMinute: Number(to.split(":")[1])

    property int clockHour: DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes

    // ── Automatic scheduling (Disabled on KDE to respect KWin's native scheduler) ───
    // onClockMinuteChanged: reEvaluate()
    // onAutomaticChanged: {
    //     root.manualActive = undefined;
    //     root.firstEvaluation = true;
    //     reEvaluate();
    // }

    function inBetween(t, from, to) {
        if (from < to) {
            return (t >= from && t <= to);
        } else {
            return (t >= from || t <= to);
        }
    }

    function reEvaluate() {
        // Disabled: KDE manages its own NightLight scheduling.
    }

    // onShouldBeOnChanged: ensureState()
    function ensureState() {
        // Disabled: Prevent Quickshell from aggressively overwriting KWin's manual settings
    }

    // ── DBus Processes ───────────────────────────────────────────────────────

    // Live preview process (non-persistent, just visual)
    Process {
        id: previewProc
    }

    // Stop preview process
    Process {
        id: stopPreviewProc
        command: [
            "bash", "-c", "qdbus6 org.kde.KWin /KWin reconfigure"
        ]
    }

    // Persistent enable/disable via kwriteconfig6 + reconfigure
    Process {
        id: enableProc
    }

    // Read current KWin NightLight state on startup
    Process {
        id: fetchProc
        running: true
        command: [
            "bash", "-c",
            "kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null || echo 'false'"
        ]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const output = stateCollector.text.trim().toLowerCase();
                root.temperatureActive = (output === "true");
            }
        }
    }

    // ── Temperature preview (while slider is dragged) ────────────────────────

    /**
     * Call this while the user is dragging the slider.
     * If toggle is ON: previews and will commit on sliderReleased()
     * If toggle is OFF: previews only, reverted on sliderReleased()
     */
    function sliderPreview(temp) {
        root.isPreviewing = true;
        previewProc.command = [
            "qdbus6", "org.kde.KWin",
            "/ColorCorrect", "org.kde.kwin.ColorCorrect.preview",
            String(Math.round(temp))
        ];
        previewProc.running = false;
        previewProc.running = true;
    }

    /**
     * Call this when the slider is released.
     * Commits the temperature via kwriteconfig6 permanently.
     */
    function sliderReleased(temp) {
        root.isPreviewing = false;
        // Always commit: write to config and reconfigure KWin
        _commitTemperature(temp);
    }

    // ── Persistent enable/disable ────────────────────────────────────────────

    function enableTemperature() {
        root.temperatureActive = true;
        if (!root.isPreviewing) {
            _commitTemperature(root.colorTemperature);
        }
        _setNightLightEnabled(true);
    }

    function disableTemperature() {
        root.temperatureActive = false;
        if (root.isPreviewing) {
            // Stop any active preview
            stopPreviewProc.running = false;
            stopPreviewProc.running = true;
        }
        _setNightLightEnabled(false);
    }

    // Write temperature to kwinrc and reconfigure KWin
    function _commitTemperature(temp) {
        const t = Math.round(temp);
        enableProc.command = [
            "bash", "-c",
            `kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature ${t} && ` +
            `qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true`
        ];
        enableProc.running = false;
        enableProc.running = true;
    }

    // Enable or disable Night Light in kwinrc
    function _setNightLightEnabled(enabled) {
        const val = enabled ? "true" : "false";
        enableProc.command = [
            "bash", "-c",
            `kwriteconfig6 --file kwinrc --group NightColor --key Active ${val} && ` +
            `qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true`
        ];
        enableProc.running = false;
        enableProc.running = true;
    }

    // ── Toggle ───────────────────────────────────────────────────────────────

    /**
     * Toggle night light on/off.
     * Pass `active` to force a specific state (true/false).
     * If undefined, toggles current state.
     */
    function toggleTemperature(active = undefined) {
        if (root.manualActive === undefined) {
            root.manualActive = root.temperatureActive;
            root.manualActiveHour = root.clockHour;
            root.manualActiveMinute = root.clockMinute;
        }

        const newState = (active !== undefined) ? active : !root.temperatureActive;
        root.manualActive = newState;

        if (newState) {
            root.enableTemperature();
        } else {
            root.disableTemperature();
        }
    }

    // ── Gamma via xrandr (display dimming) ───────────────────────────────────
    // Maps gamma 25..100 → xrandr gamma 0.25..1.0 for software display dimming.
    // This is completely independent of KDE NightLight / colour temperature.
    // Applies to all connected X11 outputs detected by xrandr.
    //
    // Usage: Brightness.qml calls setGamma() when the brightness slider goes
    // below the 0.3 threshold. gamma=100 = full brightness, gamma=25 = minimum.

    Process {
        id: gammaProc
        environment: {
            // Ensure DISPLAY is set for xrandr (X11 tool used under Wayland/XWayland)
            var env = ({});
            env["DISPLAY"] = Quickshell.env("DISPLAY") || ":0";
            return env;
        }
    }

    // On startup, reset gamma to 1.0 (full) so stale gamma from previous session
    // doesn't persist across restarts
    Component.onCompleted: {
        _applyXrandrGamma(1.0);
    }

    function _applyXrandrGamma(value) {
        // Apply gamma to all connected outputs via xrandr
        // value: 0.0..1.0 (1.0 = full brightness, no dimming)
        const g = value.toFixed(3);
        gammaProc.command = [
            "bash", "-c",
            `DISPLAY="\${DISPLAY:-:0}" xrandr --listmonitors 2>/dev/null ` +
            `| awk '/[0-9]+:/{print $NF}' ` +
            `| while read -r out; do ` +
            `  DISPLAY="\${DISPLAY:-:0}" xrandr --output "$out" --gamma ${g}:${g}:${g} 2>/dev/null || true; ` +
            `done`
        ];
        gammaProc.running = false;
        gammaProc.running = true;
    }

    function setGamma(newGamma) {
        root.gamma = Math.max(root.gammaLowerLimit, Math.min(100, newGamma));
        root.gammaChangeAttempt();
        // Map gamma 25..100 → xrandr value 0.25..1.0
        const xrandrVal = root.gamma / 100.0;
        _applyXrandrGamma(xrandrVal);
    }

    // ── React to config changes ──────────────────────────────────────────────
    Connections {
        target: Config.options.light.night
        function onColorTemperatureChanged() {
            if (!root.temperatureActive || root.isPreviewing) return;
            _commitTemperature(Config.options.light.night.colorTemperature);
        }
    }
}