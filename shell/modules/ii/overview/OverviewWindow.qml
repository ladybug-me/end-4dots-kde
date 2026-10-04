pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.components.images
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
    id: root

    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property bool restrictToWorkspace: true
    property real widthRatio: {
        const widgetWidth = ((widgetMonitor?.transform ?? 0) & 1) ? (widgetMonitor?.height ?? 1080) : (widgetMonitor?.width ?? 1920);
        const monitorWidth = ((monitorData?.transform ?? 0) & 1) ? (monitorData?.height ?? 1080) : (monitorData?.width ?? 1920);
        return ((widgetWidth || 1920) * (monitorData?.scale ?? 1)) / ((monitorWidth || 1920) * (widgetMonitor?.scale ?? 1));
    }
    property real heightRatio: {
        const widgetHeight = ((widgetMonitor?.transform ?? 0) & 1) ? (widgetMonitor?.width ?? 1920) : (widgetMonitor?.height ?? 1080);
        const monitorHeight = ((monitorData?.transform ?? 0) & 1) ? (monitorData?.width ?? 1920) : (monitorData?.height ?? 1080);
        return ((widgetHeight || 1080) * (monitorData?.scale ?? 1)) / ((monitorHeight || 1080) * (widgetMonitor?.scale ?? 1));
    }
    property real initX: {
        const winX = windowData?.x ?? windowData?.at?.[0] ?? 0;
        const res0 = monitorData?.reserved?.[0] ?? 0;
        return Math.max((winX - (monitorData?.x ?? 0) - res0) * widthRatio * root.scale, 0) + xOffset;
    }
    property real initY: {
        const winY = windowData?.y ?? windowData?.at?.[1] ?? 0;
        const res1 = monitorData?.reserved?.[1] ?? 0;
        return Math.max((winY - (monitorData?.y ?? 0) - res1) * heightRatio * root.scale, 0) + yOffset;
    }
    property real xOffset: 0
    property real yOffset: 0
    property var widgetMonitor
    property int widgetMonitorId: widgetMonitor?.id ?? 0
    property var targetWindowWidth: (windowData?.width ?? windowData?.size?.[0] ?? 0) * scale * widthRatio
    property var targetWindowHeight: (windowData?.height ?? windowData?.size?.[1] ?? 0) * scale * heightRatio
    property bool hovered: false
    property bool pressed: false
    property bool centerIcons: Config.options.overview.centerIcons
    property real iconGapRatio: 0.06
    property real iconToWindowRatio: centerIcons ? 0.35 : 0.15
    property real xwaylandIndicatorToIconRatio: 0.35
    property real iconToWindowRatioCompact: 0.6
    property string iconPath: WinIcons.sourceForClient(windowData)
    property bool compactMode: Appearance.font.pixelSize.smaller * 4 > targetWindowHeight || Appearance.font.pixelSize.smaller * 4 > targetWindowWidth
    property bool indicateXWayland: windowData?.xwayland ?? false
    property real topLeftRadius
    property real topRightRadius
    property real bottomLeftRadius
    property real bottomRightRadius

    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    opacity: (windowData?.monitor ?? 0) == widgetMonitorId ? 1 : 0.4

    Component.onCompleted: {
        if (windowData) {
            WinIcons.request(windowData.class || "", windowData.title || "", windowData.pid ?? 0, windowData.address ? String(windowData.address) : "");
        }
    }

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomRightRadius: root.bottomRightRadius
            bottomLeftRadius: root.bottomLeftRadius
        }
    }

    Behavior on x {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    Behavior on y {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    Behavior on width {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    Behavior on height {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    WindowPreview {
        id: windowPreview

        anchors.fill: parent
        active: GlobalStates.overviewOpen
        address: windowData?.address ? String(windowData.address) : ""
        fallbackIcon: root.iconPath
        sourceAspect: (root.targetWindowWidth > 0 && root.targetWindowHeight > 0) ? (root.targetWindowWidth / root.targetWindowHeight) : (16 / 9)
    }

    Rectangle {
        anchors.fill: parent
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomRightRadius: root.bottomRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        color: pressed ? ColorUtils.transparentize(Appearance.colors.colLayer2Active, 0.5) : 
            hovered ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.7) : 
            ColorUtils.transparentize(Appearance.colors.colLayer2)
        border.color: ColorUtils.transparentize(Appearance.m3colors.m3outline, 0.88)
        border.width: 1
    }

    StyledImage {
        id: windowIcon

        property real baseSize: Math.min(root.targetWindowWidth, root.targetWindowHeight)
        property var iconSize: baseSize * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio)

        anchors {
            top: root.centerIcons ? undefined : parent.top
            left: root.centerIcons ? undefined : parent.left
            centerIn: root.centerIcons ? parent : undefined
            margins: baseSize * root.iconGapRatio
        }
        mipmap: true
        Layout.alignment: Qt.AlignHCenter
        source: root.iconPath
        width: iconSize
        height: iconSize

        Behavior on width {
            animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
        }

        Behavior on height {
            animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
        }
    }
}
