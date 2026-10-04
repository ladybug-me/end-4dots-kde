pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs
import qs.components.misc
import qs.services
import qs.utils
import qs.modules.common

Scope {
    id: root

    property bool launcherInterrupted: false
    readonly property bool hasFullscreen: Kwin.hasFullscreen()

    // `action` ids are the krohnkite
    // kwinscript's own registrations (verified against its contents/ui/shortcuts.qml):
    // keep their exact casing (e.g. "KrohnkitegrowWidth") or KWin will invoke actions
    // it never registered. `key` is the default binding ("" = unbound), overridden by
    // the user's keybinds.json.
    readonly property var krohnkiteShortcuts: [
        { name: "krohnkiteFocusUp", description: qsTr("Focus the window above"), action: "KrohnkiteFocusUp", key: "Meta+Up" },
        { name: "krohnkiteFocusDown", description: qsTr("Focus the window below"), action: "KrohnkiteFocusDown", key: "Meta+Down" },
        { name: "krohnkiteFocusLeft", description: qsTr("Focus the window to the left"), action: "KrohnkiteFocusLeft", key: "Meta+Left" },
        { name: "krohnkiteFocusRight", description: qsTr("Focus the window to the right"), action: "KrohnkiteFocusRight", key: "Meta+Right" },
        { name: "krohnkiteShiftUp", description: qsTr("Move window up"), action: "KrohnkiteShiftUp", key: "Meta+Shift+Up" },
        { name: "krohnkiteShiftDown", description: qsTr("Move window down"), action: "KrohnkiteShiftDown", key: "Meta+Shift+Down" },
        { name: "krohnkiteShiftLeft", description: qsTr("Move window left"), action: "KrohnkiteShiftLeft", key: "Meta+Shift+Left" },
        { name: "krohnkiteShiftRight", description: qsTr("Move window right"), action: "KrohnkiteShiftRight", key: "Meta+Shift+Right" },
        { name: "krohnkiteCloseWindow", description: qsTr("Close current window"), action: "Window Close", key: "Meta+Q" },
        { name: "krohnkiteFocusNext", description: qsTr("Focus next window"), action: "KrohnkiteFocusNext", key: "" },
        { name: "krohnkiteFocusPrev", description: qsTr("Focus previous window"), action: "KrohnkiteFocusPrev", key: "" },
        { name: "krohnkiteSetMaster", description: qsTr("Set active window as Master"), action: "KrohnkiteSetMaster", key: "" },
        { name: "krohnkiteNextLayout", description: qsTr("Switch to next layout"), action: "KrohnkiteNextLayout", key: "" },
        { name: "krohnkitePreviousLayout", description: qsTr("Switch to previous layout"), action: "KrohnkitePreviousLayout", key: "" },
        { name: "krohnkiteBTreeLayout", description: qsTr("Switch to BTree layout"), action: "KrohnkiteBTreeLayout", key: "" },
        { name: "krohnkiteMonocleLayout", description: qsTr("Switch to Monocle layout"), action: "KrohnkiteMonocleLayout", key: "" },
        { name: "krohnkiteFloatingLayout", description: qsTr("Switch to Floating layout"), action: "KrohnkiteFloatingLayout", key: "" },
        { name: "krohnkiteQuarterLayout", description: qsTr("Switch to Quarter layout"), action: "KrohnkiteQuarterLayout", key: "" },
        { name: "krohnkiteSpreadLayout", description: qsTr("Switch to Spread layout"), action: "KrohnkiteSpreadLayout", key: "" },
        { name: "krohnkiteStackedLayout", description: qsTr("Switch to Stacked layout"), action: "KrohnkiteStackedLayout", key: "" },
        { name: "krohnkiteStairLayout", description: qsTr("Switch to Stair layout"), action: "KrohnkiteStairLayout", key: "" },
        { name: "krohnkiteColumnsLayout", description: qsTr("Switch to Columns layout"), action: "KrohnkiteColumnsLayout", key: "" },
        { name: "krohnkiteTreeColumnLayout", description: qsTr("Switch to Three Column layout"), action: "KrohnkiteThreeColumnLayout", key: "" },
        { name: "krohnkiteSpiralLayout", description: qsTr("Switch to Spiral layout"), action: "KrohnkiteSpiralLayout", key: "" },
        { name: "krohnkiteTileLayout", description: qsTr("Switch to Tile layout"), action: "KrohnkiteTileLayout", key: "" },
        { name: "krohnkiteGrowHeight", description: qsTr("Increase window height"), action: "KrohnkiteGrowHeight", key: "" },
        { name: "krohnkiteShrinkHeight", description: qsTr("Decrease window height"), action: "KrohnkiteShrinkHeight", key: "" },
        { name: "krohnkiteGrowWidth", description: qsTr("Increase window width"), action: "KrohnkitegrowWidth", key: "" },
        { name: "krohnkiteShrinkWidth", description: qsTr("Decrease window width"), action: "KrohnkiteShrinkWidth", key: "" },
        { name: "krohnkiteIncreaseMaster", description: qsTr("Increase master area size"), action: "KrohnkiteIncrease", key: "" },
        { name: "krohnkiteDecreaseMaster", description: qsTr("Decrease master area size"), action: "KrohnkiteDecrease", key: "" },
        { name: "krohnkiteToggleFloat", description: qsTr("Toggle floating state"), action: "KrohnkiteToggleFloat", key: "" },
        { name: "krohnkiteFloatAll", description: qsTr("Toggle floating state for all"), action: "KrohnkiteFloatAll", key: "" },
        { name: "krohnkiteRotate", description: qsTr("Rotate the window layout"), action: "KrohnkiteRotate", key: "" },
        { name: "krohnkiteRotatePart", description: qsTr("Rotate windows within a part"), action: "KrohnkiteRotatePart", key: "" },
        { name: "krohnkiteToggleDock", description: qsTr("Toggle dock support"), action: "KrohnkitetoggleDock", key: "" }
    ]

    function toggleLauncher(): void {
        if (Config.options?.panelFamily === "waffle") {
            GlobalStates.searchOpen = !GlobalStates.searchOpen;
        } else {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }

    Component.onCompleted: {
        let _ = KeybindsModel;
    }

    CustomShortcut {
        name: "launcher"
        description: qsTr("Toggle launcher")

        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted) {
                root.toggleLauncher();
            }
            root.launcherInterrupted = false;
        }
    }

    CustomShortcut {
        name: "launcherInterrupt"
        description: qsTr("Interrupt launcher keybind")

        onPressed: root.launcherInterrupted = true
    }

    CustomShortcut {
        name: "overview"
        description: qsTr("Toggle overview")

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }

    CustomShortcut {
        name: "session"
        description: qsTr("Toggle session menu")

        onPressed: {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }
    }

    CustomShortcut {
        name: "lock"
        description: qsTr("Lock session")

        onPressed: {
            Quickshell.execDetached(["loginctl", "lock-session"]);
        }
    }

    CustomShortcut {
        name: "sidebar"
        description: qsTr("Toggle sidebar")

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }
    }

    CustomShortcut {
        name: "screenshot"
        description: qsTr("Toggle screenshot overlay")

        onPressed: {
            GlobalStates.regionSelectorOpen = true;
        }
    }

    CustomShortcut {
        name: "googleLens"
        description: qsTr("Toggle Google Lens search")

        onPressed: {
            Quickshell.execDetached(["qs-msg", "-c", "caelestia", "regionSelector", "search"]);
        }
    }

    CustomShortcut {
        name: "ocr"
        description: qsTr("Recognize text on screen")

        onPressed: {
            Quickshell.execDetached(["qs-msg", "-c", "caelestia", "regionSelector", "ocr"]);
        }
    }

    CustomShortcut {
        name: "screenRecording"
        description: qsTr("Toggle screen recording")

        onPressed: {
            Quickshell.execDetached(["qs-msg", "-c", "caelestia", "regionSelector", "record"]);
        }
    }

    CustomShortcut {
        name: "wallpaper"
        description: qsTr("Open wallpaper picker")

        onPressed: {
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen;
        }
    }

    CustomShortcut {
        name: "keybinds"
        description: qsTr("Open keybinds list")

        onPressed: {
            Quickshell.execDetached(["qs-msg", "-c", "caelestia", "cheatsheet", "toggle"]);
        }
    }

    CustomShortcut {
        name: "foot"
        description: qsTr("Launch Terminal")

        onPressed: Launch.exec([...GlobalConfig.general.apps.terminal])
    }

    CustomShortcut {
        name: "firefox"
        description: qsTr("Launch Browser")

        onPressed: Launch.exec(["firefox"])
    }

    CustomShortcut {
        name: "code"
        description: qsTr("Launch Editor")

        onPressed: Launch.exec(["code"])
    }

    CustomShortcut {
        name: "github-desktop"
        description: qsTr("Launch GitHub Desktop")

        onPressed: Launch.exec(["github-desktop"])
    }

    CustomShortcut {
        name: "nemo"
        description: qsTr("Launch File Manager")

        onPressed: Launch.exec(["nemo"])
    }

    CustomShortcut {
        name: "kcolorpicker"
        description: qsTr("Color Picker")

        onPressed: ColorPicker.pickColor()
    }

    Instantiator {
        model: root.krohnkiteShortcuts

        delegate: CustomShortcut {
            required property var modelData

            name: modelData.name
            description: modelData.description
            key: Config.general?.krohnkiteEnabled ? modelData.key : ""

            onPressed: {
                if (Config.general?.krohnkiteEnabled)
                    Quickshell.execDetached(["qdbus6", "org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component.invokeShortcut", modelData.action]);
            }
        }
    }

    CustomShortcut {
        name: "workspace1"
        description: qsTr("Switch to workspace 1")

        onPressed: Kwin.setDesktop(1)
    }

    CustomShortcut {
        name: "workspace2"
        description: qsTr("Switch to workspace 2")

        onPressed: Kwin.setDesktop(2)
    }

    CustomShortcut {
        name: "workspace3"
        description: qsTr("Switch to workspace 3")

        onPressed: Kwin.setDesktop(3)
    }

    CustomShortcut {
        name: "workspace4"
        description: qsTr("Switch to workspace 4")

        onPressed: Kwin.setDesktop(4)
    }

    CustomShortcut {
        name: "workspace5"
        description: qsTr("Switch to workspace 5")

        onPressed: Kwin.setDesktop(5)
    }

    CustomShortcut {
        name: "workspace6"
        description: qsTr("Switch to workspace 6")

        onPressed: Kwin.setDesktop(6)
    }

    CustomShortcut {
        name: "workspace7"
        description: qsTr("Switch to workspace 7")

        onPressed: Kwin.setDesktop(7)
    }

    CustomShortcut {
        name: "workspace8"
        description: qsTr("Switch to workspace 8")

        onPressed: Kwin.setDesktop(8)
    }

    CustomShortcut {
        name: "workspace9"
        description: qsTr("Switch to workspace 9")

        onPressed: Kwin.setDesktop(9)
    }

    CustomShortcut {
        name: "workspace10"
        description: qsTr("Switch to workspace 10")

        onPressed: Kwin.setDesktop(10)
    }
}
