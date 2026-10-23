pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services

Scope {
    id: root

    property var windowList: Kwin.windowList.map(normalizeWindow)
    property var workspaces: Kwin.workspaces
    property var workspaceById: Kwin.workspaceById
    property var activeWorkspace: Kwin.activeWorkspace
    property var monitors: Quickshell.screens
    property var focusedMonitor: Kwin.focusedMonitor

    function switchWorkspaceRelative(direction) {
        const delta = direction === "next" ? 1 : -1;
        const current = Kwin.activeWsId;
        const list = Kwin.workspaceIds;
        if (!list || list.length === 0) return;
        const idx = list.indexOf(current);
        const nextIdx = (idx + delta + list.length) % list.length;
        Kwin.switchWorkspace(list[nextIdx]);
    }

    function normalizeWindow(w) {
        if (!w) return null;
        return {
            id: w.address,
            address: w.address,
            title: w.title,
            appId: w.class || w.appId || "",
            workspaceId: w.workspaceId ?? w.workspace?.id ?? -1,
            focused: w.address === Kwin.activeWindow?.address
        };
    }

    function focusWindow(id) {
        Kwin.focusWindow(id);
    }

    function closeWindow(id) {
        Kwin.closeWindow(id);
    }

    function switchWorkspace(id) {
        Kwin.switchWorkspace(id);
    }

    function moveWindowToWorkspace(id, wsId) {
        Kwin.moveWindowToWorkspace(id, wsId);
    }

    function monitorFor(screen) {
        return Kwin.monitorFor(screen);
    }

    function activeWorkspaceForMonitor(monitorName) {
        const wsId = Kwin.activeByOutput[monitorName] ?? Kwin.activeWsId;
        return { id: wsId };
    }

    function biggestWindowForWorkspace(wsId) {
        return Kwin.biggestWindowForWorkspace ? Kwin.biggestWindowForWorkspace(wsId) : null;
    }

    function fullscreenOnMonitor(monitorName) {
        return Kwin.fullscreenOnMonitor(monitorName);
    }

    function monitorGeometry(screen) {
        if (!screen) return { x: 0, y: 0, scale: 1 };
        return { x: screen.x || 0, y: screen.y || 0, scale: screen.scale || 1 };
    }

    Connections {
        target: Kwin
        function onWindowListChanged() { root.windowList = Kwin.windowList.map(root.normalizeWindow); }
        function onWorkspacesChanged() { root.workspaces = Kwin.workspaces; }
        function onActiveWsIdChanged() { root.activeWorkspace = Kwin.activeWorkspace; }
    }
}
