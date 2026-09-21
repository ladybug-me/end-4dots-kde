pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Services

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root

    property var windowList: {
        return (KWinActiveWindowBridge.windowList || []).map(w => ({
            address: w.address,
            mapped: !w.minimized,
            hidden: w.minimized,
            at: [w.x, w.y],
            size: [w.width, w.height],
            workspace: { id: w.workspace?.id || -1, name: w.workspace?.uuid || "" },
            floating: w.floating,
            monitor: 0,
            class: w.class,
            title: w.title,
            initialClass: w.class,
            initialTitle: w.title,
            pid: w.pid,
            xwayland: false,
            pinned: w.workspace?.id === -1,
            fullscreen: w.fullscreen,
            fullscreenMode: 0,
            fakeFullscreen: false,
            // Extra properties to help mock Toplevel
            focused: w.focused
        }));
    }
    property var addresses: windowList.map(w => w.address)
    property var windowByAddress: {
        let map = {};
        for (let i = 0; i < windowList.length; i++) {
            map[windowList[i].address] = windowList[i];
        }
        return map;
    }
    
    property var workspaces: {
        return (KWinWorkspaceState.workspaces || []).map(ws => {
            return {
                id: ws.index,
                uuid: ws.id,
                name: ws.name,
                active: ws.active
            };
        });
    }
    property var workspaceIds: workspaces.map(ws => ws.id)
    property var workspaceById: {
        let map = {};
        for (let i = 0; i < workspaces.length; i++) {
            map[workspaces[i].id] = workspaces[i];
        }
        return map;
    }
    property var activeWorkspace: workspaceById[KWinWorkspaceState.activeId] || null
    property var monitors: []
    property var layers: ({})

    // Convenient stuff

    function toplevelsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace?.id === workspace).map(win => ({
            appId: win.class,
            title: win.title,
            address: win.address,
            activated: win.focused,
            activate: function() { KWinActiveWindowBridge.focusWindow(win.address); },
            close: function() { KWinActiveWindowBridge.closeWindow(win.address); },
            HyprlandToplevel: { address: win.address.replace("0x", "") }
        }));
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace?.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || (!toplevel.address && !toplevel.HyprlandToplevel)) {
            return null;
        }
        const address = toplevel.address || `0x${toplevel.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    // Internals
    // Functions kept for backward compatibility; the backend syncs automatically.
    function updateWindowList() {}
    function updateLayers() {}
    function updateMonitors() {}
    function updateWorkspaces() {}
    function updateAll() {}

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = root.windowList.filter(w => w.workspace?.id === workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
    }
}
