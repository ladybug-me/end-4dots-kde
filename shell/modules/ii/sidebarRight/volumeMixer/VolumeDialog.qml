pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.services
import qs.utils
import qs.modules.common
import qs.modules.common.widgets

WindowDialog {
    id: root
    property bool isSink: true
    backgroundHeight: 600

    WindowDialogTitle {
        text: root.isSink ? Translation.tr("Audio output") : Translation.tr("Audio input")
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    VolumeDialogContent {
        isSink: root.isSink
    }

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Launch.exec(["bash", "-c", `${Config.options.apps.volumeMixer}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
