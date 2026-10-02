pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
import qs.modules.common

/**
 * High-performance hardware resource monitoring backed by Caelestia C++ Cpu and Memory services.
 */
Singleton {
    id: root

    readonly property real memoryTotal: Memory.total
    readonly property real memoryUsed: Memory.used
    readonly property real memoryFree: Math.max(0, Memory.total - Memory.used)
    readonly property real memoryUsedPercentage: Memory.percentage

    property real swapTotal: 1
    property real swapFree: 0
    readonly property real swapUsed: Math.max(0, swapTotal - swapFree)
    readonly property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0

    readonly property real cpuUsage: Cpu.percentage
    readonly property real cpuTemperature: Cpu.temperature
    readonly property string cpuName: Cpu.name

    readonly property string maxAvailableMemoryString: (Memory.total / (1024 * 1024)).toFixed(1) + " GB"
    readonly property string maxAvailableSwapString: (swapTotal / (1024 * 1024)).toFixed(1) + " GB"
    readonly property string maxAvailableCpuString: Cpu.name.length > 0 ? Cpu.name : "--"

    readonly property int historyLength: Config?.options?.resources?.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb: real): string {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateHistories(): void {
        const cpuHist = [...cpuUsageHistory, cpuUsage];
        if (cpuHist.length > historyLength)
            cpuHist.shift();
        cpuUsageHistory = cpuHist;

        const memHist = [...memoryUsageHistory, memoryUsedPercentage];
        if (memHist.length > historyLength)
            memHist.shift();
        memoryUsageHistory = memHist;

        const swpHist = [...swapUsageHistory, swapUsedPercentage];
        if (swpHist.length > historyLength)
            swpHist.shift();
        swapUsageHistory = swpHist;
    }

    Timer {
        interval: Config.options?.resources?.updateInterval ?? 3000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            fileMeminfo.reload();
            const textMeminfo = fileMeminfo.text();
            root.swapTotal = Number(textMeminfo.match(/SwapTotal:\s*(\d+)/)?.[1] ?? 0);
            root.swapFree = Number(textMeminfo.match(/SwapFree:\s*(\d+)/)?.[1] ?? 0);

            root.updateHistories();
        }
    }

    FileView {
        id: fileMeminfo

        path: "/proc/meminfo"
    }
}
