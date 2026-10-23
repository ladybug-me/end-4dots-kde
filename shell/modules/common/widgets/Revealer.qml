import qs.modules.common
import QtQuick

/**
 * Recreation of GTK revealer. Expects one single child.
 */
Item {
    id: root
    property bool reveal
    property bool vertical: false
    clip: true

    readonly property Item child: children.length > 0 ? children[0] : null
    readonly property real childWidth: child ? child.implicitWidth : 0
    readonly property real childHeight: child ? child.implicitHeight : 0

    implicitWidth: (reveal || vertical) ? childWidth : 0
    implicitHeight: (reveal || !vertical) ? childHeight : 0

    visible: reveal || (implicitWidth > 0 && !vertical) || (implicitHeight > 0 && vertical)

    Behavior on implicitWidth {
        enabled: !vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        enabled: vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
}