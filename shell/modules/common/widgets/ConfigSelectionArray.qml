import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RowLayout {
    id: root
    property string text: ""
    property string icon: ""
    property list<var> options: [
        {
            "displayName": "Option 1",
            "icon": "check",
            "value": 1
        },
        {
            "displayName": "Option 2",
            "icon": "close",
            "value": 2
        },
    ]
    property var currentValue: null
    property bool textOnlyWhenActive: false

    signal selected(var newValue)

    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    RowLayout {
        spacing: 10
        visible: root.text !== ""
        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
    }

    Flow {
        id: buttonsFlow
        Layout.fillWidth: !root.text
        Layout.alignment: Qt.AlignRight
        spacing: 2
        Layout.preferredWidth: root.textOnlyWhenActive ? singleRowWidth() : implicitWidth
        Layout.minimumWidth: root.textOnlyWhenActive ? Layout.preferredWidth : 0
        Layout.preferredHeight: root.textOnlyWhenActive ? singleRowHeight() : implicitHeight
        Layout.maximumHeight: root.textOnlyWhenActive ? Layout.preferredHeight : Number.POSITIVE_INFINITY
        clip: root.textOnlyWhenActive

        function singleRowHeight() {
            let h = 0;
            for (let i = 0; i < children.length; i++) {
                const c = children[i];
                if (c.modelData === undefined) continue;
                h = Math.max(h, c.implicitHeight);
            }
            return h;
        }

        function singleRowWidth() {
            let total = 0;
            let count = 0;
            for (let i = 0; i < children.length; i++) {
                const c = children[i];
                if (c.modelData === undefined) continue;
                total += c.implicitWidth;
                count++;
            }
            return total + Math.max(0, count - 1) * spacing;
        }

        Repeater {
            model: root.options
            delegate: SelectionGroupButton {
                id: paletteButton
                required property var modelData
                required property int index
                onYChanged: {
                    if (index === 0) {
                        paletteButton.leftmost = true
                    } else {
                        var prev = buttonsFlow.children[index - 1]
                        var thisIsOnNewLine = prev && prev.y !== paletteButton.y
                        paletteButton.leftmost = thisIsOnNewLine
                        prev.rightmost = thisIsOnNewLine
                    }
                }
                enableImplicitWidthAnimation: !root.textOnlyWhenActive
                Behavior on implicitWidth {
                    enabled: root.textOnlyWhenActive
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                baseWidth: root.textOnlyWhenActive
                    ? contentItem.children[0].implicitWidth + (buttonText.length > 0 ? contentItem.spacing + contentItem.children[1].children[0].implicitWidth : 0) + horizontalPadding * 2
                    : contentItem.implicitWidth + horizontalPadding * 2
                leftmost: index === 0
                rightmost: index === root.options.length - 1
                buttonIcon: modelData.icon || ""
                buttonText: (!root.textOnlyWhenActive || toggled || hovered) ? modelData.displayName : ""
                toggled: root.currentValue == modelData.value
                onClicked: {
                    root.selected(modelData.value);
                }
            }
        }
    }
}