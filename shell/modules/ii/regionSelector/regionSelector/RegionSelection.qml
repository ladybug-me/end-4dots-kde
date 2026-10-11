pragma ComponentBehavior: Bound

import ".."
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

PanelWindow {
    id: root

    visible: false
    color: "transparent"
    WlrLayershell.namespace: "osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    enum SelectionMode { RectCorners, Circle }

    enum Phase { Select, Post }

    property var action: ScreenshotAction.SnipAction.Copy

    property var selectionMode: RegionSelection.SelectionMode.RectCorners

    property var phase: RegionSelection.Phase.Select

    signal dismiss()

    onDismiss: {
        root.snapshotWorkspaceId = 0;
        root.snapshotWorkspaceUuid = "";
        root.lastHoverFocusedAddress = "";
    }

    property string screenshotDir: Directories.screenshotTemp

    property color overlayColor: Qt.rgba(0, 0, 0, 0.6)

    property color brightSecondary: Appearance.m3colors.m3secondary

    property color selectionBorderColor: brightSecondary

    property color selectionFillColor: "#33ffffff"

    property color windowBorderColor: brightSecondary

    property color windowFillColor: Qt.rgba(windowBorderColor.r, windowBorderColor.g, windowBorderColor.b, 0.15)

    property color onBorderColor: "#ff000000"

    property real targetRegionOpacity: 0.6

    property int snapshotWorkspaceId: 0
    property string snapshotWorkspaceUuid: ""

    readonly property var windows: {
        const useSnapshot = root.snapshotWorkspaceId > 0 || root.snapshotWorkspaceUuid !== "";
        const target = useSnapshot
            ? (root.snapshotWorkspaceUuid !== "" ? root.snapshotWorkspaceUuid : root.snapshotWorkspaceId)
            : Kwin.activeWsId;

        const arr = Array.from(Kwin.windowsForWorkspace(target));

        return arr.sort((a, b) => {
            if (a.floating === b.floating) return 0;
            return a.floating ? -1 : 1;
        });
    }

    readonly property real monitorScale: (frozenImage.sourceSize.width > 0 && root.screen.width > 0) ? (frozenImage.sourceSize.width / root.screen.width) : (screen.devicePixelRatio || 1.0)

    readonly property real monitorOffsetX: screen.x || 0

    readonly property real monitorOffsetY: screen.y || 0

    property string activeWorkspaceId: ""

    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}.png`

    property real dragStartX: 0

    property real dragStartY: 0

    property real draggingX: 0

    property real draggingY: 0

    property real dragDiffX: 0

    property real dragDiffY: 0

    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)

    property bool dragging: false

    property var points: []

    property var mouseButton: null

    readonly property var windowRegions: RegionFunctions.filterWindowRegionsByLayers(
        root.windows,
        []
    ).map(window => {
        return {
            at: [window.x - root.monitorOffsetX, window.y - root.monitorOffsetY],
            size: [window.width, window.height],
            class: window.class,
            title: window.title,
            address: window.address || "",
        }
    })

    property bool isCircleSelection: (root.selectionMode === RegionSelection.SelectionMode.Circle)

    property bool showWindowOutlines: false

    property bool enableWindowRegions: showWindowOutlines && !isCircleSelection

    property real targetedRegionX: -1

    property real targetedRegionY: -1

    property real targetedRegionWidth: 0

    property real targetedRegionHeight: 0

    property string targetedWindowAddress: ""

    property string lastHoverFocusedAddress: ""

    Timer {
        id: focusHoverTimer

        interval: 120
        repeat: false
        onTriggered: {
            if (root.showWindowOutlines && root.targetedWindowAddress
                    && root.targetedWindowAddress !== root.lastHoverFocusedAddress) {
                const stillVisible = root.windowRegions.some(
                    r => r.address === root.targetedWindowAddress
                );
                if (stillVisible) {
                    Kwin.focusWindow(root.targetedWindowAddress);
                    root.lastHoverFocusedAddress = root.targetedWindowAddress;
                }
            }
        }
    }

    function targetedRegionValid() {
        return (root.targetedRegionX >= 0 && root.targetedRegionY >= 0)
    }

    function setRegionToTargeted() {
        const padding = 0;
        root.regionX = root.targetedRegionX - padding;
        root.regionY = root.targetedRegionY - padding;
        root.regionWidth = root.targetedRegionWidth + padding * 2;
        root.regionHeight = root.targetedRegionHeight + padding * 2;
    }

    function updateTargetedRegion(x, y) {
        let clickedWindow = null;
        let smallestArea = Infinity;
        for (const region of root.windowRegions) {
            if (region.at[0] <= x && x <= region.at[0] + region.size[0]
                    && region.at[1] <= y && y <= region.at[1] + region.size[1]) {
                const area = region.size[0] * region.size[1];
                if (area < smallestArea) {
                    smallestArea = area;
                    clickedWindow = region;
                }
            }
        }
        if (clickedWindow) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
            const newAddr = clickedWindow.address || "";
            if (root.showWindowOutlines && newAddr && newAddr !== root.targetedWindowAddress) {
                root.targetedWindowAddress = newAddr;
                focusHoverTimer.restart();
            } else {
                root.targetedWindowAddress = newAddr;
            }
            return;
        }

        root.targetedRegionX = -1;
        root.targetedRegionY = -1;
        root.targetedRegionWidth = 0;
        root.targetedRegionHeight = 0;
        root.targetedWindowAddress = "";
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)

    property real regionHeight: Math.abs(draggingY - dragStartY)

    property real regionX: Math.min(dragStartX, draggingX)

    property real regionY: Math.min(dragStartY, draggingY)

    TempScreenshotProcess {
        id: screenshotProc

        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = true;
        }
    }

    property bool isRecording: root.action === ScreenshotAction.SnipAction.Record || root.action === ScreenshotAction.SnipAction.RecordWithSound

    property bool recordingShouldStop: false

    Process {
        id: checkRecordingProc

        running: root.isRecording
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.recordingShouldStop = (exitCode === 0);
        }
    }

    property bool preparationDone: false

    property bool regionConfirmPending: false

    property string frozenImageSource: ""

    onPreparationDoneChanged: {
        if (!preparationDone) return;
        if (root.isRecording && root.recordingShouldStop) {
            Quickshell.execDetached([Directories.recordScriptPath]);
            root.dismiss();
            return;
        }
        root.frozenImageSource = "file://" + root.screenshotPath;
        const snapId = Kwin.activeWsId;
        root.snapshotWorkspaceId = snapId;
        const snapIdx = snapId > 0 ? snapId - 1 : 0;
        root.snapshotWorkspaceUuid = Kwin.workspaces[snapIdx]
            ? Kwin.workspaces[snapIdx].id : "";

        root.visible = true;
        mouseArea.forceActiveFocus();
    }

    property bool screenshotConsumed: false

    function snip() {
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            root.dismiss();
            return;
        }

        const screenWidth = root.screen.width;
        const screenHeight = root.screen.height;
        root.regionX = Math.max(0, Math.min(root.regionX, screenWidth - root.regionWidth));
        root.regionY = Math.max(0, Math.min(root.regionY, screenHeight - root.regionHeight));
        root.regionWidth = Math.max(0, Math.min(root.regionWidth, screenWidth - root.regionX));
        root.regionHeight = Math.max(0, Math.min(root.regionHeight, screenHeight - root.regionY));

        if (root.action === ScreenshotAction.SnipAction.Copy || root.action === ScreenshotAction.SnipAction.Edit) {
            root.action = root.mouseButton === Qt.RightButton ? ScreenshotAction.SnipAction.Edit : ScreenshotAction.SnipAction.Copy;
        }

        const defaultDir = `${Directories.pictures}/Screenshots`;
        const screenshotDir = defaultDir;
        root.screenshotConsumed = true;
        const command = ScreenshotAction.getCommand(
            root.regionX * root.monitorScale,
            root.regionY * root.monitorScale,
            root.regionWidth * root.monitorScale,
            root.regionHeight * root.monitorScale,
            root.screenshotPath,
            root.action,
            screenshotDir
        );
        Quickshell.execDetached(command);
        if (root.action === ScreenshotAction.SnipAction.Record || root.action === ScreenshotAction.SnipAction.RecordWithSound) {
            root.phase = RegionSelection.Phase.Post;
            root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        } else {
            root.dismiss();
        }
    }

    function snipWindow(windowAddress) {
        root.screenshotConsumed = true;

        const saveDir = `${Directories.pictures}/Screenshots`;
        let spectacleFlags = "-b -a -n";
        if (root.mouseButton === Qt.RightButton || root.action === ScreenshotAction.SnipAction.Edit) {
            spectacleFlags = "-b -a -n -e";
        }

        const tmpFile = `${Directories.screenshotTemp}/snip-window-${Date.now()}.png`;
        const actionScript = ScreenshotAction.getScript(
            0, 0, 99999, 99999, tmpFile, root.action, saveDir
        );

        const command = [
            "bash", "-c",
            `set -euo pipefail; ` +
            `spectacle ${spectacleFlags} -o '${tmpFile}' && ${actionScript}`
        ];

        if (windowAddress) {
            Kwin.focusWindow(windowAddress);
        }
        root.dismiss();
        Quickshell.execDetached(command);
    }

    mask: Region {
        item: switch (root.phase) {
        case RegionSelection.Phase.Select:
            return mouseArea;
        case RegionSelection.Phase.Post:
            return null;
        }
    }

    Image {
        id: frozenImage

        anchors.fill: parent
        source: root.frozenImageSource
        asynchronous: false
        fillMode: Image.Stretch
        cache: false
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        GlobalShortcut {
            name: "escape"
            description: "Dismiss region selector"
            onActivated: {
                if (root.regionConfirmPending) {
                    root.regionConfirmPending = false;
                    root.regionWidth = 0;
                    root.regionHeight = 0;
                } else {
                    root.dismiss();
                }
            }
        }

        GlobalShortcut {
            name: "enter"
            description: "Confirm region selection"
            onActivated: {
                if (root.regionConfirmPending) {
                    root.snip();
                }
            }
        }

        onPressed: (mouse) => {
            root.mouseButton = mouse.button;
            if (root.targetedRegionValid() && root.enableWindowRegions) {
                root.setRegionToTargeted();
                if (root.targetedWindowAddress) {
                    root.snipWindow(root.targetedWindowAddress);
                    return;
                }
                root.snip();
                return;
            }
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragDiffX = 0;
            root.dragDiffY = 0;
            root.dragging = true;
            root.points = [{ x: mouse.x, y: mouse.y }];
            cursorGuide.active = false;
        }

        onReleased: (mouse) => {
            root.dragging = false;
            if (root.selectionMode === RegionSelection.SelectionMode.Circle) {
                if (root.points.length < 3) return;
                let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                for (let i = 0; i < root.points.length; i++) {
                    const pt = root.points[i];
                    if (pt.x < minX) minX = pt.x;
                    if (pt.x > maxX) maxX = pt.x;
                    if (pt.y < minY) minY = pt.y;
                    if (pt.y > maxY) maxY = pt.y;
                }
                const padding = 0;
                root.regionX = minX - padding;
                root.regionY = minY - padding;
                root.regionWidth = maxX - minX + padding * 2;
                root.regionHeight = maxY - minY + padding * 2;
                root.snip();
                return;
            }

            if (root.regionWidth > 10 && root.regionHeight > 10) {
                root.regionConfirmPending = true;
            } else {
                cursorGuide.active = true;
            }
        }

        onPositionChanged: (mouse) => {
            root.updateTargetedRegion(mouse.x, mouse.y);
            if (!root.dragging) return;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragDiffX = mouse.x - root.dragStartX;
            root.dragDiffY = mouse.y - root.dragStartY;
            root.points.push({ x: mouse.x, y: mouse.y });
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.RectCorners
            sourceComponent: RectCornersSelectionDetails {
                regionX: root.regionX
                regionY: root.regionY
                regionWidth: root.regionWidth
                regionHeight: root.regionHeight
                mouseX: mouseArea.mouseX
                mouseY: mouseArea.mouseY
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                breathingBorderOnly: root.phase === RegionSelection.Phase.Post
            }
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.Circle
            sourceComponent: CircleSelectionDetails {
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                points: root.points
            }
        }

        CursorGuide {
            id: cursorGuide

            z: 9999
            visible: root.phase === RegionSelection.Phase.Select
            x: root.dragging ? root.regionX + root.regionWidth : mouseArea.mouseX
            y: root.dragging ? root.regionY + root.regionHeight : mouseArea.mouseY
            action: root.action
            selectionMode: root.selectionMode
        }

        Repeater {
            model: root.phase === RegionSelection.Phase.Select && root.enableWindowRegions ? root.windowRegions : []

            delegate: TargetRegion {
                z: 2
                required property var modelData
                clientDimensions: modelData
                showIcon: true
                targeted: !root.draggedAway && (root.targetedRegionX === modelData.at[0] && root.targetedRegionY === modelData.at[1] && root.targetedRegionWidth === modelData.size[0] && root.targetedRegionHeight === modelData.size[1])
                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                text: `${modelData.class}`
                iconName: modelData.class
                radius: 4
            }
        }

        Row {
            id: regionSelectionControls

            z: 10
            visible: root.phase === RegionSelection.Phase.Select
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: -height
            }
            opacity: 0

            Connections {
                target: root

                function onVisibleChanged() {
                    if (!visible) return;
                    regionSelectionControls.anchors.bottomMargin = 8;
                    regionSelectionControls.opacity = 1;
                }
            }

            Behavior on opacity {
                animation: NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            Behavior on anchors.bottomMargin {
                animation: NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }

            spacing: 6

            OptionsToolbar {
                Synchronizer on action {
                    property alias source: root.action
                }
                Synchronizer on selectionMode {
                    property alias source: root.selectionMode
                }
                Synchronizer on showWindowOutlines {
                    property alias source: root.showWindowOutlines
                }

                onDismiss: root.dismiss();
            }

            ToolbarPairedFab {
                anchors.verticalCenter: parent.verticalCenter
                iconText: "fullscreen"
                onClicked: {
                    root.regionX = 0;
                    root.regionY = 0;
                    root.regionWidth = root.screen.width;
                    root.regionHeight = root.screen.height;
                    root.snip();
                }

                StyledToolTip {
                    text: Translation.tr("Full Screen Screenshot")
                }
            }

            ToolbarPairedFab {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.regionConfirmPending
                iconText: "check"
                onClicked: root.snip();

                StyledToolTip {
                    text: Translation.tr("Snip selected region (Enter)")
                }
            }

            ToolbarPairedFab {
                anchors.verticalCenter: parent.verticalCenter
                iconText: "close"
                onClicked: {
                    if (root.regionConfirmPending) {
                        root.regionConfirmPending = false;
                        root.regionWidth = 0;
                        root.regionHeight = 0;
                    } else {
                        root.dismiss();
                    }
                }

                StyledToolTip {
                    text: root.regionConfirmPending ? Translation.tr("Clear selection") : Translation.tr("Close")
                }
            }
        }
    }
}
