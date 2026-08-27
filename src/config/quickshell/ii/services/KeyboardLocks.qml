pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool capsLock: false
    property bool numLock: false
    property bool scrollLock: false

    property string ledBasePath: "/sys/class/leds/input3"

    function updateLocks() {
        capsLockFile.reload();
        numLockFile.reload();
        scrollLockFile.reload();
    }

    Timer {
        id: pollTimer

        interval: 100
        running: true
        repeat: true

        onTriggered: {
            root.updateLocks();
        }
    }

    FileView {
        id: capsLockFile

        path: root.ledBasePath + "::capslock/brightness"
        watchChanges: true

        onLoaded: {
            root.capsLock = text().trim() === "1";
        }

        onTextChanged: {
            root.capsLock = text().trim() === "1";
        }
    }

    FileView {
        id: numLockFile

        path: root.ledBasePath + "::numlock/brightness"
        watchChanges: true

        onLoaded: {
            root.numLock = text().trim() === "1";
        }

        onTextChanged: {
            root.numLock = text().trim() === "1";
        }
    }

    FileView {
        id: scrollLockFile

        path: root.ledBasePath + "::scrolllock/brightness"
        watchChanges: true

        onLoaded: {
            root.scrollLock = text().trim() === "1";
        }

        onTextChanged: {
            root.scrollLock = text().trim() === "1";
        }
    }
}
