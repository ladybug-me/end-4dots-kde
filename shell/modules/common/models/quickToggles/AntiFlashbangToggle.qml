import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Anti-flashbang")
    tooltipText: `${Translation.tr("Anti-flashbang")}: ${Config.options.light.antiFlashbang.enable ? Translation.tr("On") : Translation.tr("Off")}`
    icon: Config.options.light.antiFlashbang.enable ? "flash_off" : "flash_on"
    toggled: Config.options.light.antiFlashbang.enable

    mainAction: () => {
        Config.options.light.antiFlashbang.enable = !Config.options.light.antiFlashbang.enable;
    }
    hasMenu: true
}
