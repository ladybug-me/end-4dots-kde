import QtQuick
import qs.services
import "../"

QuickToggleModel {
    id: root

    name: Translation.tr("Game mode")
    toggled: GameMode.enabled
    icon: "gamepad"
    tooltipText: Translation.tr("Game mode")

    mainAction: () => {
        GameMode.enabled = !GameMode.enabled;
    }
}
