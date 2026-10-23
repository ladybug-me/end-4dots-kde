import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    readonly property string description: {
        const text = Weather.data?.description ?? "";
        return text.length > 0 ? text.charAt(0).toUpperCase() + text.slice(1) : "";
    }

    ColumnLayout {
        id: mainLayout
        implicitWidth: 340
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroLayout.implicitHeight + 32
            radius: Appearance.rounding.large
            bottomLeftRadius: Appearance.rounding.small
            bottomRightRadius: Appearance.rounding.small
            color: Appearance.colors.colPrimaryContainer

            ColumnLayout {
                id: heroLayout
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 0

                        RowLayout {
                            spacing: 4

                            MaterialSymbol {
                                text: "location_on"
                                fill: 1
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnPrimaryContainer
                            }

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: Weather.data?.city ?? ""
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        StyledText {
                            text: Weather.data?.temp ?? "--°"
                            font.family: Appearance.font.family.expressive
                            font.pixelSize: 64
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.description
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        StyledText {
                            visible: (Weather.data?.tempFeelsLike ?? "") !== ""
                            text: Translation.tr("Feels like %1").arg(Weather.data?.tempFeelsLike ?? "")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.75
                        }
                    }

                    MaterialShapeWrappedMaterialSymbol {
                        Layout.alignment: Qt.AlignTop
                        shape: MaterialShape.Shape.Sunny
                        text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                        fill: 1
                        iconSize: 44
                        implicitSize: 92
                        color: Appearance.colors.colPrimary
                        colSymbol: Appearance.colors.colOnPrimary
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    SunChip {
                        icon: "wb_twilight"
                        label: Weather.data?.sunrise ?? "--"
                    }

                    SunChip {
                        icon: "bedtime"
                        label: Weather.data?.sunset ?? "--"
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 4
            columnSpacing: 4
            uniformCellWidths: true

            WeatherCard {
                title: Translation.tr("Rain?")
                symbol: "rainy"
                value: Weather.data?.cr ?? "--"
                shape: MaterialShape.Shape.Pentagon
                shapeColor: Appearance.colors.colSecondaryContainer
                symbolColor: Appearance.colors.colOnSecondaryContainer
            }
            WeatherCard {
                title: Translation.tr("Wind")
                symbol: "air"
                value: `${Weather.data?.wind ?? "--"}`
                shape: MaterialShape.Shape.Clover4Leaf
                shapeColor: Appearance.colors.colTertiaryContainer
                symbolColor: Appearance.colors.colOnTertiaryContainer
            }
            WeatherCard {
                title: Translation.tr("Precipitation")
                symbol: "rainy_light"
                value: Weather.data?.precip ?? "--"
                shape: MaterialShape.Shape.Cookie6Sided
                shapeColor: Appearance.colors.colPrimaryContainer
                symbolColor: Appearance.colors.colOnPrimaryContainer
            }
            WeatherCard {
                title: Translation.tr("Humidity")
                symbol: "humidity_low"
                value: Weather.data?.humidity ?? "--"
                shape: MaterialShape.Shape.Puffy
                shapeColor: Appearance.colors.colSecondaryContainer
                symbolColor: Appearance.colors.colOnSecondaryContainer
            }
            WeatherCard {
                title: Translation.tr("Visibility")
                symbol: "visibility"
                value: Weather.data?.visib ?? "--"
                shape: MaterialShape.Shape.Gem
                shapeColor: Appearance.colors.colTertiaryContainer
                symbolColor: Appearance.colors.colOnTertiaryContainer
            }
            WeatherCard {
                title: Translation.tr("Pressure")
                symbol: "readiness_score"
                value: Weather.data?.press ?? "--"
                shape: MaterialShape.Shape.Cookie4Sided
                shapeColor: Appearance.colors.colPrimaryContainer
                symbolColor: Appearance.colors.colOnPrimaryContainer
            }
        }
    }

    component SunChip: Rectangle {
        id: chip
        required property string icon
        required property string label
        implicitWidth: chipRow.implicitWidth + 20
        implicitHeight: chipRow.implicitHeight + 10
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                text: chip.icon
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnPrimary
            }

            StyledText {
                text: chip.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnPrimary
            }
        }
    }
}
