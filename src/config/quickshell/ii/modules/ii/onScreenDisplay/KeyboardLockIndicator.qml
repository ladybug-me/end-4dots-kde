import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string lockName
    required property string icon
    required property bool enabled

    implicitWidth: Appearance.sizes.osdWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: indicator.implicitHeight + 2 * Appearance.sizes.elevationMargin

    StyledRectangularShadow {
        target: indicator
    }

    Rectangle {
        id: indicator

        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }

        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0

        implicitWidth: content.implicitWidth + 40
        implicitHeight: content.implicitHeight + 20

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: 12

            MaterialSymbol {
                text: root.icon
                iconSize: 28
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                text: root.lockName
                color: Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                text: root.enabled ? "On" : "Off"
                color: Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
            }
        }
    }
}
