pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
import qs.modules.common
import qs.modules.common.functions

/**
 * Clipboard service backed by C++ ClipboardManager.
 */
Singleton {
    id: root

    property string cliphistBinary: "cliphist"
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search?.sloppy ?? false
    property real scoreThreshold: 0.2

    property list<string> entries: []
    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
    }))

    readonly property string imageCacheDir: ClipboardManager.imageCacheDir
    readonly property bool available: ClipboardManager.available

    function fuzzyQuery(search: string): var {
        if (!search || search.trim() === "")
            return entries;

        if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score);
            return results.map(item => item.entry);
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => r.obj.entry);
    }

    function entryIsImage(entry: string): bool {
        if (!entry)
            return false;
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry));
    }

    function refresh(): void {
        ClipboardManager.reload();
    }

    function copy(entry: string): void {
        if (!entry)
            return;
        Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`]);
    }

    function paste(entry: string): void {
        if (!entry)
            return;
        Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && wl-paste`]);
    }

    function superpaste(count: int, isImage: var): void {
        const targetEntries = entries.filter(entry => {
            if (!isImage)
                return true;
            return entryIsImage(entry);
        }).slice(0, count);
        const pasteCommands = [...targetEntries].reverse().map(entry => `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`);
        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    function deleteEntry(entry: string): void {
        if (!entry)
            return;
        deleteProc.deleteEntry(entry);
    }

    function wipe(): void {
        ClipboardManager.clearHistory();
    }

    Process {
        id: deleteProc

        property string entry: ""

        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]

        function deleteEntry(targetEntry: string): void {
            deleteProc.entry = targetEntry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }

        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function syncEntries(): void {
        const items = ClipboardManager.items;
        if (!items)
            return;
        root.entries = items.map(item => item.text || "");
    }

    Connections {
        target: ClipboardManager

        function onItemsChanged(): void {
            root.syncEntries();
        }
    }

    Connections {
        target: Quickshell

        function onClipboardTextChanged(): void {
            delayedUpdateTimer.restart();
        }
    }

    Timer {
        id: delayedUpdateTimer

        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 200
        repeat: false

        onTriggered: {
            root.refresh();
        }
    }

    Component.onCompleted: {
        root.refresh();
    }
}
