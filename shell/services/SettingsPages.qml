pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property string pagesDir: "modules/ii/settings/pages/"

    readonly property var pages: {
        const list = [
            { id: "quick",     name: Translation.tr("Quick"),     icon: "instant_mix",    file: "QuickConfig.qml" },
            { id: "general",   name: Translation.tr("General"),   icon: "browse",         file: "GeneralConfig.qml" },
            { id: "bar",       name: Translation.tr("Bar"),       icon: "toast",          iconRotation: 180, file: "BarConfig.qml" },
            { id: "desktop",   name: Translation.tr("Desktop"),   icon: "texture",        file: "BackgroundConfig.qml" },
            { id: "interface", name: Translation.tr("Interface"), icon: "bottom_app_bar", file: "InterfaceConfig.qml" },
            { id: "services",  name: Translation.tr("Services"),  icon: "settings",       file: "ServicesConfig.qml" },
        ];
        if (WM.compositor === "hyprland")
            list.push({ id: "hyprland", name: Translation.tr("Hyprland"), icon: "select_window_2", file: "HyprlandConfig.qml" });
        if (WM.compositor === "niri")
            list.push({ id: "niri", name: Translation.tr("Niri"), icon: "select_window_2", file: "NiriConfig.qml" });
        list.push({ id: "about", name: Translation.tr("About"), icon: "info", file: "About.qml" });
        return list.map(page => Object.assign({}, page, {
            component: Qt.resolvedUrl("../" + root.pagesDir + page.file),
            path: root.pagesDir + page.file
        }));
    }

    function byId(id) {
        return root.pages.find(page => page.id === id) ?? null;
    }
}
