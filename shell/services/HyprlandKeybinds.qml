pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Services

Singleton {
    id: root

    property list<var> keybinds: []
    property list<string> keybindCategories: []

    function parseModMask(sequence: string): int {
        let mask = 0;
        const parts = sequence.split("+");
        for (let i = 0; i < parts.length - 1; i++) {
            const mod = parts[i].trim().toLowerCase();
            if (mod === "ctrl" || mod === "control")
                mask |= (1 << 2);
            else if (mod === "super" || mod === "meta" || mod === "win")
                mask |= (1 << 6);
            else if (mod === "shift")
                mask |= (1 << 0);
            else if (mod === "alt")
                mask |= (1 << 3);
        }
        return mask;
    }

    function parseKey(sequence: string): string {
        const parts = sequence.split("+");
        return parts.length > 0 ? parts[parts.length - 1].trim() : "";
    }

    function updateKeybinds(): void {
        const raw = KeybindsModel.keybinds || [];
        const parsed = [];
        const categories = [];

        for (let i = 0; i < raw.length; i++) {
            const item = raw[i];
            const bindStr = item.bind || "";
            if (!bindStr)
                continue;

            const desc = item.description || item.name || item.action || "";
            const modmask = root.parseModMask(bindStr);
            const key = root.parseKey(bindStr);

            parsed.push({
                description: desc,
                key: key,
                modmask: modmask,
                action: item.action || item.name || ""
            });

            const colonIdx = desc.indexOf(":");
            if (colonIdx > 0) {
                const group = desc.substring(0, colonIdx).trim();
                if (group.length > 0 && !categories.includes(group))
                    categories.push(group);
            }
        }

        root.keybinds = parsed;
        root.keybindCategories = categories;
    }

    Component.onCompleted: root.updateKeybinds()

    Connections {
        function onKeybindsChanged(): void {
            root.updateKeybinds();
        }

        target: KeybindsModel
    }
}
