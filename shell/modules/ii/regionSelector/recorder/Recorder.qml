pragma ComponentBehavior: Bound

import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData

        screen: modelData
        property bool active: false

        visible: active
        color: "transparent"
        mask: Region {}

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            id: bg

            anchors.fill: parent
            color: Appearance.m3colors.m3scrim
            opacity: root.active ? 0.3 : 0

            MouseArea {
                anchors.fill: parent
                onClicked: root.active = false
            }

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            color: Appearance.m3colors.m3surface
            radius: Appearance.rounding.normal

            opacity: root.active ? 1 : 0
            scale: root.active ? 1 : 0.9

            implicitWidth: layout.implicitWidth + 32
            implicitHeight: layout.implicitHeight + 32

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            ColumnLayout {
                id: layout

                anchors.centerIn: parent
                spacing: 16

                Row {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    spacing: 16

                    BigRecorderButton {
                        materialSymbol: "screenshot_region"
                        name: Translation.tr("Screenshot region")
                        onClicked: {
                            root.active = false;
                            Quickshell.execDetached(["caelestia", "shell", "region", "screenshot"]);
                        }
                    }

                    BigRecorderButton {
                        materialSymbol: "photo_camera"
                        name: Translation.tr("Screenshot")
                        onClicked: {
                            root.active = false;
                            Quickshell.execDetached(["bash", "-c", "spectacle -b -n -m || import -window root /tmp/fullshot.png && wl-copy < /tmp/fullshot.png"]);
                        }
                    }

                    BigRecorderButton {
                        materialSymbol: "screen_record"
                        name: Translation.tr("Record region")
                        onClicked: {
                            root.active = false;
                            Quickshell.execDetached(["spectacle", "-R", "r"]);
                        }
                    }

                    BigRecorderButton {
                        materialSymbol: "capture"
                        name: Translation.tr("Record screen")
                        onClicked: {
                            root.active = false;
                            Quickshell.execDetached(["spectacle", "-R", "s"]);
                        }
                    }
                }
            }
        }

        component BigRecorderButton: Rectangle {
            id: bigButton

            required property string materialSymbol
            required property string name
            signal clicked()

            color: mouseArea.containsMouse ? Appearance.m3colors.m3surfaceContainerHighest : Appearance.m3colors.m3surfaceContainerHigh
            radius: width / 2
            implicitHeight: 66
            implicitWidth: 66

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 28
                color: Appearance.m3colors.m3onSurface
                text: bigButton.materialSymbol
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bigButton.clicked()
            }

            StyledToolTip {
                text: bigButton.name
            }
        }
    }
}
