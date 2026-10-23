import QtQuick
import qs.services
import qs.modules.common
import "WorldMapDots.js" as WorldMapDots
import "WorldCities.js" as WorldCities

Item {
    id: root
    clip: true

    property real dotSize: 2.2
    property color dotColor: Appearance.colors.colLayer0Border 
    property color markerColor: Appearance.colors.colPrimary
    property color glowColorCenter: "transparent"
    property color glowColorEdge: "transparent"

    implicitWidth: 600
    implicitHeight: 300

    function projectX(lon) { return ((lon + 180) / 360) * width }
    function projectY(lat) { return ((90 - lat) / 180) * height }

    function findCityCoords(cityName) {
        if (!cityName || cityName.length === 0) return null
        const key = cityName.trim().toLowerCase()
        if (WorldCities.cityCoords[key]) return WorldCities.cityCoords[key]

        for (const name in WorldCities.cityCoords) {
            if (name.includes(key) || key.includes(name)) return WorldCities.cityCoords[name]
        }
        return null
    }

    function nearestCity(lat, lon) {
        let bestName = null
        let bestCoords = null
        let bestDist = Infinity

        for (const name in WorldCities.cityCoords) {
            const c = WorldCities.cityCoords[name]
            const dLat = c.lat - lat
            const dLon = c.lon - lon
            const dist = dLat * dLat + dLon * dLon
            if (dist < bestDist) {
                bestDist = dist
                bestCoords = c
                bestName = name
            }
        }
        return bestCoords ? { lat: bestCoords.lat, lon: bestCoords.lon, name: bestName } : null
    }

    readonly property bool gpsFixValid: Weather.gpsActive && Weather.location.valid
        && !(Weather.location.lat === 0 && Weather.location.lon === 0)

    readonly property var gpsSnapped: root.gpsFixValid
        ? root.nearestCity(Weather.location.lat, Weather.location.lon)
        : null

    readonly property var cityFallback: findCityCoords(Config.options.bar.weather.city)
    readonly property var markerCoords: root.gpsFixValid ? root.gpsSnapped : root.cityFallback
    readonly property bool hasMarker: root.markerCoords !== null
        && isFinite(root.markerCoords.lat) && isFinite(root.markerCoords.lon)
        && root.width > 0 && root.height > 0

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var grad = ctx.createRadialGradient(
                width * 0.5, height * 0.45, 0,
                width * 0.5, height * 0.45, Math.max(width, height) * 0.8
            )
            grad.addColorStop(0, root.glowColorCenter)
            grad.addColorStop(1, root.glowColorEdge)
            ctx.fillStyle = grad
            ctx.fillRect(0, 0, width, height)

            ctx.fillStyle = root.dotColor
            var dots = WorldMapDots.landDots
            var r = root.dotSize / 2
            for (var i = 0; i < dots.length; i += 2) {
                var px = root.projectX(dots[i])
                var py = root.projectY(dots[i + 1])
                ctx.beginPath()
                ctx.arc(px, py, r, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        Component.onCompleted: requestPaint()
    }

    Item {
        id: marker
        visible: root.hasMarker
        x: root.hasMarker ? root.projectX(root.markerCoords.lon) - width / 2 : 0
        y: root.hasMarker ? root.projectY(root.markerCoords.lat) - height / 2 : 0
        width: 14
        height: 14

        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: 14
            height: 14
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: root.markerColor
            opacity: 0.8

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 0.5; to: 2.2; duration: 1400; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.7; to: 0.0; duration: 1400; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            id: core
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: width / 2
            color: root.markerColor

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.4; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.4; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
        }
    }

    StyledText {
        visible: root.hasMarker && root.gpsFixValid
        x: marker.x + marker.width + 4
        y: marker.y - 2
        text: root.gpsSnapped?.name ?? ""
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: root.markerColor
        opacity: 0.85
    }

    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onDotColorChanged: canvas.requestPaint()
    onDotSizeChanged: canvas.requestPaint()
}