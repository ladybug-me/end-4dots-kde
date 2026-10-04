pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme(): void {
        themeFileView.reload()
    }

    function applyColors(fileContent: string): void {
        if (!fileContent || fileContent.trim().length === 0)
            return

        try {
            const data = JSON.parse(fileContent)
            const colours = data.colours || data
            for (const key in colours) {
                if (colours.hasOwnProperty(key)) {
                    let hex = String(colours[key]).trim()
                    if (!hex.startsWith("#"))
                        hex = "#" + hex

                    let normalizedKey = key
                    if (normalizedKey.includes("_"))
                        normalizedKey = normalizedKey.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())

                    const propKey = normalizedKey.startsWith("term") || normalizedKey.startsWith("m3")
                        ? normalizedKey
                        : ("m3" + normalizedKey)

                    Appearance.m3colors[propKey] = hex
                }
            }

            if (typeof data.mode === "string") {
                Appearance.m3colors.darkmode = (data.mode === "dark")
            } else if (Appearance.m3colors.m3background) {
                Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
            }
        } catch (e) {
            console.warn("[MaterialThemeLoader] Failed to parse scheme JSON:", e)
        }
    }

    function resetFilePathNextTime(): void {
        resetFilePathNextWallpaperChange.enabled = true
    }

    function toggleLightDark(): void {
        const currentlyDark = Appearance.m3colors.darkmode
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", currentlyDark ? "light" : "dark", "--noswitch"])
    }

    Connections {
        id: resetFilePathNextWallpaperChange

        function onWallpaperPathChanged(): void {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }

        target: Config.options.background
        enabled: false
    }

    Timer {
        id: delayedFileRead

        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false

        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    FileView {
        id: themeFileView

        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true

        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: root.resetFilePathNextTime()
    }

    GlobalShortcut {
        name: "toggleLightDark"
        description: "Toggles between dark theme and light theme"

        onPressed: {
            root.toggleLightDark()
        }
    }

    IpcHandler {
        function toggleLightDark(): void {
            root.toggleLightDark()
        }

        target: "theme"
    }
}

