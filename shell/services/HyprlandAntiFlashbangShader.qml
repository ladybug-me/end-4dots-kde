pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string shaderPath: ""
    readonly property string weakShaderPath: ""
    property bool enabled: false
    property bool weak: false

    function enable(): void {}

    function enableWeak(): void {}

    function disable(): void {}

    function toggle(): void {}

    function cycle(): void {}
}
