pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string scriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/system-appearance.sh`)

    property int iconRevision: 0
    property string startupIconTheme: ""
    property var resolvedIcons: ({})
    readonly property var iconQueue: ({ names: [] })

    readonly property string iconResolverPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/icon-resolve.py`)

    function defaultIconPath(name, fallback) {
        return fallback === undefined ? Quickshell.iconPath(name) : Quickshell.iconPath(name, fallback)
    }

    function iconPath(name, fallback) {
        void root.iconRevision
        const usesStartupTheme = root.startupIconTheme === "" || root.iconTheme === root.startupIconTheme
        if (usesStartupTheme || !name || name.startsWith("/") || name.startsWith("file:")) {
            return root.defaultIconPath(name, fallback)
        }
        const themeIcons = root.resolvedIcons[root.iconTheme]
        if (themeIcons && name in themeIcons) {
            const found = themeIcons[name]
            if (found !== "") return "file://" + found
            return fallback === true ? "" : root.defaultIconPath(name, fallback)
        }
        root.queueIcon(name)
        return root.defaultIconPath(name, fallback)
    }

    function queueIcon(name) {
        if (root.iconQueue.names.includes(name)) return
        root.iconQueue.names.push(name)
        resolveTimer.restart()
    }

    Timer {
        id: resolveTimer
        interval: 30
        onTriggered: root.resolvePending()
    }

    function resolvePending() {
        if (resolveProc.running || root.iconQueue.names.length === 0) return
        resolveProc.theme = root.iconTheme
        resolveProc.names = root.iconQueue.names.splice(0)
        resolveProc.command = ["python3", root.iconResolverPath, resolveProc.theme].concat(resolveProc.names)
        resolveProc.running = true
    }

    Process {
        id: resolveProc
        property string theme: ""
        property var names: []
        stdout: StdioCollector {
            id: resolveOutput
        }
        onExited: (code, status) => {
            try {
                const found = JSON.parse(resolveOutput.text)
                const merged = Object.assign({}, root.resolvedIcons[resolveProc.theme] ?? {}, found)
                const all = Object.assign({}, root.resolvedIcons)
                all[resolveProc.theme] = merged
                root.resolvedIcons = all
                root.iconRevision += 1
            } catch (e) {
                console.log("[SystemAppearance] icon resolve failed", code, e)
            }
            if (root.iconQueue.names.length > 0) resolveTimer.restart()
        }
    }

    Timer {
        id: iconRefreshTimer
        interval: 400
        onTriggered: {
            root.iconRevision += 1
        }
    }

    property var iconThemes: []
    property var cursorThemes: []
    property var fonts: []

    property string iconTheme: ""
    property string cursorTheme: ""
    property int cursorSize: 24
    property string fontFamily: ""
    property int fontSize: 11
    property string monoFamily: ""
    property int monoSize: 11

    function toOptions(list) {
        return list.map(name => ({ displayName: name, value: name }))
    }

    function fontOptions(current) {
        const options = root.toOptions(root.fonts)
        if (current && !root.fonts.includes(current)) options.unshift({ displayName: current, value: current })
        return options
    }

    function refresh() {
        iconsProc.running = true
        cursorsProc.running = true
        fontsProc.running = true
        currentProc.running = true
    }

    function run(args) {
        const proc = applyComponent.createObject(root, { command: ["bash", root.scriptPath].concat(args) })
        proc.running = true
    }

    Component {
        id: applyComponent
        Process {
            id: applyProc
            onExited: (code, status) => {
                if (applyProc.command.includes("--set-icons")) iconRefreshTimer.restart()
                applyProc.destroy()
            }
        }
    }

    function setIcons(name) {
        root.iconTheme = name
        root.run(["--set-icons", name])
    }

    function setCursor(name, size) {
        root.cursorTheme = name
        root.cursorSize = size
        root.run(["--set-cursor", name, String(size)])
    }

    function setFont(role, family, size) {
        if (role === "mono") {
            root.monoFamily = family
            root.monoSize = size
        } else {
            root.fontFamily = family
            root.fontSize = size
        }
        root.run(["--set-font", role, family, String(size)])
    }

    function lines(text) {
        return text.split("\n").map(line => line.trim()).filter(line => line.length > 0)
    }

    Process {
        id: iconsProc
        command: ["bash", root.scriptPath, "--list-icons"]
        stdout: StdioCollector {
            onStreamFinished: root.iconThemes = root.lines(text)
        }
    }

    Process {
        id: cursorsProc
        command: ["bash", root.scriptPath, "--list-cursors"]
        stdout: StdioCollector {
            onStreamFinished: root.cursorThemes = root.lines(text)
        }
    }

    Process {
        id: fontsProc
        command: ["bash", root.scriptPath, "--list-fonts"]
        stdout: StdioCollector {
            onStreamFinished: root.fonts = root.lines(text)
        }
    }

    Process {
        id: currentProc
        command: ["bash", root.scriptPath, "--get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.iconTheme = data.icons
                    if (root.startupIconTheme === "") root.startupIconTheme = data.icons
                    root.cursorTheme = data.cursor
                    root.cursorSize = data.cursorSize
                    root.fontFamily = data.fontFamily
                    root.fontSize = data.fontSize
                    root.monoFamily = data.monoFamily
                    root.monoSize = data.monoSize
                } catch (e) {
                    console.log("Failed to read system appearance:", e)
                }
            }
        }
    }

    FileView {
        path: FileUtils.trimFileProtocol(`${Directories.config}/kdeglobals`)
        watchChanges: true
        onFileChanged: {
            currentProc.running = true
        }
    }

    Component.onCompleted: root.refresh()
}
