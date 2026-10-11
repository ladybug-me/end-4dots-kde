pragma ComponentBehavior: Bound

import ".."
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property var action
    property var selectionMode
    property bool active: false

    visible: opacity > 0
    opacity: active ? 1.0 : 0.0

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: root.active ? 150 : 0 }
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    property string description: switch (root.action) {
    case ScreenshotAction.SnipAction.Copy:
    case ScreenshotAction.SnipAction.Edit:
        return Translation.tr("Copy region (LMB) or annotate (RMB)");
    case ScreenshotAction.SnipAction.Search:
        return Translation.tr("Search with Google Lens");
    case ScreenshotAction.SnipAction.CharRecognition:
        return Translation.tr("Recognize text");
    case ScreenshotAction.SnipAction.Record:
    case ScreenshotAction.SnipAction.RecordWithSound:
        return Translation.tr("Record region");
    default:
        return "";
    }

    property string materialSymbol: switch (root.action) {
    case ScreenshotAction.SnipAction.Copy:
    case ScreenshotAction.SnipAction.Edit:
        return "content_cut";
    case ScreenshotAction.SnipAction.Search:
        return "image_search";
    case ScreenshotAction.SnipAction.CharRecognition:
        return "document_scanner";
    case ScreenshotAction.SnipAction.Record:
    case ScreenshotAction.SnipAction.RecordWithSound:
        return "videocam";
    default:
        return "";
    }

    property bool showDescription: true

    property int margins: 8

    implicitWidth: content.implicitWidth + margins * 2
    implicitHeight: content.implicitHeight + margins * 2

    Rectangle {
        id: content

        anchors.left: parent.left
        anchors.leftMargin: root.margins
        anchors.verticalCenter: parent.verticalCenter

        property real padding: 8
        implicitHeight: 38
        implicitWidth: root.showDescription ? contentRow.implicitWidth + padding * 2 : implicitHeight
        width: root.active ? implicitWidth : implicitHeight

        Behavior on width {
            SequentialAnimation {
                PauseAnimation { duration: root.active ? 150 : 0 }
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        clip: true
        topLeftRadius: 6
        bottomLeftRadius: implicitHeight - topLeftRadius
        bottomRightRadius: bottomLeftRadius
        topRightRadius: bottomLeftRadius

        color: Appearance.m3colors.m3surfaceContainerHigh
        border.width: 1
        border.color: Appearance.m3colors.m3outlineVariant

        Row {
            id: contentRow

            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: content.padding
            }
            spacing: 12

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 22
                color: Appearance.m3colors.m3onSurface
                text: root.materialSymbol
            }

            StyledText {
                id: descriptionText

                anchors.verticalCenter: parent.verticalCenter
                color: Appearance.m3colors.m3onSurface
                text: root.description
            }
        }
    }
}
