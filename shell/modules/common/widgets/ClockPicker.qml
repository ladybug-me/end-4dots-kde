import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root
    implicitWidth: 200
    implicitHeight: 200

    property int value: 25
    property bool running: false
    signal dragFinished(int val)

    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real radius: Math.min(width, height) / 2 - 10
    readonly property real angle: (value / 60) * 2 * Math.PI - Math.PI / 2

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Appearance.colors.colLayer1
    }

    Repeater {
        model: 12
        delegate: Item {
            id: tickDelegate
            required property int index
            readonly property int minuteVal: (index + 1) * 5
            readonly property real tickAngle: ((index + 1) / 12) * 2 * Math.PI - Math.PI / 2
            readonly property real numR: root.radius - 18
            readonly property bool isSelected: root.value === minuteVal

            Rectangle {
                x: root.centerX + numR * Math.cos(tickDelegate.tickAngle) - width / 2
                y: root.centerY + numR * Math.sin(tickDelegate.tickAngle) - height / 2
                width: 28
                height: 28
                radius: 14
                color: (root.running && tickDelegate.isSelected)
                    ? Appearance.colors.colPrimary
                    : "transparent"
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                StyledText {
                    id: numText
                    anchors.centerIn: parent
                    visible: !tickDelegate.isSelected || root.running
                    text: tickDelegate.minuteVal === 60 ? "60" : tickDelegate.minuteVal.toString()
                    font.pixelSize: 11
                    font.weight: 700
                    color: (root.running && tickDelegate.isSelected)
                        ? Appearance.colors.colOnPrimary
                        : Appearance.colors.colSubtext
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }

            Rectangle {
                readonly property real tickR: root.radius - 4
                x: root.centerX + tickR * Math.cos(tickDelegate.tickAngle) - width / 2
                y: root.centerY + tickR * Math.sin(tickDelegate.tickAngle) - height / 2
                width: tickDelegate.minuteVal % 15 === 0 ? 5 : 3
                height: width
                radius: width / 2
                visible: !(root.running && tickDelegate.isSelected)
                color: tickDelegate.isSelected
                    ? Appearance.colors.colPrimary
                    : ColorUtils.transparentize(Appearance.colors.colSubtext, 0.5)
            }
        }
    }

    Canvas {
        id: handCanvas
        anchors.fill: parent
        visible: !root.running
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const cx = root.centerX;
            const cy = root.centerY;
            const angle = root.angle;
            const handLen = root.radius - 30;
            const tipX = cx + handLen * Math.cos(angle);
            const tipY = cy + handLen * Math.sin(angle);
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(tipX, tipY);
            ctx.strokeStyle = Qt.rgba(
                Appearance.colors.colPrimary.r,
                Appearance.colors.colPrimary.g,
                Appearance.colors.colPrimary.b,
                0.9
            );
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.stroke();
        }
        Connections {
            target: root
            function onAngleChanged() { handCanvas.requestPaint() }
            function onValueChanged() { handCanvas.requestPaint() }
        }
        Connections {
            target: Appearance
            function onColorsChanged() { handCanvas.requestPaint() }
        }
    }

    Rectangle {
        width: 8
        height: 8
        radius: 4
        color: Appearance.colors.colPrimary
        anchors.centerIn: parent
        z: 2
        visible: !root.running
    }

    Rectangle {
        id: handTip
        width: 28
        height: 28
        radius: 14
        color: Appearance.colors.colPrimary
        z: 2
        visible: !root.running
        x: root.centerX + (root.radius - 30) * Math.cos(root.angle) - width / 2
        y: root.centerY + (root.radius - 30) * Math.sin(root.angle) - height / 2

        StyledText {
            anchors.centerIn: parent
            text: root.value.toString()
            font.pixelSize: 9
            font.weight: 700
            color: Appearance.colors.colOnPrimary
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: root.running
        spacing: 2

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: {
                let m = Math.floor(TimerService.pomodoroSecondsLeft / 60).toString().padStart(2, '0');
                let s = Math.floor(TimerService.pomodoroSecondsLeft % 60).toString().padStart(2, '0');
                return `${m}:${s}`;
            }
            font.pixelSize: 36
            font.weight: 700
            font.features: { "tnum": 1 }
            color: Appearance.m3colors.m3onSurface
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.running
        cursorShape: Qt.PointingHandCursor

        function angleToValue(mx, my) {
            const dx = mx - root.centerX;
            const dy = my - root.centerY;
            let a = Math.atan2(dy, dx) + Math.PI / 2;
            if (a < 0) a += 2 * Math.PI;
            const raw = (a / (2 * Math.PI)) * 60;
            const snapped = Math.round(raw / 5) * 5;
            return snapped === 0 ? 60 : snapped;
        }

        onPressed: event => {
            root.value = angleToValue(event.x, event.y);
        }
        onPositionChanged: event => {
            if (!pressed) return;
            root.value = angleToValue(event.x, event.y);
        }
        onReleased: {
            root.dragFinished(root.value);
        }
    }
}