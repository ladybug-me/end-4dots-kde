pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root
    property var windowData

    property bool hovered: false
    property bool pressed: false

    property string iconPath: Quickshell.iconPath(AppSearch.guessIcon(windowData?.class), "image-missing")

    width: 64
    height: 64

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: pressed ? ColorUtils.transparentize(Appearance.colors.colLayer2Active, 0.5) : 
               hovered ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.7) : 
               "transparent"
        border.color: hovered ? ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.5) : "transparent"
        border.width: 1
    }

    StyledImage {
        id: windowIcon
        anchors.centerIn: parent
        mipmap: true
        source: root.iconPath
        width: 48
        height: 48
    }
}
