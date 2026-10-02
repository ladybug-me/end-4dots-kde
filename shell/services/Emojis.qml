pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Services
import qs.modules.common
import qs.modules.common.functions

/**
 * Emojis service backed by Caelestia C++ EmojiDb.
 */
Singleton {
    id: root

    property list<var> list: []
    readonly property bool loaded: EmojiDb.loaded
    readonly property int count: EmojiDb.count

    function fuzzyQuery(search: string): var {
        if (!search || search.trim() === "")
            return root.list;
        return EmojiDb.search(search, 100).map(item => `${item.ch}  ${item.name}`);
    }

    function recordUsage(ch: string): void {
        EmojiDb.recordUsage(ch);
    }

    function load(): void {
        root.refresh();
    }

    function refresh(): void {
        const items = EmojiDb.getSortedItems([], 500);
        root.list = items.map(item => `${item.ch}  ${item.name}`);
    }

    Connections {
        target: EmojiDb

        function onLoadedChanged(): void {
            root.refresh();
        }
    }

    Component.onCompleted: {
        if (EmojiDb.loaded) {
            root.refresh();
        }
    }
}
