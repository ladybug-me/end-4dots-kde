pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Services
import qs.services
import qs.modules.common

Singleton {
    id: root

    property list<var> apps: {
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const window of Kwin.windowList) {
            let appId = window.class || "";
            if (ignoredRegexes.some(re => re.test(appId))) continue;
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            
            // Map the KWin window to match the expected Quickshell Toplevel structure
            let mappedWindow = {
                appId: appId,
                title: window.title,
                address: window.address,
                activated: window.focused,
                isMinimized: window.minimized,
                isMaximized: window.maximized,
                isFullscreen: window.fullscreen,
                activate: function() {
                    Kwin.focusWindow(window.address);
                },
                close: function() {
                    Kwin.closeWindow(window.address);
                }
            };
            
            map.get(appId.toLowerCase()).toplevels.push(mappedWindow);
        }

        var values = [];

        for (const [key, value] of map) {
            values.push(appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned }));
        }

        return values;
    }

    function isPinned(appId) {
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    Component {
        id: appEntryComp

        TaskbarAppEntry {}
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper

        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
}
