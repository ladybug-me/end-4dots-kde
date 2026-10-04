pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property list<var> persistent: []
    property list<var> dismissable: []

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
}
