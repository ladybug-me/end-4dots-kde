pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import qs.services
import qs.modules.common

Singleton {
    id: root

    function closeAllWindows(): void {
        Kwin.windowList.forEach(w => {
            if (w.pid) Quickshell.execDetached(["kill", w.pid]);
        });
    }

    function changePassword(): void {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.changePassword}`]);
    }

    function lock(): void {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend(): void {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout(): void {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null || loginctl terminate-session self 2>/dev/null"]);
    }

    function launchTaskManager(): void {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`]);
    }

    function hibernate(): void {
        Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]);
    }

    function poweroff(): void {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]);
    }

    function reboot(): void {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]);
    }

    function rebootToFirmware(): void {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]);
    }
}

