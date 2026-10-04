import QtQuick
import Quickshell
import qs.services
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Kwin.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    icon: Hyprsunset.temperatureActive ? "routine" : "light_mode"
    rotateIcon: true
    scaleIcon: true
    name: Translation.tr("Brightness")
    value: root.brightnessMonitor?.brightness ?? 50
}
