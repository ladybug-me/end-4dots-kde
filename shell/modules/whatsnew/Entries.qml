import QtQuick
import Quickshell

QtObject {
    readonly property string assetDir: "../../assets/whatsnew/"

    readonly property var list: [
        {
            "id": "desktop_context_menu",
            "revision": 27,
            "icon": "mouse",
            "title": qsTr("Desktop Context Menus"),
            "description": qsTr("Desktop icons now feature a dedicated right-click context menu. You can rename the icon directly or send it to the trash right from the desktop.")
        },
        {
            "id": "clock_calendar",
            "revision": 28,
            "icon": "calendar_month",
            "title": qsTr("Calendar Popout"),
            "settingsPage": "panels",
            "settingsSubPage": 11,
            "description": qsTr("Hovering the clock now shows a mini calendar with a month grid, today highlighted, and month navigation. Click the title to jump back to today. Enable this feature in Settings -> Panels -> Taskbar -> Clock.")
        },
        {
            "id": "status_icons_context_menu",
            "revision": 29,
            "icon": "more_vert",
            "title": qsTr("Status Icons Context Menu"),
            "settingsPage": "panels",
            "settingsSubPage": 10,
            "description": qsTr("Right-clicking the status icons block in the bar now opens a context menu popout with a shortcut to the Status Icons configuration page, where you can reorder or toggle them.")
        },
        {
            "id": "network_multiple_profiles",
            "revision": 30,
            "icon": "wifi",
            "title": qsTr("Multiple Wi-Fi Profiles"),
            "settingsPage": "network",
            "settingsSubPage": 6,
            "description": qsTr("You can now manage multiple saved profiles (e.g. DHCP and static IP) for the same Wi-Fi network (SSID). The Saved Networks page lists one row per profile, allowing you to edit, autoconnect, or forget them individually.")
        },
        {
            "id": "manual_light_dark_mode",
            "revision": 31,
            "icon": "contrast",
            "title": qsTr("Manual Light/Dark Mode"),
            "settingsPage": "appearance",
            "settingsSubPage": 3,
            "description": qsTr("A manual light/dark mode selector has been added to the colors page, allowing you to override the automatic theme switching. Open Settings -> Appearance -> Colors -> Advanced Settings to manually set the light/dark mode. Alternatively, you can open launcher -> Type > -> Select light/dark mode.")
        }
    ]

    function mediaSource(entry: var): url {
        if (!entry || !entry.mediaUrl)
            return "";
        if (entry.mediaUrl.startsWith("root:"))
            return Qt.resolvedUrl(`${Quickshell.shellDir}${entry.mediaUrl.slice("root:".length)}`);
        return Qt.resolvedUrl(`${assetDir}${entry.mediaUrl}`);
    }
}
