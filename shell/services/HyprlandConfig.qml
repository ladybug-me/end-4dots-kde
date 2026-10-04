pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    signal configChanged(string key, var value)

    function get(key: string, callback: var): void {
        if (callback)
            callback("");
    }

    function set(key: string, value: var): void {}

    function setMany(dict: var): void {}

    function reset(key: string): void {}

    function resetMany(keys: var): void {}
}
