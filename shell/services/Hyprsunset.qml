pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Services
import qs.modules.common

/**
 * Night Light service backed by native KWin NightColorBridge C++ plugin.
 */
Singleton {
    id: root

    readonly property int currentTemperature: NightColorBridge.currentTemperature
    readonly property int dayTemperature: NightColorBridge.dayTemperature
    readonly property int nightTemperature: NightColorBridge.nightTemperature
    readonly property bool available: NightColorBridge.available
    readonly property bool autoMode: NightColorBridge.autoMode
    readonly property real gammaLowerLimit: 25

    property bool temperatureActive: NightColorBridge.active
    property int colorTemperature: NightColorBridge.nightTemperature
    property int defaultColorTemperature: 6500
    property int gamma: 100

    property string from: Config.options?.light?.night?.from ?? "19:00"
    property string to: Config.options?.light?.night?.to ?? "06:30"
    property bool automatic: NightColorBridge.autoMode
    property bool shouldBeOn: NightColorBridge.active

    signal gammaChangeAttempt()

    function setDayTemperature(temp: int): void {
        NightColorBridge.setDayTemperature(temp);
    }

    function setNightTemperature(temp: int): void {
        NightColorBridge.setNightTemperature(temp);
    }

    function previewTemperature(temp: int): void {
        NightColorBridge.previewTemperature(temp);
    }

    function stopPreview(): void {
        NightColorBridge.stopPreview();
    }

    function toggleAutoMode(): void {
        NightColorBridge.toggleAutoMode();
    }

    function toggleNightLight(): void {
        NightColorBridge.toggleNightLight();
    }

    function toggleTemperature(active: var): void {
        if (active === undefined) {
            NightColorBridge.toggleNightLight();
        } else if (active !== NightColorBridge.active) {
            NightColorBridge.toggleNightLight();
        }
    }

    function enableTemperature(): void {
        if (!NightColorBridge.active)
            NightColorBridge.toggleNightLight();
    }

    function disableTemperature(): void {
        if (NightColorBridge.active)
            NightColorBridge.toggleNightLight();
    }

    function setGamma(g: int): void {
        root.gamma = Math.max(root.gammaLowerLimit, Math.min(100, g));
        root.gammaChangeAttempt();
    }

    function fetchState(): void {
        // NightColorBridge maintains real-time D-Bus properties
    }

    function ensureState(): void {
        // Handled directly by KWin Night Light
    }

    function load(): void {
        // Initialized directly by NightColorBridge
    }
}