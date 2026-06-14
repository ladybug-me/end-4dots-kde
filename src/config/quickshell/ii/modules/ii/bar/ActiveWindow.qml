import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property int effectiveActiveWorkspaceId: 1
    
    Process {
        id: kwinDesktopPollerInit
        running: true
        command: ["qdbus6", "org.kde.KWin", "/KWin", "currentDesktop"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim());
                if (!isNaN(val)) effectiveActiveWorkspaceId = val;
            }
        }
    }

    // Listen to KWin's VirtualDesktopManager signals
    Process {
        id: kwinDesktopListener
        running: true
        command: ["dbus-monitor", "type='signal',interface='org.kde.KWin.VirtualDesktopManager',member='currentChanged'"]
        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                // When output changes, just re-poll to get the correct int index since we only get the UUID from the signal
                kwinDesktopPollerInit.running = true;
            }
        }
    }

    implicitWidth: colLayout.implicitWidth

    ColumnLayout {
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: Translation.tr("Desktop")
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: `${Translation.tr("Workspace")} ${effectiveActiveWorkspaceId}`
        }

    }

}
