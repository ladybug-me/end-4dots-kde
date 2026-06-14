pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common

/**
 * Exposes the active Hyprland Xkb keyboard layout name and code for indicators.
 */
Singleton {
    id: root
    property list<string> layoutCodes: []
    property string currentLayoutName: ""
    property string currentLayoutCode: ""

    Process {
        id: fetchLayoutsProc
        running: true
        command: ["bash", "-c", "qdbus6 --literal org.kde.keyboard /Layouts org.kde.KeyboardLayouts.getLayoutsList"]

        stdout: StdioCollector {
            id: devicesCollector
            onStreamFinished: {
                // [Argument: a(sss) {[Argument: (sss) "us", "", "English (US)"]}]
                const textStr = String(devicesCollector.text);
                let codes = [];
                let name = "us";
                
                const regex = /"([^"]*)", "([^"]*)", "([^"]*)"/g;
                let match;
                while ((match = regex.exec(textStr)) !== null) {
                    codes.push(match[1]);
                    if (codes.length === 1) {
                        name = match[3];
                        root.currentLayoutCode = match[1];
                    }
                }
                
                root.layoutCodes = codes;
                root.currentLayoutName = name;
            }
        }
    }
}
