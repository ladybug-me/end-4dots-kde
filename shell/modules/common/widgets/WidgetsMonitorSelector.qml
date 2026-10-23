import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Flow {
    id: root
    required property var configEntry 
    Layout.fillWidth: true
    spacing: 2

    SelectionGroupButton {
        leftmost: true
        rightmost: Hyprland.monitors.length === 0
        buttonIcon: "tv_displays"
        buttonText: Translation.tr("All")
        toggled: root.configEntry.screenList.length === 0
        onClicked: root.configEntry.screenList = []
    }

    Repeater {
        model: Hyprland.monitors
        delegate: SelectionGroupButton {
            required property var modelData
            required property int index
            leftmost: false
            rightmost: index === Hyprland.monitors.length - 1
            buttonIcon: "monitor"
            buttonText: modelData.name
            toggled: root.configEntry.screenList.includes(modelData.name)
            onClicked: {
                const allNames = Array.from({length: Hyprland.monitors.length}, (_, i) => Hyprland.monitors[i].name)
                let list = root.configEntry.screenList.length === 0 ? allNames.slice() : root.configEntry.screenList.slice()
                if (toggled) list = list.filter(s => s !== modelData.name)
                else list.push(modelData.name)
                root.configEntry.screenList = list.length === allNames.length ? [] : list
            }
        }
    }
    SelectionGroupButton {
        leftmost: false
        rightmost: true
        buttonIcon: "page_footer"
        buttonText: Translation.tr("")
    }
}