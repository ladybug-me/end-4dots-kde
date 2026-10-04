import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    readonly property var monitor: (root.QsWindow.window?.screen && root.QsWindow.window.screen.name) ? Kwin.monitorFor(root.QsWindow.window.screen) : (Kwin.focusedMonitor ?? null)
    readonly property int currentWsId: {
        const activeWs = Kwin.activeWsId;
        const activeByOut = Kwin.activeByOutput;
        const perOutput = (monitor?.name && activeByOut) ? activeByOut[monitor.name] : 0;
        return perOutput > 0 ? perOutput : (activeWs > 0 ? activeWs : 1);
    }
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property string activeWindowAddress: Kwin.activeWindow?.address ? String(Kwin.activeWindow.address) : ""
    property bool focusingThisMonitor: Kwin.focusedMonitor?.name === monitor?.name
    property var biggestWindow: Kwin.biggestWindowForWorkspace(currentWsId)

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
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                root.activeWindow?.appId :
                (root.biggestWindow?.["class"]) ?? Translation.tr("Desktop")
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                root.activeWindow?.title :
                (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${root.currentWsId}`
        }
    }
}
