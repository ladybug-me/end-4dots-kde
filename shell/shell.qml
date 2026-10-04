//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"
import "modules"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Caelestia.Services
import qs.components.misc

ShellRoot {
    id: root

    property list<string> families: ["ii", "waffle"]

    function cyclePanelFamily(): void {
        const currentIndex = families.indexOf(Config.options.panelFamily);
        const nextIndex = (currentIndex + 1) % families.length;
        Config.options.panelFamily = families[nextIndex];
    }

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
        Hyprsunset.load();
        FirstRunExperience.load();
        ConflictKiller.load();
        Cliphist.refresh();
        Wallpapers.load();
        Updates.load();
    }

    ReloadPopup {}

    Shortcuts {}

    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }

    IpcHandler {
        function cycle(): void {
            root.cyclePanelFamily();
        }

        target: "panelFamily"
    }

    CustomShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true

        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
}


