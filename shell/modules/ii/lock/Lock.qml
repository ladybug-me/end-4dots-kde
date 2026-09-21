pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock
import QtQuick
import Quickshell
import Quickshell

LockScreen {
    id: root

    // Monitor name -> workspace id to restore on unlock (set when locking)
    property var savedWorkspaces: ({})

    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: {
            for (var j = 0; j < Quickshell.screens.length; ++j) {
                var monName = Quickshell.screens[j].name
                var wsId = root.savedWorkspaces[monName]
                if (wsId !== undefined) {
                    Kwin.switchToWorkspace(wsId, monName)
                }
            }
        }
    }

    lockSurface: LockSurface {
        context: root.context
    }

    // Single batch for lock and unlock so we don't race multiple hyprctl calls
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                // Lock: save workspace per monitor and move all to temp workspace in one batch
                var next = {}
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var mon = Quickshell.screens[i].name
                    var ws = Kwin.activeWorkspaceFor(mon)
                    if (ws === undefined || ws === null) {
                        return;
                    }
                    next[mon] = ws
                    Kwin.switchToWorkspace(2147483647 - ws, mon)
                }
                root.savedWorkspaces = next
            } else {
                restoreTimer.start()
            }
        }
    }

    // Push everything down (visual only; workspace switch is in Connections above)
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property ShellScreen modelData
            property bool shouldPush: GlobalStates.screenLocked
            property string targetMonitorName: modelData.name
            property int verticalMovementDistance: modelData.height
            property int horizontalSqueeze: modelData.width * 0.2
        }
    }
}
