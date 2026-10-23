pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.utils
import qs.modules.common

Singleton {
    id: root

    function closeAllWindows() {
        if (WM.compositor === "kwin") {
            Kwin.windowList.map(w => w.pid).forEach(pid => {
                if (pid) Quickshell.execDetached(["kill", pid]);
            });
        } else {
            (WM.windowList || []).map(w => w.pid).forEach(pid => {
                if (pid) Quickshell.execDetached(["kill", pid]);
            });
        }
    }

    function changePassword() {
        Launch.exec(["bash", "-c", `${Config.options.apps.changePassword}`]);
    }

    function lock() {
        if (WM.compositor === "niri") {
            Quickshell.execDetached(["qs", "-c", "end4-pC", "ipc", "call", "lock", "activate"]);
        } else {
            Quickshell.execDetached(["loginctl", "lock-session"]);
        }
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        closeAllWindows();
        if (WM.compositor === "niri") {
            Quickshell.execDetached(["niri", "msg", "action", "quit"]);
        } else if (WM.compositor === "kwin") {
            Quickshell.execDetached(["qdbus6", "org.kde.Shutdown", "/Shutdown", "logout"]);
        } else {
            Quickshell.execDetached(["pkill", "-i", "Hyprland"]);
        }
    }

    function launchTaskManager() {
        Launch.exec(["bash", "-c", `${Config.options.apps.taskManager}`]);
    }

    function hibernate() {
        Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]);
    }

    function poweroff() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]);
    }

    function reboot() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]);
    }

    function rebootToFirmware() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]);
    }
}
