import Caelestia.Services
import qs.components
import qs.services

PerfStat {
    icon: "desktop_windows"
    accent: Colours.palette.m3secondary
    value: Gpu.percentage
    valueText: isNaN(Gpu.percentage) ? "..." : Math.round(Gpu.percentage * 100)

    ServiceRef {
        service: Gpu
    }
}
