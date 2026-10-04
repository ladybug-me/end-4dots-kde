import QtQuick
import Quickshell.Wayland
import qs.services
import qs.modules.common as C

NestableObject {
    id: root

    required property var monitor
    readonly property var liveMonitorData: (monitor && monitor.id !== undefined) ? (Kwin.monitors.find(m => m.id === monitor.id) || monitor) : (Kwin.focusedMonitor ?? null)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int activeWorkspace: Kwin.activeWorkspaceFor(monitor?.name) || monitor?.activeWorkspace?.id || Kwin.activeWsId || 1
    readonly property bool currentWorkspaceNotFake: activeWindow?.activated ?? false
    readonly property int fakeWorkspace: currentWorkspaceNotFake ? -9999 : activeWorkspace
    readonly property int shownCount: C.Config.options.bar.workspaces.shown
    readonly property int group: Math.floor((activeWorkspace - 1) / shownCount)
    readonly property var specialWorkspace: liveMonitorData?.specialWorkspace
    readonly property string specialWorkspaceName: specialWorkspace?.name ? specialWorkspace.name.replace("special:", "") : ""
    readonly property bool specialWorkspaceActive: specialWorkspaceName !== ""
    property list<bool> occupied: []
    property list<var> biggestWindow: occupied.map((_, index) => {
        const wsId = getWorkspaceIdAt(index);
        return Kwin.biggestWindowForWorkspace(wsId);
    })

    function getWorkspaceId(group, index) {
        return group * root.shownCount + index + 1;
    }

    function getWorkspaceIdAt(index) {
        return root.getWorkspaceId(root.group, index);
    }

    function updateWorkspaceOccupied() {
        root.occupied = Array.from({
            length: root.shownCount
        }, (_, i) => {
            const thisWorkspaceId = getWorkspaceId(root.group, i);
            return (Kwin.workspaces || []).some(ws => ws.id === thisWorkspaceId);
        });
    }

    onGroupChanged: {
        updateWorkspaceOccupied();
    }

    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        function onWorkspacesChanged() {
            root.updateWorkspaceOccupied();
        }

        function onActiveWsIdChanged() {
            root.updateWorkspaceOccupied();
        }

        target: Kwin
    }
}
