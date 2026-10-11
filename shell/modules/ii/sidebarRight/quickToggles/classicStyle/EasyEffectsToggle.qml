import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.utils
import qs.modules.common.widgets

QuickToggleButton {
    id: root
    visible: EasyEffects.available
    toggled: EasyEffects.active
    buttonIcon: "instant_mix"

    Component.onCompleted: {
        EasyEffects.fetchActiveState()
    }

    onClicked: {
        EasyEffects.toggle()
    }

    altAction: () => {
        Launch.exec(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"])
        GlobalStates.sidebarRightOpen = false
    }

    StyledToolTip {
        text: Translation.tr("EasyEffects | Right-click to configure")
    }
}
