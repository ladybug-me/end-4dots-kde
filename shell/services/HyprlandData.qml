pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property alias windowList: Kwin.windowList
    readonly property alias addresses: Kwin.addresses
    readonly property alias windowByAddress: Kwin.windowByAddress
    readonly property alias workspaces: Kwin.workspaces
    readonly property alias workspaceIds: Kwin.workspaceIds
    readonly property alias workspaceById: Kwin.workspaceById
    readonly property alias activeWorkspace: Kwin.activeWorkspace
    readonly property alias monitors: Kwin.monitors
    readonly property alias layers: Kwin.layers

    function toplevelsForWorkspace(workspace: var): var {
        return Kwin.toplevelsForWorkspace(workspace);
    }

    function hyprlandClientsForWorkspace(workspace: var): var {
        return Kwin.hyprlandClientsForWorkspace(workspace);
    }

    function clientForToplevel(toplevel: var): var {
        return Kwin.clientForToplevel(toplevel);
    }

    function biggestWindowForWorkspace(workspaceId: var): var {
        return Kwin.biggestWindowForWorkspace(workspaceId);
    }

    function updateWindowList(): void {
        Kwin.updateWindowList();
    }

    function updateLayers(): void {}

    function updateMonitors(): void {}

    function updateWorkspaces(): void {}

    function updateAll(): void {
        Kwin.updateAll();
    }
}
