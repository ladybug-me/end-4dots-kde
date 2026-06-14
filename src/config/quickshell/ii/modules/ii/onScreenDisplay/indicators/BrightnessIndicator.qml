import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: root
    // KDE port: Hyprland.focusedMonitor is unavailable on KDE Plasma.
    // Use the primary monitor (first in list) for brightness display.
    property var brightnessMonitor: Brightness.getPrimaryMonitor()

    icon: Hyprsunset.temperatureActive ? "routine" : "light_mode"
    // rotateIcon: false — brightness icon doesn't need rotation
    // scaleIcon: true — icon grows with brightness level
    scaleIcon: true
    rotateIcon: true
    name: Translation.tr("Brightness")
    // brightness is 0.0–1.0 from Brightness service; fallback to 0.0 (not 50)
    value: root.brightnessMonitor?.brightness ?? 0.0
}
