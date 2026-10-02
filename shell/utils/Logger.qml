pragma Singleton

import QtQuick
import Caelestia.Config

QtObject {
    id: root

    property bool enabled: GlobalConfig.general.debugLogs

    function log(...args): void {
        if (root.enabled) {
            console.log(...args);
        }
    }
}
