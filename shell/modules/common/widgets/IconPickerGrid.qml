import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt.labs.folderlistmodel
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Flow {
    id: root
    property string currentValue: ""
    property string customFolder: ""
    property bool colorize: true
    property color iconColor: Appearance.colors.colOnLayer0
    property real minCellSize: 44
    readonly property int columns: Math.max(1, Math.floor((width + spacing) / (minCellSize + spacing)))
    readonly property real cellSize: width > 0 ? (width + spacing) / columns - spacing : minCellSize
    signal selected(string name)

    Layout.fillWidth: true
    spacing: 6

    FolderListModel {
        id: folderModel
        folder: FileUtils.folderUrl(root.customFolder) || "file://" + Quickshell.shellPath("assets/icons")
        nameFilters: ["*.svg", "*.png"]
        showDirs: false
    }

    Repeater {
        model: folderModel
        delegate: Item {
            id: cell
            required property string fileName
            readonly property string iconName: fileName.replace(/\.(svg|png)$/, "")
            readonly property bool isSelected: root.currentValue === iconName
            implicitWidth: root.cellSize
            implicitHeight: root.cellSize

            Rectangle {
                anchors.fill: parent
                radius: cell.isSelected ? Appearance.rounding.normal : Appearance.rounding.small
                color: root.colorize
                    ? (cell.isSelected ? Appearance.colors.colSecondaryContainer : (mouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2))
                    : ColorUtils.transparentize(Appearance.colors.colPrimary, cell.isSelected ? 0.05 : (mouseArea.containsMouse ? 0.15 : 0.3))
                border.width: cell.isSelected ? 2 : 0
                border.color: Appearance.colors.colPrimary

                Behavior on radius {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            CustomIcon {
                anchors.centerIn: parent
                width: root.cellSize * 0.5
                height: root.cellSize * 0.5
                source: cell.fileName
                customFolder: root.customFolder
                colorize: root.colorize
                color: root.iconColor
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(cell.iconName)

                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: mouseArea.containsMouse
                    text: cell.iconName.replace("-symbolic", "")
                }
            }
        }
    }
}
