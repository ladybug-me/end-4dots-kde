import QtQuick
import qs.modules.common

Item {
    id: root

    property bool active: true
    property int animIndex: 0
    property real travelX: 0
    property real travelY: 0
    property int staggerMs: 45
    property real minScale: 0.25
    property bool fade: true
    readonly property real speed: Math.max(0.5, Config.options.settings.animationSpeed ?? 1)

    property real animScale: active ? 1 : minScale
    property real animOpacity: active || !fade ? 1 : 0
    property real offsetX: active ? 0 : travelX
    property real offsetY: active ? 0 : travelY

    transformOrigin: Item.Center
    scale: animScale
    opacity: animOpacity
    transform: Translate {
        x: root.offsetX
        y: root.offsetY
    }

    onActiveChanged: {
        if (!root.initialized) return
        if (root.active) {
            exitAnim.stop()
            enterAnim.restart()
        } else {
            enterAnim.stop()
            exitAnim.restart()
        }
    }

    property bool initialized: false
    Component.onCompleted: {
        root.initialized = true
        if (root.active) {
            root.animScale = root.minScale
            root.animOpacity = root.fade ? 0 : 1
            root.offsetX = root.travelX
            root.offsetY = root.travelY
            enterAnim.start()
        }
    }

    SequentialAnimation {
        id: enterAnim
        PauseAnimation { duration: root.animIndex * root.staggerMs }
        ParallelAnimation {
            SpringAnimation { target: root; property: "animScale"; to: 1; spring: 2.6 * root.speed; damping: 0.32 }
            SpringAnimation { target: root; property: "offsetX"; to: 0; spring: 2.6 * root.speed; damping: 0.32 }
            SpringAnimation { target: root; property: "offsetY"; to: 0; spring: 2.6 * root.speed; damping: 0.32 }
            NumberAnimation { target: root; property: "animOpacity"; to: 1; duration: 220 / root.speed; easing.type: Easing.OutQuad }
        }
    }

    SequentialAnimation {
        id: exitAnim
        PauseAnimation { duration: root.animIndex * (root.staggerMs - 4) }
        ParallelAnimation {
            NumberAnimation { target: root; property: "animScale"; to: root.minScale; duration: 260 / root.speed; easing.type: Easing.InBack }
            NumberAnimation { target: root; property: "offsetX"; to: root.travelX; duration: 280 / root.speed; easing.type: Easing.InQuad }
            NumberAnimation { target: root; property: "offsetY"; to: root.travelY; duration: 280 / root.speed; easing.type: Easing.InQuad }
            NumberAnimation { target: root; property: "animOpacity"; to: root.fade ? 0 : 1; duration: 220 / root.speed; easing.type: Easing.InQuad }
        }
    }
}
