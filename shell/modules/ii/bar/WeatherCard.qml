import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property alias title: title.text
    property alias value: value.text
    property alias symbol: symbolShape.text
    property var shape: MaterialShape.Shape.Cookie4Sided
    property color shapeColor: Appearance.colors.colSecondaryContainer
    property color symbolColor: Appearance.colors.colOnSecondaryContainer

    Layout.fillWidth: true
    implicitWidth: rowLayout.implicitWidth + 20
    implicitHeight: rowLayout.implicitHeight + 16
    radius: Appearance.rounding.normal
    color: Appearance.colors.colSurfaceContainerHigh

    RowLayout {
        id: rowLayout
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 12
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 10

        MaterialShapeWrappedMaterialSymbol {
            id: symbolShape
            shape: root.shape
            implicitSize: 36
            iconSize: Appearance.font.pixelSize.large
            fill: 1
            color: root.shapeColor
            colSymbol: root.symbolColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -2

            StyledText {
                id: value
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSurface
            }

            StyledText {
                id: title
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }
}
