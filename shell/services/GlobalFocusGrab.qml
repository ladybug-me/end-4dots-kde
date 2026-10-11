pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property list<var> persistent: []
    property list<var> dismissable: []
    property bool _wasActive: false

    signal dismissed

    function dismiss(): void {
        root.dismissable = [];
        root.dismissed();
    }

    function addPersistent(window: var): void {
        if (window && root.persistent.indexOf(window) === -1)
            root.persistent.push(window);
    }

    function removePersistent(window: var): void {
        const index = root.persistent.indexOf(window);
        if (index !== -1)
            root.persistent.splice(index, 1);
    }

    function addDismissable(window: var): void {
        if (window && root.dismissable.indexOf(window) === -1)
            root.dismissable.push(window);
    }

    function removeDismissable(window: var): void {
        const index = root.dismissable.indexOf(window);
        if (index !== -1)
            root.dismissable.splice(index, 1);
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
        running: root.dismissable.length > 0

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
}
