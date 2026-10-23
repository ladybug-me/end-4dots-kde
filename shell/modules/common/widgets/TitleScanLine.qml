import QtQuick
import qs.modules.common

Item {
    id: root
    property real position: 0
    property real segmentRatio: 0.35
    property color color: Appearance.colors.colPrimary

    height: 2
    clip: true

    Rectangle {
        width: root.width * root.segmentRatio
        height: root.height
        radius: root.height / 2
        x: root.position * (root.width - width)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: root.color }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
