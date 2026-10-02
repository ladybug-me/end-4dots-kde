import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Notifications")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Delivery")
        }

        NavRow {
            first: true
            icon: "notifications"
            label: qsTr("Notifications")
            status: qsTr("Position, timeout, and display behavior")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            last: true
            icon: "campaign"
            label: qsTr("Toasts")
            status: qsTr("Fullscreen behavior, appearance, and sound")
            onClicked: root.nState.openSubPage(2)
        }

        SectionHeader {
            text: qsTr("Automation")
        }

        NavRow {
            first: true
            last: true
            icon: "tune"
            label: qsTr("Toast events")
            status: qsTr("Choose which system changes show a toast")
            onClicked: root.nState.openSubPage(3)
        }
    }
}
