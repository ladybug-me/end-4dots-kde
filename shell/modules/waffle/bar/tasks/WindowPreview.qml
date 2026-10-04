import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.components.images
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.bar
import qs.modules.waffle.looks

Button {
    id: root

    required property var toplevel
    property real previewWidthConstraint: 200
    property real previewHeightConstraint: 110
    padding: 5
    Layout.fillHeight: true

    onClicked: {
        root.toplevel.activate(); // TODO: make this work with those who disable focus on activate because telegram is abusive
    }

    background: Rectangle {
        id: background
        radius: Looks.radius.medium
        color: root.down ? Looks.colors.bg2Active : (root.hovered ? Looks.colors.bg2Hover : ColorUtils.transparentize(Looks.colors.bg2))
        Behavior on color {
            animation: Looks.transition.color.createObject(this)
        }
    }

    contentItem: ColumnLayout {
        id: contentItem
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: 8

            WAppIcon {
                id: appIcon
                Layout.leftMargin: Looks.radius.large - root.padding + 2
                Layout.alignment: Qt.AlignVCenter
                iconName: WinIcons.sourceFor(null, root.toplevel.appId, "", root.toplevel.pid ?? 0)
                implicitSize: 16
            }

            Item {
                id: appTitleContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: closeButton.implicitHeight // Enforce height, because closeButton doesn't contribute when it's invisible
                WText {
                    id: appTitleText
                    anchors.fill: parent
                    text: root.toplevel.title
                    elide: Text.ElideRight
                    font.pixelSize: Looks.font.pixelSize.large
                    font.weight: Looks.font.weight.thin
                    color: Looks.colors.fg1
                }
            }

            WindowCloseButton {
                id: closeButton
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Looks.radius.large - root.padding
            Layout.topMargin: 0
            implicitWidth: root.previewWidthConstraint
            implicitHeight: root.previewHeightConstraint

            WindowPreview {
                id: previewItem
                anchors.centerIn: parent
                width: root.previewWidthConstraint
                height: root.previewHeightConstraint
                address: root.toplevel.address ? String(root.toplevel.address) : ""
                fallbackIcon: WinIcons.sourceFor(null, root.toplevel.appId, "", root.toplevel.pid ?? 0)
                sourceAspect: root.previewWidthConstraint / root.previewHeightConstraint
            }
        }
    }

    component WindowCloseButton: CloseButton {
        visible: root.hovered
        Layout.leftMargin: 4
        implicitHeight: 30
        implicitWidth: 30
        radius: Looks.radius.large - root.padding
        onClicked: {
            root.toplevel.close();
        }
    }
}
