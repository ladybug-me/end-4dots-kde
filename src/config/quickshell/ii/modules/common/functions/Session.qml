pragma Singleton
import Quickshell
import qs.services
import qs.modules.common
import Quickshell.Io

/**
 * Session management using KDE-native DBus calls.
 *
 * Logout/Shutdown/Reboot use KSMServer (org.kde.ksmserver) for graceful
 * session management — KDE handles saving apps, prompts, etc.
 *
 * KSMServer logout() args:
 *   confirm: 0 = no confirm dialog, 1 = show confirm dialog
 *   type:    0 = logout, 1 = reboot, 2 = shutdown
 *   mode:    1 = save if possible, 2 = don't save, 3 = save (force)
 *
 * Sleep/Hibernate use Solid.PowerManagement DBus or systemctl fallback.
 * Lock uses loginctl (already correct for KDE Plasma).
 */
Singleton {
    id: root

    // ── Lock ────────────────────────────────────────────────────────────────
    function lock() {
        // loginctl lock-session is the correct KDE/systemd call
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    // ── Sleep (suspend) ──────────────────────────────────────────────────────
    function suspend() {
        // Try KDE Solid.PowerManagement first, fall back to systemctl
        Quickshell.execDetached([
            "bash", "-c",
            "qdbus6 org.kde.Solid.PowerManagement " +
            "/org/kde/Solid/PowerManagement " +
            "org.kde.Solid.PowerManagement.requestSleep 2>/dev/null || " +
            "systemctl suspend 2>/dev/null || " +
            "loginctl suspend"
        ]);
    }

    // ── Hibernate ────────────────────────────────────────────────────────────
    function hibernate() {
        Quickshell.execDetached([
            "bash", "-c",
            "qdbus6 org.kde.Solid.PowerManagement " +
            "/org/kde/Solid/PowerManagement " +
            "org.kde.Solid.PowerManagement.requestHibernation 2>/dev/null || " +
            "systemctl hibernate 2>/dev/null || " +
            "loginctl hibernate"
        ]);
    }

    // ── Logout ───────────────────────────────────────────────────────────────
    function logout() {
        Quickshell.execDetached([
            "bash", "-c",
            "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null || " +
            "qdbus6 org.kde.ksmserver /KSMServer logout 0 0 2 2>/dev/null || " +
            "loginctl terminate-session $XDG_SESSION_ID 2>/dev/null || " +
            "loginctl terminate-user $USER"
        ]);
    }

    // ── Shutdown ─────────────────────────────────────────────────────────────
    function poweroff() {
        // KSMServer: confirm=0, type=2 (shutdown), mode=2 (don't save)
        Quickshell.execDetached([
            "bash", "-c",
            "qdbus6 org.kde.ksmserver /KSMServer logout 0 2 2 2>/dev/null || " +
            "systemctl poweroff 2>/dev/null || " +
            "loginctl poweroff"
        ]);
    }

    // ── Reboot ───────────────────────────────────────────────────────────────
    function reboot() {
        // KSMServer: confirm=0, type=1 (reboot), mode=2 (don't save)
        Quickshell.execDetached([
            "bash", "-c",
            "qdbus6 org.kde.ksmserver /KSMServer logout 0 1 2 2>/dev/null || " +
            "systemctl reboot 2>/dev/null || " +
            "loginctl reboot"
        ]);
    }

    // ── Reboot to Firmware (UEFI setup) ─────────────────────────────────────
    function rebootToFirmware() {
        // systemctl is the reliable path for firmware reboot
        Quickshell.execDetached([
            "bash", "-c",
            "systemctl reboot --firmware-setup 2>/dev/null || " +
            "qdbus6 org.kde.ksmserver /KSMServer logout 0 1 2 2>/dev/null || " +
            "reboot --firmware-setup"
        ]);
    }

    // ── Task Manager ─────────────────────────────────────────────────────────
    function launchTaskManager() {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`]);
    }

    // ── Change Password ──────────────────────────────────────────────────────
    function changePassword() {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.changePassword}`]);
    }
}
