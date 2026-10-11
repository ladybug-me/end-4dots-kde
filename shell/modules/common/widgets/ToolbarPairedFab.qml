pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property alias iconText: fabWidget.iconText
    default property alias fabData: fabWidget.data
    property bool enableShadow: true

    signal clicked(event: var)

    implicitWidth: fabWidget.implicitWidth
    implicitHeight: fabWidget.implicitHeight

    anchors {
        verticalCenter: parent.verticalCenter
    }

    StyledRectangularShadow {
        visible: root.enableShadow
        target: fabWidget
        radius: fabWidget.buttonRadius
    }

    FloatingActionButton {
        id: fabWidget

        baseSize: 48
        colBackground: Appearance.colors.colTertiaryContainer
        colBackgroundHover: Appearance.colors.colTertiaryContainerHover
        colRipple: Appearance.colors.colTertiaryContainerActive
        colOnBackground: Appearance.colors.colOnTertiaryContainer

        onClicked: e => root.clicked(e)
    }
}