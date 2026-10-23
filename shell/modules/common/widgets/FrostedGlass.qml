import QtQuick
import qs.modules.common

Item {
    id: root
    required property Item blurSource
    property real cardRadius: 30
    property real topLeftRadius: cardRadius
    property real topRightRadius: cardRadius
    property real bottomRightRadius: cardRadius
    property real bottomLeftRadius: cardRadius
    property color tint: "white"
    property real tintOpacity: 0.3
    readonly property real rimWidth: 4
    readonly property real pull: 0
    readonly property real split: 0
    readonly property real haze: 6
    readonly property real vividness: 1.25
    readonly property real sheen: 0.31
    property real trackX: 0
    property real trackY: 0

    ShaderEffectSource {
        id: capture
        sourceItem: root.blurSource
        sourceRect: {
            var _fx = root.trackX
            var _fy = root.trackY
            if (!root.blurSource) return Qt.rect(0, 0, 0, 0)
            var pt = root.mapToItem(root.blurSource, 0, 0)
            return Qt.rect(pt.x, pt.y, root.width, root.height)
        }
        mipmap: true
        hideSource: false
        live: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.blurSource !== null && root.width > 0 && root.height > 0

        property var backdrop: capture
        property vector2d size: Qt.vector2d(width, height)
        property vector4d radii: Qt.vector4d(root.topLeftRadius, root.topRightRadius, root.bottomRightRadius, root.bottomLeftRadius)
        property real rimWidth: root.rimWidth
        property real pull: root.pull
        property real split: root.split
        property real haze: root.haze
        property real vividness: root.vividness
        property real sheen: root.sheen
        property color wash: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.tintOpacity)

        fragmentShader: Qt.resolvedUrl("shaders/frostedLens.frag.qsb")
    }
}
