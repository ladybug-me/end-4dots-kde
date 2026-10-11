import QtQuick
import Quickshell.Wayland
import qs.services
import qs.modules.common as C

NestableObject {
    id: root

    required property var monitor
    readonly property var liveMonitorData: (monitor && monitor.id !== undefined) ? (Kwin.monitors.find(m => m.id === monitor.id) || monitor) : (Kwin.focusedMonitor ?? null)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int activeWorkspace: {
        const activeWs = Kwin.activeWsId;
        const activeByOut = Kwin.activeByOutput;
        const perOutput = (monitor?.name && activeByOut) ? activeByOut[monitor.name] : 0;
        return perOutput > 0 ? perOutput : (activeWs > 0 ? activeWs : 1);
    }
    readonly property bool currentWorkspaceNotFake: activeWindow?.activated ?? false
    readonly property int fakeWorkspace: currentWorkspaceNotFake ? -9999 : activeWorkspace
    readonly property var specialWorkspace: liveMonitorData?.specialWorkspace
    readonly property string specialWorkspaceName: specialWorkspace?.name ? specialWorkspace.name.replace("special:", "") : ""
    readonly property bool specialWorkspaceActive: specialWorkspaceName !== ""
    readonly property int desktopCount: Math.max(1, (Kwin.workspaces || []).length)
    readonly property int shown: Math.max(1, C.Config.options.bar.workspaces.shown)
    readonly property bool showUnoccupied: C.Config.options.bar.workspaces.showUnoccupied ?? true
    readonly property var occupiedMap: {
        const occ = {};
        for (let i = 1; i <= root.desktopCount; ++i) {
            occ[i] = false;
        }
        const kwinList = Kwin.windowList;
        if (kwinList) {
            for (let i = 0; i < kwinList.length; ++i) {
                const w = kwinList[i];
                if (C.Config.options.bar.workspaces.perMonitor && root.monitor?.name && w.output && w.output !== root.monitor.name)
                    continue;
                const wsId = w.workspace?.id ?? w.desktop;
                if (typeof wsId === "number") {
                    occ[wsId] = true;
                }
            }
        }
        return occ;
    }
    readonly property var wsIds: {
        if (root.showUnoccupied) {
            const ids = [];
            const start = Math.floor((root.activeWorkspace - 1) / root.shown) * root.shown;
            for (let i = 0; i < root.shown; ++i) {
                const id = start + i + 1;
                if (id <= root.desktopCount)
                    ids.push(id);
            }
            return ids;
        }
        const ids = [];
        for (let id = 1; id <= root.desktopCount; ++id) {
            if (root.occupiedMap[id] || id === root.activeWorkspace)
                ids.push(id);
        }
        const currentIdx = ids.indexOf(root.activeWorkspace);
        if (currentIdx < 0)
            return [];
        const end = Math.max(currentIdx + 1, Math.min(root.shown, ids.length));
        return ids.slice(Math.max(0, end - root.shown), end);
    }
    readonly property int count: root.wsIds.length
    readonly property int shownCount: root.count
    readonly property int workspaceIndexInGroup: {
        const idx = root.wsIds.indexOf(root.activeWorkspace);
        return idx >= 0 ? idx : 0;
    }
    readonly property list<bool> occupied: root.wsIds.map(id => !!root.occupiedMap[id])
    readonly property list<var> biggestWindow: root.wsIds.map(id => Kwin.biggestWindowForWorkspace(id))

    function getWorkspaceId(group, index) {
        return root.getWorkspaceIdAt(index);
    }

    function getWorkspaceIdAt(index) {
        return root.wsIds[index] ?? (index + 1);
    }

    Connections {
        function onWorkspacesChanged() {
            Kwin.refreshWindows();
        }

        target: Kwin
    }
}
