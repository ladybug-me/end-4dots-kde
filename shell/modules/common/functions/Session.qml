pragma Singleton

import Quickshell
import qs.services
import qs.utils
import qs.modules.common

Singleton {
    id: root

    function closeAllWindows() {
        Kwin.windowList.map(w => w.pid).forEach(pid => {
            if (pid)
                Quickshell.execDetached(["kill", pid]);
        });
    }

    function changePassword() {
        Launch.exec(["bash", "-c", `${Config.options.apps.changePassword}`]);
    }

    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        closeAllWindows();
        Quickshell.execDetached(["qdbus6", "org.kde.Shutdown", "/Shutdown", "logout"]);
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
