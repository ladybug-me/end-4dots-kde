pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * System and OS information service.
 */
Singleton {
    id: root

    property string distroName: "Linux"
    property string distroId: "linux"
    property string distroIcon: "linux-symbolic"
    readonly property string username: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user"
    property string homeUrl: ""
    property string documentationUrl: ""
    property string supportUrl: ""
    property string bugReportUrl: ""
    property string privacyPolicyUrl: ""
    property string logo: ""
    readonly property string desktopEnvironment: Quickshell.env("XDG_CURRENT_DESKTOP") || "KDE"
    readonly property string windowingSystem: Quickshell.env("WAYLAND_DISPLAY") ? "Wayland" : (Quickshell.env("DISPLAY") ? "X11" : "Wayland")

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false

        onTriggered: {
            fileOsRelease.reload();
            const textOsRelease = fileOsRelease.text();

            const prettyNameMatch = textOsRelease.match(/^PRETTY_NAME="(.+?)"/m);
            const nameMatch = textOsRelease.match(/^NAME="(.+?)"/m);
            root.distroName = prettyNameMatch ? prettyNameMatch[1] : (nameMatch ? nameMatch[1].replace(/Linux/i, "").trim() : "Linux");

            const idMatch = textOsRelease.match(/^ID="?(.+?)"?$/m);
            root.distroId = idMatch ? idMatch[1].toLowerCase() : "linux";

            const homeUrlMatch = textOsRelease.match(/^HOME_URL="(.+?)"/m);
            root.homeUrl = homeUrlMatch ? homeUrlMatch[1] : "";
            const documentationUrlMatch = textOsRelease.match(/^DOCUMENTATION_URL="(.+?)"/m);
            root.documentationUrl = documentationUrlMatch ? documentationUrlMatch[1] : "";
            const supportUrlMatch = textOsRelease.match(/^SUPPORT_URL="(.+?)"/m);
            root.supportUrl = supportUrlMatch ? supportUrlMatch[1] : "";
            const bugReportUrlMatch = textOsRelease.match(/^BUG_REPORT_URL="(.+?)"/m);
            root.bugReportUrl = bugReportUrlMatch ? bugReportUrlMatch[1] : "";
            const privacyPolicyUrlMatch = textOsRelease.match(/^PRIVACY_POLICY_URL="(.+?)"/m);
            root.privacyPolicyUrl = privacyPolicyUrlMatch ? privacyPolicyUrlMatch[1] : "";
            const logoFieldMatch = textOsRelease.match(/^LOGO="?(.+?)"?$/m);
            root.logo = logoFieldMatch ? logoFieldMatch[1] : "";

            switch (root.distroId) {
            case "artix":
            case "arch":
                root.distroIcon = "arch-symbolic";
                break;
            case "manjaro":
                root.distroIcon = "manjaro-symbolic";
                break;
            case "endeavouros":
                root.distroIcon = "endeavouros-symbolic";
                break;
            case "cachyos":
                root.distroIcon = "cachyos-symbolic";
                break;
            case "nixos":
                root.distroIcon = "nixos-symbolic";
                break;
            case "fedora":
                root.distroIcon = "fedora-symbolic";
                break;
            case "linuxmint":
            case "ubuntu":
            case "zorin":
            case "pop":
            case "popos":
                root.distroIcon = "ubuntu-symbolic";
                break;
            case "debian":
            case "raspbian":
            case "kali":
                root.distroIcon = "debian-symbolic";
                break;
            case "gentoo":
            case "funtoo":
                root.distroIcon = "gentoo-symbolic";
                break;
            default:
                root.distroIcon = "linux-symbolic";
                break;
            }

            if (textOsRelease.toLowerCase().includes("nyarch"))
                root.distroIcon = "nyarch-symbolic";

            if (root.logo.trim().length === 0)
                root.logo = root.distroIcon;
        }
    }

    FileView {
        id: fileOsRelease

        path: "/etc/os-release"
    }
}