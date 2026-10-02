pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Appearance")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        SectionHeader {
            first: true
            text: qsTr("Wallpaper")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                icon: "wallpaper"
                label: qsTr("Wallpapers")
                status: qsTr("Browse and select wallpapers")
                onClicked: root.nState.openSubPage(1)
            }

            NavRow {
                icon: "image_search"
                label: qsTr("Wallhaven")
                status: qsTr("Download wallpapers from Wallhaven")
                onClicked: root.nState.openSubPage(4)
            }

            NavRow {
                last: true
                icon: "folder_open"
                label: qsTr("Open wallpaper folder")
                status: qsTr("Add your own wallpapers")
                onClicked: Quickshell.execDetached(["xdg-open", Paths.wallsdir])
            }
        }

        SectionHeader {
            text: qsTr("Lock screen")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                last: true
                icon: "lock"
                label: qsTr("Lock screen")
                status: qsTr("Wallpaper sync and lock screen settings")
                onClicked: root.nState.openSubPage(9)
            }
        }

        SectionHeader {
            text: qsTr("Colors")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                icon: "palette"
                label: qsTr("Colors")
                status: qsTr("Dynamic, light and dark palettes")
                onClicked: root.nState.openSubPage(3)
            }

            NavRow {
                last: true
                icon: "style"
                label: qsTr("Theme & Effects")
                status: qsTr("Islands, Pitch Black, Transparency")
                onClicked: root.nState.openSubPage(8)
            }
        }

        SectionHeader {
            text: qsTr("Wallpaper options")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                icon: "settings_suggest"
                label: qsTr("Wallpaper Settings")
                status: qsTr("Display, Recolor, Desktop Icons")
                onClicked: root.nState.openSubPage(5)
            }

            NavRow {
                icon: "slideshow"
                label: qsTr("Slideshow & Order")
                status: qsTr("Slideshow interval and randomization")
                onClicked: root.nState.openSubPage(6)
            }

            NavRow {
                last: true
                icon: "movie"
                label: qsTr("Video Wallpapers")
                status: qsTr("Audio and pausing behavior")
                onClicked: root.nState.openSubPage(7)
            }
        }
    }
}
