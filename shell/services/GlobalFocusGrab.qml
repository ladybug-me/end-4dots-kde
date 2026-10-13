pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property list<var> persistent: []
    property list<var> dismissable: []
    readonly property bool hasDismissables: root.dismissable.length > 0
    property bool _wasActive: false

    signal dismissed

    function dismiss(): void {
        root.dismissable = [];
        root.dismissed();
    }

    function addPersistent(window: var): void {
        if (!window)
            return;
        const list = root.persistent.slice();
        if (list.indexOf(window) === -1) {
            list.push(window);
            root.persistent = list;
        }
    }

    function removePersistent(window: var): void {
        if (!window)
            return;
        const list = root.persistent.slice();
        const index = list.indexOf(window);
        if (index !== -1) {
            list.splice(index, 1);
            root.persistent = list;
        }
    }

    function addDismissable(window: var): void {
        if (!window)
            return;
        const list = root.dismissable.slice();
        if (list.indexOf(window) === -1) {
            list.push(window);
            root.dismissable = list;
        }
    }

    function removeDismissable(window: var): void {
        if (!window)
            return;
        const list = root.dismissable.slice();
        const index = list.indexOf(window);
        if (index !== -1) {
            list.splice(index, 1);
            root.dismissable = list;
        }
    }

    function hasActive(element: var): bool {
        if (!element)
            return false;
        if (element.activeFocus)
            return true;
        const children = element.children;
        if (!children)
            return false;
        for (let i = 0; i < children.length; i++) {
            if (root.hasActive(children[i]))
                return true;
        }
        return false;
    }

    Timer {
        id: kdeFocusGrab

        interval: 100
        repeat: true
        running: root.hasDismissables

        onRunningChanged: {
            if (!running)
                root._wasActive = false;
        }

        onTriggered: {
            let anyActive = false;
            for (let i = 0; i < root.dismissable.length; i++) {
                const w = root.dismissable[i];
                if (w && (w.active || w.activeFocusItem || root.hasActive(w.contentItem))) {
                    anyActive = true;
                    break;
                }
            }

            if (anyActive) {
                root._wasActive = true;
            } else if (root._wasActive && !anyActive) {
                root._wasActive = false;
                root.dismiss();
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: scrimWindow
            required property ShellScreen modelData
            screen: modelData

            visible: root.hasDismissables
            color: "transparent"

            WlrLayershell.namespace: "quickshell:focus-scrim"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: false
                cursorShape: Qt.ArrowCursor
                onPressed: {
                    root.dismiss();
                }
            }
        }
    }
}
