pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components.misc
import qs.services
import qs.modules.common
import qs.modules.common.functions

/**
 * For managing brightness of monitors. Supports Wayland protocol, ddcutil, and Apple displays.
 */
Singleton {
    id: root

    property list<var> ddcMonitors: []
    readonly property var ddcMonitorMap: {
        const map = {};
        for (const m of ddcMonitors)
            map[m.connector] = m;
        return map;
    }
    readonly property list<Monitor> monitors: variants.instances // qmllint disable incompatible-type
    property bool appleDisplayPresent: false
    property int workspaceAnimationDelay: 500
    property int contentSwitchDelay: 30
    property string screenshotDir: "/tmp/quickshell/brightness/antiflashbang"

    signal brightnessChanged()

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.modelData === screen) ?? null; // qmllint disable missing-property
    }

    function getMonitor(query: string): var {
        if (query === "active") {
            return monitors.find(m => Kwin.monitorFor(m.modelData)?.focused) ?? monitors[0] ?? null; // qmllint disable missing-property
        }

        if (query.startsWith("model:")) {
            const model = query.slice(6);
            return monitors.find(m => m.modelData.model === model) ?? null; // qmllint disable missing-property
        }

        if (query.startsWith("serial:")) {
            const serial = query.slice(7);
            return monitors.find(m => m.modelData.serialNumber === serial) ?? null; // qmllint disable missing-property
        }

        if (query.startsWith("id:")) {
            const id = parseInt(query.slice(3), 10);
            return monitors.find(m => Kwin.monitorFor(m.modelData)?.id === id) ?? null; // qmllint disable missing-property
        }

        return monitors.find(m => m.modelData.name === query) ?? null; // qmllint disable missing-property
    }

    function increaseBrightness(): void {
        // if gamma is not yet 100, first increase gamma
        if (Hyprsunset.gamma !== 100) {
            Hyprsunset.setGamma(Hyprsunset.gamma + 5);
            return;
        }

        const monitor = getMonitor("active");
        if (monitor)
            monitor.stepBrightness(GlobalConfig.services.brightnessIncrement);
    }

    function decreaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor && monitor.brightness > 0)
            monitor.stepBrightness(-GlobalConfig.services.brightnessIncrement);
        // if brightness is 0, then decrease gamma
        else {
            Hyprsunset.setGamma(Hyprsunset.gamma - 5);
        }
    }

    function brightnessMultiplierForLightness(x: real): real {
        // Fitted exponential curve: 6.600135 + 216.360356 * e^(-0.0811129189x)
        return (6.600135 + 216.360356 * Math.pow(Math.E, -0.0811129189 * x)) / 100.0;
    }

    reloadableId: "brightness"

    onMonitorsChanged: {
        ddcMonitors = [];
        ddcProc.running = true;
    }

    Variants {
        id: variants

        model: Quickshell.screens

        Monitor {}
    }

    Process {
        running: true
        command: ["sh", "-c", "asdbctl get"]

        stdout: StdioCollector {
            onStreamFinished: root.appleDisplayPresent = text.trim().length > 0
        }
    }

    Process {
        id: ddcProc

        command: ["ddcutil", "detect", "--brief"]

        stdout: StdioCollector {
            onStreamFinished: root.ddcMonitors = text.trim().split("\n\n").filter(d => d.startsWith("Display ")).map(d => {
                        const busNum = d.match(/I2C bus:[ ]*\/dev\/i2c-([0-9]+)/)?.[1];
                        const connector = d.match(/DRM connector:\s+(.*)/)?.[1]?.replace(/^card\d+-/, "");
                        return busNum && connector ? { busNum, connector } : null;
                    }).filter(m => m)
        }
    }

    // Native Wayland listener
    Connections {
        function onBrightnessChanged(outputName: string, value: real): void {
            const monitor = root.getMonitor(outputName);
            if (monitor && monitor.brightness !== value) {
                monitor.brightness = value;
            }
        }

        function onDimmingChanged(outputName: string, value: real): void {
            const monitor = root.getMonitor(outputName);
            if (monitor && monitor.dimming !== value) {
                monitor.dimming = value;
            }
        }

        target: BrightnessWatcher
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "brightnessUp"
        description: qsTr("Increase brightness")
        onPressed: root.increaseBrightness()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "brightnessDown"
        description: qsTr("Decrease brightness")
        onPressed: root.decreaseBrightness()
    }

    GlobalShortcut {
        name: "brightnessIncrease"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    GlobalShortcut {
        name: "brightnessDecrease"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }

    IpcHandler {
        function get(): real {
            return getFor("active");
        }

        function getFor(query: string): real {
            return root.getMonitor(query)?.brightness ?? -1;
        }

        function getDimming(): real {
            return getDimmingFor("active");
        }

        function getDimmingFor(query: string): real {
            return root.getMonitor(query)?.dimming ?? -1;
        }

        function set(value: string): string {
            return setFor("active", value);
        }

        // Handles brightness value like brightnessctl: 0.1, +0.1, 0.1-, 10%, +10%, 10%-
        function setFor(query: string, value: string): string {
            const monitor = root.getMonitor(query);
            if (!monitor)
                return "Invalid monitor: " + query;

            const current = monitor.effectiveBrightness;
            let targetBrightness;
            if (value.endsWith("%-")) {
                const percent = parseFloat(value.slice(0, -2));
                targetBrightness = current - (percent / 100);
            } else if (value.startsWith("+") && value.endsWith("%")) {
                const percent = parseFloat(value.slice(1, -1));
                targetBrightness = current + (percent / 100);
            } else if (value.endsWith("%")) {
                const percent = parseFloat(value.slice(0, -1));
                targetBrightness = percent / 100;
            } else if (value.startsWith("+")) {
                const increment = parseFloat(value.slice(1));
                targetBrightness = current + increment;
            } else if (value.endsWith("-")) {
                const decrement = parseFloat(value.slice(0, -1));
                targetBrightness = current - decrement;
            } else if (value.includes("%") || value.includes("-") || value.includes("+")) {
                return `Invalid brightness format: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;
            } else {
                targetBrightness = parseFloat(value);
            }

            if (isNaN(targetBrightness))
                return `Failed to parse value: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;

            monitor.setBrightness(targetBrightness);

            return `Set monitor ${monitor.modelData.name} brightness to ${+monitor.brightness.toFixed(2)}`;
        }

        function increment(): void {
            root.increaseBrightness();
        }

        function decrement(): void {
            root.decreaseBrightness();
        }

        target: "brightness"
    }

    // Anti-flashbang
    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property var modelData
            property string screenName: modelData.name
            property string screenshotPath: `${root.screenshotDir}/screenshot-${screenName}.png`

            Connections {
                function onActiveWindowChanged() {
                    screenshotTimer.interval = root.contentSwitchDelay;
                    screenshotTimer.restart();
                }

                function onActiveWsIdChanged() {
                    screenshotTimer.interval = root.workspaceAnimationDelay;
                    screenshotTimer.restart();
                }

                enabled: (Config.options?.light?.antiFlashbang?.enable ?? false) && (Appearance.m3colors?.darkmode ?? false)
                target: Kwin
            }

            Timer {
                id: screenshotTimer

                interval: 700
                onTriggered: {
                    screenshotProc.running = false;
                    screenshotProc.running = true;
                }
            }

            Process {
                id: screenshotProc

                command: ["bash", "-c",
                    `mkdir -p '${StringUtils.shellSingleQuoteEscape(root.screenshotDir)}'`
                    + ` && grim -o '${StringUtils.shellSingleQuoteEscape(screenScope.screenName)}' -`
                    + ` | magick png:- -colorspace Gray -format "%[fx:mean*100]" info:`
                ]

                stdout: StdioCollector {
                    id: lightnessCollector

                    onStreamFinished: {
                        Quickshell.execDetached(["rm", screenScope.screenshotPath]); // Cleanup
                        const lightness = lightnessCollector.text
                        const newMultiplier = root.brightnessMultiplierForLightness(parseFloat(lightness))
                        root.getMonitorForScreen(screenScope.modelData)?.setBrightnessMultiplier(newMultiplier)
                    }
                }
            }
        }
    }

    component Monitor: QtObject {
        id: monitor

        required property ShellScreen modelData
        readonly property alias screen: monitor.modelData
        readonly property var ddcInfo: root.ddcMonitorMap[modelData.name] ?? null
        readonly property bool isDdc: ddcInfo !== null
        readonly property string busNum: ddcInfo?.busNum ?? ""
        readonly property bool isAppleDisplay: root.appleDisplayPresent && modelData.model.startsWith("StudioDisplay")
        readonly property bool writesHardwareDirectly: isAppleDisplay || isDdc
        property real brightness: 1.0
        property real dimming: 1.0
        property real brightnessMultiplier: 1.0
        readonly property real effectiveBrightness: Math.max(0, Math.min(1, brightness * dimming * (Config.options?.light?.antiFlashbang?.enable ? brightnessMultiplier : 1)))
        property real queuedBrightness: NaN
        property bool verifying: false

        readonly property Process readProc: Process {
            stdout: StdioCollector {
                onStreamFinished: {
                    if (monitor.isAppleDisplay) {
                        const val = parseInt(text.trim());
                        monitor.brightness = val / 101;
                        return;
                    }

                    const [, , , cur, max] = text.split(" ");
                    const actual = parseInt(cur) / parseInt(max);

                    if (!monitor.verifying) {
                        monitor.brightness = actual;
                        return;
                    }

                    monitor.verifying = false;
                    const target = Math.round(monitor.brightness * 100);

                    if (isNaN(actual) || Math.round(actual * 100) === target)
                        return;

                    monitor.writeBrightness(target / 100);
                    monitor.brightness = target / 100;

                    if (isDdc)
                        timer.restart();
                }
            }
        }

        readonly property Timer timer: Timer {
            interval: 500
            onTriggered: {
                if (!isNaN(monitor.queuedBrightness)) {
                    const pending = monitor.queuedBrightness;
                    monitor.queuedBrightness = NaN;
                    monitor.brightness = pending;
                    // writeBrightness() skips setBrightness(), so KWin's record is updated here too.
                    monitor.syncKwinRecord(Math.round(pending * 100) / 100);
                    monitor.writeBrightness(pending);
                    monitor.timer.restart();
                }
            }
        }

        function syncKwinRecord(value: real): void {
            if (writesHardwareDirectly && BrightnessWatcher.brightness(modelData.name) >= 0)
                BrightnessWatcher.setBrightness(modelData.name, value);
        }

        function writeBrightness(value: real): void {
            const actual = Config.options?.light?.antiFlashbang?.enable
                ? Math.max(0, Math.min(1, value * brightnessMultiplier))
                : value;
            const rounded = Math.round(actual * 100);

            if (isAppleDisplay)
                Quickshell.execDetached(["asdbctl", "set", rounded]);
            else if (isDdc)
                Quickshell.execDetached(["ddcutil", "-b", busNum, "setvcp", "10", rounded]);
            else
                BrightnessWatcher.setBrightness(modelData.name, actual);
        }

        // Steps are relative to what the screen renders, not to the value last commanded.
        function stepBrightness(delta: real): void {
            setBrightness(effectiveBrightness + delta);
        }

        function setBrightness(value: real): void {
            value = Math.max(0, Math.min(1, value));
            const rounded = Math.round(value * 100);

            // The KWin write below also asserts full dimming; mirror it now so the OSD does not
            // keep showing the stale multiplier until KWin echoes the cleared value back.
            if (dimming < 1)
                dimming = 1;

            if (Math.round(brightness * 100) === rounded) {
                syncKwinRecord(rounded / 100);

                if (isDdc && !timer.running && !readProc.running) {
                    verifying = true;
                    readProc.running = true;
                }
                return;
            }

            if (isDdc && timer.running) {
                queuedBrightness = value;
                brightness = value;
                return;
            }

            syncKwinRecord(rounded / 100);

            brightness = value;
            writeBrightness(value);

            if (isDdc)
                timer.restart();
        }

        function setBrightnessMultiplier(value: real): void {
            monitor.brightnessMultiplier = value;
            if (Config.options?.light?.antiFlashbang?.enable) {
                writeBrightness(brightness);
            }
        }

        function initBrightness(): void {
            const dim = BrightnessWatcher.dimming(modelData.name);
            if (dim >= 0.0)
                monitor.dimming = dim;

            if (isAppleDisplay)
                readProc.command = ["asdbctl", "get"];
            else if (isDdc)
                readProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"];
            else {
                const val = BrightnessWatcher.brightness(modelData.name);
                if (val >= 0.0)
                    monitor.brightness = val;
                return;
            }

            readProc.running = true;
        }

        onBrightnessChanged: root.brightnessChanged()
        onDimmingChanged: root.brightnessChanged()
        onEffectiveBrightnessChanged: root.brightnessChanged()
        onBusNumChanged: initBrightness()
        Component.onCompleted: initBrightness()
    }
}
