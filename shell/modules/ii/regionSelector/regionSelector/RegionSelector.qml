pragma ComponentBehavior: Bound

import ".."
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs
import qs.components.misc
import qs.services
import qs.modules.common

Scope {
    id: root

    property bool screenshotActive: false

    onScreenshotActiveChanged: {
        GlobalStates.regionSelectorOpen = root.screenshotActive;
    }

    function dismiss(): void {
        root.screenshotActive = false;
    }

    property var action: ScreenshotAction.SnipAction.Copy

    property var selectionMode: RegionSelection.SelectionMode.RectCorners

    property bool showWindowOutlines: false

    Settings {
        property alias showWindowOutlines: root.showWindowOutlines

        category: "Screenshot"
    }

    Variants {
        model: Quickshell.screens

        delegate: Loader {
            id: regionSelectorLoader

            required property var modelData

            active: root.screenshotActive && modelData.name === Kwin.cursorOutputName()

            sourceComponent: RegionSelection {
                screen: regionSelectorLoader.modelData
                onDismiss: root.dismiss()
                action: root.action
                selectionMode: root.selectionMode
                showWindowOutlines: root.showWindowOutlines
                onShowWindowOutlinesChanged: root.showWindowOutlines = showWindowOutlines
            }
        }
    }

    function screenshot(): void {
        root.action = ScreenshotAction.SnipAction.Copy;
        root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        root.screenshotActive = true;
    }

    function search(): void {
        root.action = ScreenshotAction.SnipAction.Search;
        root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        root.screenshotActive = true;
    }

    function ocr(): void {
        root.action = ScreenshotAction.SnipAction.CharRecognition;
        root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        root.screenshotActive = true;
    }

    function record(): void {
        root.action = ScreenshotAction.SnipAction.Record;
        root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        if (root.screenshotActive) root.screenshotActive = false;
        root.screenshotActive = true;
    }

    function recordWithSound(): void {
        root.action = ScreenshotAction.SnipAction.RecordWithSound;
        root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        if (root.screenshotActive) root.screenshotActive = false;
        root.screenshotActive = true;
    }

    IpcHandler {
        target: "region"

        function screenshot(): void {
            root.screenshot();
        }

        function search(): void {
            root.search();
        }

        function ocr(): void {
            root.ocr();
        }

        function record(): void {
            root.record();
        }

        function recordWithSound(): void {
            root.recordWithSound();
        }
    }

    IpcHandler {
        target: "regionSelector"

        function screenshot(): void {
            root.screenshot();
        }

        function search(): void {
            root.search();
        }

        function ocr(): void {
            root.ocr();
        }

        function record(): void {
            root.record();
        }

        function recordWithSound(): void {
            root.recordWithSound();
        }
    }

    CustomShortcut {
        name: "regionScreenshot"
        description: qsTr("Takes a screenshot of the selected region")
        onPressed: root.screenshot()
    }

    CustomShortcut {
        name: "regionSearch"
        description: qsTr("Searches the selected region")
        onPressed: root.search()
    }

    CustomShortcut {
        name: "regionOcr"
        description: qsTr("Recognizes text in the selected region")
        onPressed: root.ocr()
    }

    CustomShortcut {
        name: "regionRecord"
        description: qsTr("Records the selected region")
        onPressed: root.record()
    }

    CustomShortcut {
        name: "regionRecordWithSound"
        description: qsTr("Records the selected region with sound")
        onPressed: root.recordWithSound()
    }
}
