pragma ComponentBehavior: Bound

import ".."
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.services

Toolbar {
    id: root

    property var action: ScreenshotAction.SnipAction.Copy
    property var selectionMode
    property bool showWindowOutlines: false

    signal dismiss()

    function actionToIndex(act) {
        if (act === ScreenshotAction.SnipAction.Search) return 1;
        if (act === ScreenshotAction.SnipAction.CharRecognition) return 2;
        return 0;
    }

    function indexToAction(idx) {
        if (idx === 1) return ScreenshotAction.SnipAction.Search;
        if (idx === 2) return ScreenshotAction.SnipAction.CharRecognition;
        return ScreenshotAction.SnipAction.Copy;
    }

    IconToolbarButton {
        id: windowSelectorBtn

        Layout.alignment: Qt.AlignVCenter
        text: "desktop_windows"
        toggled: root.showWindowOutlines
        onClicked: {
            root.showWindowOutlines = !root.showWindowOutlines;
        }

        StyledToolTip {
            text: Translation.tr("Window Selector")
        }
    }

    ToolbarTabBar {
        id: tabBar

        tabButtonList: [
            {"icon": "content_cut", "name": Translation.tr("Screenshot")},
            {"icon": "image_search", "name": Translation.tr("Google Lens")},
            {"icon": "text_fields", "name": Translation.tr("Text Recognition")}
        ]
        onCurrentIndexChanged: {
            const act = root.indexToAction(currentIndex);
            if (root.action !== act) {
                root.action = act;
            }
        }
    }

    Connections {
        target: root

        function onActionChanged() {
            const targetIdx = root.actionToIndex(root.action);
            if (tabBar.currentIndex !== targetIdx) {
                tabBar.setCurrentIndex(targetIdx);
            }
        }
    }
}
