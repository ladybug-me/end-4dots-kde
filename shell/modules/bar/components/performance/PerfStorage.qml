import Caelestia.Services
import qs.components
import qs.services

PerfStat {
    readonly property real storagePerc: Storage.primaryDisk?.perc ?? Storage.percentage

    icon: "hard_disk"
    accent: Colours.palette.m3primary
    value: storagePerc
    valueText: isNaN(storagePerc) ? "..." : Math.round(storagePerc * 100)

    ServiceRef {
        service: Storage
    }
}
