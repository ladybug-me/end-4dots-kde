pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    function pickColor(): void {
        if (!dbusProcess.running) {
            dbusProcess.running = true;
        }
    }

    Process {
        id: dbusProcess

        command: [
            "dbus-send",
            "--session",
            "--print-reply",
            "--dest=org.kde.KWin",
            "/ColorPicker",
            "org.kde.kwin.ColorPicker.pick"
        ]

        stdout: StdioCollector {
            id: outCollector

            onStreamFinished: {
                const text = outCollector.text;
                const match = text.match(/uint32\s+(\d+)/);
                if (match) {
                    const decimalColor = parseInt(match[1], 10);
                    if (decimalColor === 0)
                        return;
                    const hex = (decimalColor & 0x00FFFFFF).toString(16).padStart(6, "0");
                    const colorCode = "#" + hex.toUpperCase();

                    Quickshell.execDetached(["bash", "-c", `echo -n '${colorCode}' | wl-copy`]);
                    Quickshell.execDetached(["notify-send", "Color Picker", `Color ${colorCode} copied to clipboard!`]);
                }
            }
        }
    }
}
