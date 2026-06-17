pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * KDE port: ydotool key injection service.
 *
 * Requires ydotoold daemon running with /dev/uinput access.
 * The setup script ensures:
 *   1. /etc/sudoers.d/ydotoold-nopasswd allows running ydotoold as root
 *   2. ydotoold.service is enabled as a systemd user service
 *
 * If ydotoold is not running, this singleton attempts to start it.
 */
Singleton {
    id: root
    property int shiftMode: 0 // 0: off, 1: on, 2: lock
    property list<int> shiftKeys: [42, 54] // Keycodes for Shift keys (left and right)
    property list<int> altKeys: [56, 100] // Keycodes for Alt keys (left and right)
    property list<int> ctrlKeys: [29, 97] // Keycodes for Ctrl keys (left and right)
    property bool daemonRunning: false

    // Socket path — must match what ydotoold was started with
    // /run/user/<uid>/ is standard for XDG_RUNTIME_DIR
    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000") + "/.ydotool_socket"

    // Check if ydotoold is running on startup; start it if needed
    Process {
        id: checkDaemonProc
        running: true
        command: ["pidof", "ydotoold"]
        onExited: (exitCode) => {
            root.daemonRunning = (exitCode === 0);
            if (!root.daemonRunning) {
                // Attempt to start via wrapper (uses NOPASSWD sudo)
                startDaemonProc.running = true;
            }
        }
    }

    Process {
        id: startDaemonProc
        running: false
        command: ["bash", "-c",
            "systemctl --user start ydotoold.service 2>/dev/null; sleep 1; " +
            "pidof ydotoold || sudo /usr/bin/ydotoold " +
            "--socket-path=/run/user/$(id -u)/.ydotool_socket --socket-perm=0666 &"]
        onExited: (exitCode) => {
            root.daemonRunning = true; // optimistic
        }
    }

    // Build ydotool command with explicit socket path
    function _ydotool(args) {
        return ["env", "YDOTOOL_SOCKET=" + root.socketPath, "ydotool"].concat(args);
    }

    function releaseAllKeys() {
        const keycodes = Array.from(Array(249).keys());
        Quickshell.execDetached(
            _ydotool(["key", "--key-delay", "0",
                ...keycodes.map(keycode => `${keycode}:0`)
            ])
        )
        root.shiftMode = 0; // Reset shift mode
    }

    function releaseShiftKeys() {
        Quickshell.execDetached(
            _ydotool(["key", "--key-delay", "0",
                ...root.shiftKeys.map(keycode => `${keycode}:0`)
            ])
        )
        root.shiftMode = 0; // Reset shift mode
    }

    function press(keycode) {
        Quickshell.execDetached(
            _ydotool(["key", "--key-delay", "0", `${keycode}:1`])
        );
    }

    function release(keycode) {
        Quickshell.execDetached(
            _ydotool(["key", "--key-delay", "0", `${keycode}:0`])
        );
    }
}
