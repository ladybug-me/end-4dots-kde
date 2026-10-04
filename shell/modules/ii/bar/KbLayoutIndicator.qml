pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Loader {
    id: root

    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant

    function abbreviateLayoutCode(fullCode: string): string {
        return fullCode.split(":").map(layout => {
            const baseLayout = layout.split("-")[0];
            return baseLayout.slice(0, 4);
        }).join("\n");
    }

    active: KbLayout.layouts.length > 1
    visible: active

    sourceComponent: Item {
        implicitWidth: root.vertical ? null : layoutCodeText.implicitWidth
        implicitHeight: root.vertical ? layoutCodeText.implicitHeight : null

        StyledText {
            id: layoutCodeText

            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: root.abbreviateLayoutCode(KbLayout.activeShortLabel)
            font.pixelSize: text.includes("\n") ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.small
            color: root.color
            animateChange: true
        }
    }
}
