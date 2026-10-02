pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Utilities")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Quick controls")
        }

        NavRow {
            first: true
            icon: "volume_up"
            label: qsTr("On-screen sliders")
            status: qsTr("Volume, microphone, brightness, and edge triggers")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "content_paste"
            label: qsTr("Clipboard")
            status: qsTr("History size")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            icon: "widgets"
            label: qsTr("Utilities panel")
            status: qsTr("Choose the cards shown in the panel")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            last: true
            icon: "toggle_on"
            label: qsTr("Quick toggles")
            status: qsTr("Choose the controls shown in Quick Toggles")
            onClicked: root.nState.openSubPage(6)
        }

        SectionHeader {
            text: qsTr("Performance")
        }

        NavRow {
            first: true
            last: true
            icon: "sports_esports"
            label: qsTr("Game mode")
            status: qsTr("Auto-enable rules and performance overrides")
            onClicked: root.nState.openSubPage(1)
        }
    }
}
