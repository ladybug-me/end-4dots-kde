pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

Item {
    id: root

    property string name: ""
    property string description: ""
    signal pressed()
    signal released()

    GlobalShortcut {
        name: root.name
        description: root.description
        onPressed: root.pressed()
        onReleased: root.released()
    }
}
