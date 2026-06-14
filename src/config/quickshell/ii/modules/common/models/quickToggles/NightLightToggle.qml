import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    property bool auto: Config.options.light.night.automatic

    name: Translation.tr("Night Light")
    statusText: (auto ? Translation.tr("Auto, ") : "") + (toggled ? Translation.tr("Active") : Translation.tr("Inactive"))

    toggled: Hyprsunset.temperatureActive
    icon: auto ? "night_sight_auto" : "bedtime"
    
    mainAction: () => {
        Quickshell.execDetached(["kcmshell6", "kcm_nightlight"])
    }
    hasMenu: false

    // State is automatically fetched by Hyprsunset service on startup (via fetchProc)
    
    tooltipText: Translation.tr("Night Light Settings")
}
