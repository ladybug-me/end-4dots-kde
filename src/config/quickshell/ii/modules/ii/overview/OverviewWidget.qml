pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root
    required property var screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var toplevels: ToplevelManager.toplevels
    property int effectiveActiveWorkspaceId: 1
    
    Process {
        id: kwinDesktopPoller
        running: false
        command: ["qdbus6", "org.kde.KWin", "/KWin", "currentDesktop"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim());
                if (!isNaN(val)) effectiveActiveWorkspaceId = val;
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: kwinDesktopPoller.running = true
    }
    readonly property int workspacesShown: Config.options.overview.rows * Config.options.overview.columns
    readonly property int workspaceGroup: Math.floor((effectiveActiveWorkspaceId - 1) / workspacesShown)
    property var kwinWindows: overviewScope.kwinWindows

    property bool monitorIsFocused: true
    property var windows: root.kwinWindows
    property var windowByAddress: {
        var map = {};
        for (var i = 0; i < kwinWindows.length; ++i) {
            map[kwinWindows[i].internalId] = kwinWindows[i];
        }
        return map;
    }
    property var monitorData: { return {reserved: [0, 0, 0, 0], transform: 0}; }
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Appearance.colors.colSecondary

    property real workspaceImplicitWidth: (monitorData?.transform % 2 === 1) ? 
        ((screen.height - (monitorData?.reserved[0] ?? 0) - (monitorData?.reserved[2] ?? 0)) * root.scale / screen.devicePixelRatio) :
        ((screen.width - (monitorData?.reserved[0] ?? 0) - (monitorData?.reserved[2] ?? 0)) * root.scale / screen.devicePixelRatio)
    property real workspaceImplicitHeight: (monitorData?.transform % 2 === 1) ? 
        ((screen.width - (monitorData?.reserved[1] ?? 0) - (monitorData?.reserved[3] ?? 0)) * root.scale / screen.devicePixelRatio) :
        ((screen.height - (monitorData?.reserved[1] ?? 0) - (monitorData?.reserved[3] ?? 0)) * root.scale / screen.devicePixelRatio)
    property real largeWorkspaceRadius: Appearance.rounding.large
    property real smallWorkspaceRadius: Appearance.rounding.verysmall

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: 250 * (screen.devicePixelRatio ?? 1.0)
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: 5

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []
    
    function getWsRow(ws) {
        // 1-indexed workspace, 0-indexed row
        var normalRow = Math.floor((ws - 1) / Config.options.overview.columns) % Config.options.overview.rows;
        return (Config.options.overview.orderBottomUp ? Config.options.overview.rows - normalRow - 1 : normalRow);
    }
    function getWsColumn(ws) {
        // 1-indexed workspace, 0-indexed column
        var normalCol = (ws - 1) % Config.options.overview.columns;
        return (Config.options.overview.orderRightLeft ? Config.options.overview.columns - normalCol - 1 : normalCol);
    }
    function getWsInCell(ri, ci) {
        // 1-indexed workspace, 0-indexed row and column index
        return (Config.options.overview.orderBottomUp ? Config.options.overview.rows - ri - 1 : ri) * Config.options.overview.columns + (Config.options.overview.orderRightLeft ? Config.options.overview.columns - ci - 1 : ci) + 1
    }

    StyledRectangularShadow {
        target: overviewBackground
    }
    Rectangle { // Background
        id: overviewBackground
        property real padding: 10
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: root.largeWorkspaceRadius + padding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Column { // Workspaces
            id: workspaceColumnLayout

            z: root.workspaceZ
            anchors.centerIn: parent
            spacing: workspaceSpacing
            
            Repeater {
                model: Config.options.overview.rows
                delegate: Row {
                    id: row
                    required property int index
                    spacing: workspaceSpacing

                    Repeater { // Workspace repeater
                        model: Config.options.overview.columns
                        Rectangle { // Workspace
                            id: workspace
                            required property int index
                            property int colIndex: index
                            property int workspaceValue: root.workspaceGroup * root.workspacesShown + getWsInCell(row.index, colIndex)
                            property color defaultWorkspaceColor: Appearance.colors.colSurfaceContainerLow
                            property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Appearance.colors.colLayer1Hover, 0.1)
                            property color hoveredBorderColor: Appearance.colors.colLayer2Hover
                            property bool hoveredWhileDragging: false

                            implicitWidth: root.workspaceImplicitWidth
                            implicitHeight: root.workspaceImplicitHeight
                            color: hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor
                            property bool workspaceAtLeft: colIndex === 0
                            property bool workspaceAtRight: colIndex === Config.options.overview.columns - 1
                            property bool workspaceAtTop: row.index === 0
                            property bool workspaceAtBottom: row.index === Config.options.overview.rows - 1
                            topLeftRadius: (workspaceAtLeft && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                            topRightRadius: (workspaceAtRight && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                            bottomLeftRadius: (workspaceAtLeft && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                            bottomRightRadius: (workspaceAtRight && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                            border.width: 2
                            border.color: hoveredWhileDragging ? hoveredBorderColor : "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: workspace.workspaceValue
                                font {
                                    pixelSize: root.workspaceNumberSize * root.scale
                                    weight: Font.DemiBold
                                    family: Appearance.font.family.expressive
                                }
                                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: workspaceArea
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onPressed: {
                                    if (root.draggingTargetWorkspace === -1) {
                                        GlobalStates.overviewOpen = false
                                        // KDE: switch to the clicked workspace via qdbus6
                                        Quickshell.execDetached(["bash", "-c",
                                            `qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop ${workspace.workspaceValue} 2>/dev/null || true`
                                        ])
                                    }
                                }
                            }

                            Grid {
                                id: iconGrid
                                anchors.centerIn: parent
                                property int itemCount: windowRepeater.model.values.length
                                property int cols: Math.max(1, Math.ceil(Math.sqrt(itemCount)))
                                property int rows: Math.ceil(itemCount / cols)
                                columns: cols
                                spacing: 12
                                
                                property real maxW: workspace.width - 32
                                property real maxH: workspace.height - 32
                                property real targetW: cols * 64 + Math.max(0, cols - 1) * spacing
                                property real targetH: rows * 64 + Math.max(0, rows - 1) * spacing
                                
                                scale: Math.min(1.0, Math.min(maxW / Math.max(1, targetW), maxH / Math.max(1, targetH)))
                                transformOrigin: Item.Center
                                
                                Repeater {
                                    id: windowRepeater
                                    model: ScriptModel {
                                        values: {
                                            return root.kwinWindows.filter((win) => win.workspace.id === workspace.workspaceValue);
                                        }
                                    }
                                    delegate: OverviewWindow {
                                        id: window
                                        required property var modelData
                                        property var address: modelData.internalId
                                        windowData: modelData
                                        
                                        z: Drag.active ? root.windowDraggingZ : root.windowZ
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        MouseArea {
                                            id: dragArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                            drag.target: parent
                                            onPressed: (mouse) => {
                                                root.draggingFromWorkspace = windowData?.workspace.id
                                                window.pressed = true
                                                window.Drag.active = true
                                                window.Drag.source = window
                                                window.Drag.hotSpot.x = mouse.x
                                                window.Drag.hotSpot.y = mouse.y
                                            }
                                            onReleased: {
                                                const targetWorkspace = root.draggingTargetWorkspace
                                                window.pressed = false
                                                window.Drag.active = false
                                                root.draggingFromWorkspace = -1
                                                if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) {
                                                    Quickshell.execDetached(["bash", "-c",
                                                        `qdbus6 org.kde.KWin /KWin org.kde.KWin.moveWindowToDesktop ` +
                                                        `'${window.windowData?.internalId}' ${targetWorkspace} 2>/dev/null || true`
                                                    ])
                                                }
                                            }
                                            onClicked: (event) => {
                                                if (event.button === Qt.LeftButton) {
                                                    GlobalStates.overviewOpen = false
                                                    event.accepted = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            DropArea {
                                anchors.fill: parent
                                onEntered: {
                                    root.draggingTargetWorkspace = workspace.workspaceValue
                                    if (root.draggingFromWorkspace == root.draggingTargetWorkspace) return;
                                    hoveredWhileDragging = true
                                }
                                onExited: {
                                    hoveredWhileDragging = false
                                    if (root.draggingTargetWorkspace == workspace.workspaceValue) root.draggingTargetWorkspace = -1
                                }
                            }

                        }
                    }
                }
            }
        }

        Item { // Windows & focused workspace indicator
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight

            Rectangle { // Focused workspace indicator
                id: focusedWorkspaceIndicator
                property int rowIndex: getWsRow(root.effectiveActiveWorkspaceId)
                property int colIndex: getWsColumn(root.effectiveActiveWorkspaceId)
                x: (root.workspaceImplicitWidth + workspaceSpacing) * colIndex
                y: (root.workspaceImplicitHeight + workspaceSpacing) * rowIndex
                z: root.windowZ
                width: root.workspaceImplicitWidth
                height: root.workspaceImplicitHeight
                color: "transparent"
                property bool workspaceAtLeft: colIndex === 0
                property bool workspaceAtRight: colIndex === Config.options.overview.columns - 1
                property bool workspaceAtTop: rowIndex === 0
                property bool workspaceAtBottom: rowIndex === Config.options.overview.rows - 1
                topLeftRadius: (workspaceAtLeft && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                topRightRadius: (workspaceAtRight && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                bottomLeftRadius: (workspaceAtLeft && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                bottomRightRadius: (workspaceAtRight && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                border.width: 2
                border.color: root.activeBorderColor
                Behavior on x {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on topLeftRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on topRightRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on bottomLeftRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on bottomRightRadius {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
            }
        }
    }
}
