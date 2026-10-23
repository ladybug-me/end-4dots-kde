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
    property string hostname: ""
    property string homeUrl: ""
    property string documentationUrl: ""
    property string supportUrl: ""
    property string bugReportUrl: ""
    property string privacyPolicyUrl: ""
    property string logo: ""
    readonly property string desktopEnvironment: Quickshell.env("XDG_CURRENT_DESKTOP") || "KDE"
    readonly property string windowingSystem: Quickshell.env("WAYLAND_DISPLAY") ? "Wayland" : (Quickshell.env("DISPLAY") ? "X11" : "Wayland")

    property string cpu: ""
    property string gpu: ""
    property string memory: ""
    property string disk: ""
    property string shell: ""
    property string packages: ""
    property string installAge: ""
    property string kernelVersion: ""

    function refresh(): void {
        getCpu.running = false; getCpu.running = true;
        getGpu.running = false; getGpu.running = true;
        getMemory.running = false; getMemory.running = true;
        getDisk.running = false; getDisk.running = true;
        getShell.running = false; getShell.running = true;
        getPackages.running = false; getPackages.running = true;
        getInstallAge.running = false; getInstallAge.running = true;
        getKernel.running = false; getKernel.running = true;
    }

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false

        onTriggered: {
            getHostname.running = true;
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

    Process {
        id: getHostname
        command: ["cat", "/etc/hostname"]
        stdout: SplitParser { onRead: data => root.hostname = data.trim() }
    }

    FileView {
        id: fileOsRelease
        path: "/etc/os-release"
    }

    Process {
        id: getKernel
        running: false
        command: ["uname", "-r"]
        stdout: SplitParser { onRead: data => root.kernelVersion = data.trim() }
    }

    Process {
        id: getCpu
        running: false
        command: ["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2- | sed 's/^ //' | sed 's/Intel(R)/Intel®/' | sed 's/Core(TM)/Core™/' | sed 's/CPU //' | sed 's/  */ /g' | sed 's/ @ */ @/'"]
        stdout: SplitParser { onRead: data => root.cpu = data.trim() }
    }

    Process {
        id: getGpu
        running: false
        command: ["bash", "-c", `
            gpu=$(glxinfo 2>/dev/null | grep 'renderer string' | grep -o 'Intel(R) HD Graphics [0-9]\\{4\\}' | sed 's/Intel(R)/Intel®/')
            if [ -z "$gpu" ]; then
                gpus=$(lspci | grep -iE 'vga|3d|display')
                line=$(echo "$gpus" | grep -vi 'Intel Corporation' | head -1)
                [ -z "$line" ] && line=$(echo "$gpus" | head -1)
                gpu=$(echo "$line" | sed -E '
                    s/.*: //;
                    s/ *\\(rev [0-9a-f]+\\)//;
                    s/Advanced Micro Devices, Inc\\. \\[AMD\\/ATI\\]//;
                    s/NVIDIA Corporation//;
                    s/Intel Corporation//;
                    s/.*\\[([^]]+)\\]$/\\1/;
                    s/^ *//;
                    s/ *$//
                ')
            fi
            echo "$gpu"
        `]
        stdout: SplitParser { onRead: data => root.gpu = data.trim() }
    }

    Process {
        id: getMemory
        running: false
        command: ["bash", "-c", "LC_ALL=C free -h | awk '/^Mem:/ {print $3 \" / \" $2}'"]
        stdout: SplitParser { onRead: data => root.memory = data.trim() }
    }

    Process {
        id: getDisk
        running: false
        command: ["bash", "-c", "df -h / | awk 'NR==2 {print $3 \" / \" $2}'"]
        stdout: SplitParser { onRead: data => root.disk = data.trim() }
    }

    Process {
        id: getShell
        running: false
        command: ["bash", "-c", "echo $SHELL | awk -F'/' '{print $NF}'"]
        stdout: SplitParser { onRead: data => root.shell = data.trim() }
    }

    Process {
        id: getPackages
        running: false
        command: ["bash", "-c", "pacman_count=$(pacman -Q | wc -l); flatpak_count=$(flatpak list 2>/dev/null | wc -l || echo 0); if [ \"$flatpak_count\" -gt 0 ]; then echo \"$pacman_count pacman, $flatpak_count fp\"; else echo \"$pacman_count pacman\"; fi"]
        stdout: SplitParser { onRead: data => root.packages = data.trim() }
    }

    Process {
        id: getInstallAge
        running: false
        command: ["bash", "-c", "install_sec=$(stat -c %W /); if [ \"$install_sec\" -le 0 ]; then install_sec=$(stat -c %Y /); fi; now_sec=$(date +%s); age_sec=$((now_sec - install_sec)); days=$((age_sec / 86400)); echo \"$days days\""]
        stdout: SplitParser { onRead: data => root.installAge = data.trim() }
    }
}