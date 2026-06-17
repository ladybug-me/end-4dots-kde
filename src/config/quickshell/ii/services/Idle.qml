pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland


/**
 * KDE port: Idle inhibitor using both the Wayland zwp_idle_inhibit_manager_v1
 * protocol (via Quickshell's IdleInhibitor) AND org.freedesktop.ScreenSaver
 * DBus interface as a fallback to ensure the display stays on.
 *
 * The original code used `Persistent.isNewHyprlandInstance` to detect session
 * resets — on KDE this flag is always true (HYPRLAND_INSTANCE_SIGNATURE is
 * unset). Replaced with a simple state read on startup.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    // Cookie returned by org.freedesktop.ScreenSaver.Inhibit (KDE fallback)
    property int _screensaverCookie: -1

    // Restore persisted inhibit state on startup (no Hyprland session check)
    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Persistent.ready) {
                root.inhibit = Persistent.states.idle.inhibit ?? false;
            }
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
        _applyScreensaverInhibit(root.inhibit);
    }

    // DBus ScreenSaver inhibit/uninhibit as belt-and-suspenders for KDE
    Process {
        id: screensaverProc
    }

    function _applyScreensaverInhibit(enable) {
        if (enable) {
            screensaverProc.command = [
                "bash", "-c",
                "dbus-send --session --print-reply " +
                "--dest=org.freedesktop.ScreenSaver " +
                "/org/freedesktop/ScreenSaver " +
                "org.freedesktop.ScreenSaver.Inhibit " +
                "string:'quickshell' string:'user-requested' " +
                "2>/dev/null | awk '/uint32/{print $2}' > /tmp/qs-ss-cookie"
            ];
        } else {
            screensaverProc.command = [
                "bash", "-c",
                "COOKIE=$(cat /tmp/qs-ss-cookie 2>/dev/null); " +
                "[ -n \"$COOKIE\" ] && dbus-send --session " +
                "--dest=org.freedesktop.ScreenSaver " +
                "/org/freedesktop/ScreenSaver " +
                "org.freedesktop.ScreenSaver.UnInhibit " +
                "uint32:$COOKIE 2>/dev/null; rm -f /tmp/qs-ss-cookie"
            ];
        }
        screensaverProc.running = false;
        screensaverProc.running = true;
    }

    // Wayland idle inhibitor (zwp_idle_inhibit_manager_v1)
    // Works on KDE Plasma 6 which supports this protocol
    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region {
                item: null
            }
        }
    }
}
