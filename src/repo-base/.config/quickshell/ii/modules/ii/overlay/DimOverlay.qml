import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        WlrLayershell.namespace: "quickshell:dimoverlay"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        color: "black"
        // Convert gamma 100-0 to opacity 0.0-0.9
        opacity: Math.max(0, Math.min(0.9, (100 - Hyprsunset.gamma) / 100.0))
        visible: opacity > 0

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        
        screen: modelData

        // Click-through: wait, Quickshell handles click-through via mask?
        // Or if we don't grab focus, it passes through?
        // In Quickshell, to make a window click-through, we can either set mask to an empty region or rely on Wayland semantics if color is semi-transparent?
        // Actually, if we just want clickthrough, we can use Region {} as mask
        mask: Region {}
    }
}
