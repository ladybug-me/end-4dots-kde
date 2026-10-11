pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Services as Caelestia

Loader {
    id: root

    property string name: ""
    property string description: ""
    property string key: ""
    property bool enabled: true

    signal pressed()
    signal released()
    signal activated()

    active: root.enabled
    sourceComponent: kdeShortcut

    Component {
        id: kdeShortcut

        Caelestia.GlobalShortcut {
            name: root.name
            key: root.key
            description: root.description

            onActivated: {
                root.activated();
                root.pressed();
                root.released();
            }
        }
    }
}
