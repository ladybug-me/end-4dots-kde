pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property int currentIndex: 0
    required property var tabButtonList

    signal tabClicked(int index)

    function incrementCurrentIndex(): void {
        if (root.tabButtonList && root.tabButtonList.length > 0) {
            root.setCurrentIndex((root.currentIndex + 1) % root.tabButtonList.length);
        }
    }

    function decrementCurrentIndex(): void {
        if (root.tabButtonList && root.tabButtonList.length > 0) {
            root.setCurrentIndex((root.currentIndex - 1 + root.tabButtonList.length) % root.tabButtonList.length);
        }
    }

    function setCurrentIndex(index: int): void {
        if (root.currentIndex !== index) {
            root.currentIndex = index;
        }
        root.tabClicked(index);
    }

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    implicitWidth: contentItem.implicitWidth
    implicitHeight: 40

    Row {
        id: contentItem

        z: 1
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.tabButtonList

            delegate: Rectangle {
                id: tabBtn

                required property int index
                readonly property var tabInfo: root.tabButtonList[tabBtn.index]
                property bool current: tabBtn.index === root.currentIndex

                implicitHeight: 36
                implicitWidth: contentRow.implicitWidth + 32
                radius: height / 2

                color: tabBtn.current ? Appearance.m3colors.m3secondaryContainer : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.setCurrentIndex(tabBtn.index);
                    }
                }

                RowLayout {
                    id: contentRow

                    anchors.centerIn: parent
                    spacing: 8

                    MaterialSymbol {
                        text: tabBtn.tabInfo?.icon ?? ""
                        iconSize: 18
                        color: tabBtn.current ? Appearance.m3colors.m3onSecondaryContainer : Appearance.m3colors.m3onSurface
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        text: tabBtn.tabInfo?.name ?? ""
                        color: tabBtn.current ? Appearance.m3colors.m3onSecondaryContainer : Appearance.m3colors.m3onSurface
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
