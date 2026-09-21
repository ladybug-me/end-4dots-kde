import QtQuick
import Quickshell.Wayland
import Quickshell.Wayland
import qs.services
import qs.modules.common as C

NestableObject {
    id: root

    required property var monitor
    readonly property var liveMonitorData: monitor
    readonly property var activeWindow: Kwin.activeWindow
    readonly property int activeWorkspace: Kwin.activeWsId
    readonly property bool currentWorkspaceNotFake: activeWindow?.focused ?? false // Active empty workspace = fake. At least, that's how I like to call it.
    readonly property int fakeWorkspace: currentWorkspaceNotFake ? -9999 : activeWorkspace
    readonly property int shownCount: C.Config.options.bar.workspaces.shown
    readonly property int group: Math.floor((activeWorkspace - 1) / shownCount)
    readonly property var specialWorkspace: null
    readonly property string specialWorkspaceName: ""
    readonly property bool specialWorkspaceActive: false

    property list<bool> occupied: []
    property list<var> biggestWindow: occupied.map((_, index) => {
        const wsId = getWorkspaceIdAt(index);
        var biggestWindow = Kwin.biggestWindowForWorkspace(wsId);
        return biggestWindow;
    })

    function getWorkspaceId(group, index) {
        return group * root.shownCount + index + 1;
    }
    function getWorkspaceIdAt(index) {
        return root.getWorkspaceId(root.group, index);
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        root.occupied = Array.from({
            length: root.shownCount
        }, (_, i) => {
            const thisWorkspaceId = getWorkspaceId(root.group, i);
            return Kwin.workspaces.some(ws => ws.id === thisWorkspaceId);
        });
    }

    // Occupied workspace updates
    Component.onCompleted: updateWorkspaceOccupied()
    Connections {
        target: Kwin
        function onWorkspacesChanged() {
            root.updateWorkspaceOccupied();
        }
        function onActiveWsIdChanged() {
            root.updateWorkspaceOccupied();
        }
    }
    onGroupChanged: {
        updateWorkspaceOccupied();
    }
}
