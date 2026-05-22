import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// ═══════════════════════════════════════════════════════════════
// BeeWeatherDetail.qml — Weather Detail Panel 🐝🌦️
// Opens as PanelWindow overlay from MayaDash or BeeBar click
// Shows: Current conditions, Hourly (24h), 7-Day forecast
// Glassmorphism style consistent with BeeCalendar detail
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: weatherDetail

    width: 760
    height: 620
    color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.97)
    radius: 16
    border.color: BeeTheme.glassBorder
    border.width: 1.5

    // ─── i18n helpers ─────────────────────────────────────────
    property var tr: BeeConfig.tr.weather || ({})

    function t(key, fallback) {
        return (tr && tr[key]) ? tr[key] : fallback
    }

    // ─── Signal pour fermer le PanelWindow parent ────────────
    signal closeRequested()

    // ─── Reference to BeeWeather singleton ───────────────────
    // Set by parent when creating this component
    property var weatherData: null

    // ─── Convenience aliases ─────────────────────────────────
    property string currentTemp: weatherData ? weatherData.temperature : "—"
    property string currentCondition: weatherData ? weatherData.condition : ""
    property string currentIcon: weatherData ? weatherData.icon : "🌡️"
    property string currentFeelsLike: weatherData ? weatherData.feelsLike : "—"
    property string currentHumidity: weatherData ? weatherData.humidity : "—"
    property string currentWind: weatherData ? (weatherData.windSpeed + " " + weatherData.windDirection) : "—"
    property string currentUV: weatherData ? weatherData.uvIndex : "—"
    property string currentPrecip: weatherData ? weatherData.precipitation : "—"
    property bool currentIsDay: weatherData ? weatherData.isDay : true
    property string cityName: weatherData ? weatherData.city : "Blainville"
    property var hourlyModel: weatherData ? weatherData.hourlyData : []
    property var dailyModel: weatherData ? weatherData.dailyData : []
    property bool isLoading: weatherData ? weatherData.detailLoading : false

    // ─── Trigger detail data fetch on creation ──────────────
    Component.onCompleted: {
        if (weatherData) {
            weatherData.fetchDetailData()
        }
    }

    // ─── Close Button (✕) — Top Right, BeeHive Style ───────
    OverlayCloseButton {
        z: 200
        anchors { right: parent.right; top: parent.top; rightMargin: 14; topMargin: 10 }
        onCloseAction: {
            weatherDetail.closeRequested()
        }
    }

    // ─── Main Content ───────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 16
        anchors.topMargin: 14
        anchors.bottomMargin: 16
        spacing: 12
        clip: true

        // ═══════════════════════════════════════════════════════
        // HEADER — City + Current Temp + Condition
        // ═══════════════════════════════════════════════════════
        Rectangle {
            width: parent.width
            height: 90
            radius: 12
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 600 } }
            Behavior on border.color { ColorAnimation { duration: 600 } }

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 16

                // Large weather icon
                Text {
                    text: weatherDetail.currentIcon
                    font.pixelSize: 52
                    font.family: "Noto Color Emoji"
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: -4; duration: 2500; easing.type: Easing.InOutSine }
                        NumberAnimation { from: -4; to: 0; duration: 2500; easing.type: Easing.InOutSine }
                    }
                }

                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: weatherDetail.cityName
                        color: BeeTheme.textSecondary
                        font.pixelSize: 13
                        font.letterSpacing: 1
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }

                    Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: weatherDetail.currentTemp
                            color: BeeTheme.accent
                            font.pixelSize: 42
                            font.bold: true
                            font.family: "monospace"
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: weatherDetail.currentCondition
                                color: BeeTheme.textPrimary
                                font.pixelSize: 16
                                font.bold: true
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: t("feels_like", "Ressenti") + " " + weatherDetail.currentFeelsLike
                                color: BeeTheme.textSecondary
                                font.pixelSize: 12
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                        }
                    }
                }

                // Night/Day indicator
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24; height: 24
                    Text {
                        anchors.centerIn: parent
                        text: weatherDetail.currentIsDay ? "☀️" : "🌙"
                        font.pixelSize: 20
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        // CURRENT CONDITIONS CARD — Humidity, Wind, UV, Precip
        // ═══════════════════════════════════════════════════════
        Rectangle {
            width: parent.width
            height: 72
            radius: 10
            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.15)
            border.color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.2)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 600 } }
            Behavior on border.color { ColorAnimation { duration: 600 } }

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 0

                // Humidity
                Rectangle {
                    width: parent.width / 5 - 4
                    height: 52
                    radius: 8
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "💧"
                            font.pixelSize: 18
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: weatherDetail.currentHumidity
                            color: BeeTheme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: t("humidity", "Humidité")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 9
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // Wind
                Rectangle {
                    width: parent.width / 5 - 4
                    height: 52
                    radius: 8
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "💨"
                            font.pixelSize: 18
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: weatherDetail.currentWind
                            color: BeeTheme.textPrimary
                            font.pixelSize: 13
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: t("wind", "Vent")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 9
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // UV Index
                Rectangle {
                    width: parent.width / 5 - 4
                    height: 52
                    radius: 8
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "☀️"
                            font.pixelSize: 18
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: weatherDetail.currentUV
                            color: BeeTheme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: t("uv_index", "Indice UV")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 9
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // Precipitation
                Rectangle {
                    width: parent.width / 5 - 4
                    height: 52
                    radius: 8
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "🌧️"
                            font.pixelSize: 18
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: weatherDetail.currentPrecip
                            color: BeeTheme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: t("precipitation", "Précipitations")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 9
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // Snow (ski critical!)
                Rectangle {
                    width: parent.width / 5 - 4
                    height: 52
                    radius: 8
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "⛷️"
                            font.pixelSize: 18
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: weatherDetail.currentSnowDisplay
                            color: BeeTheme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: t("snow", "Neige")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 9
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }
            }
        }

        // ─── Snow display helper ────────────────────────────────
        property string currentSnowDisplay: {
            if (!weatherDetail.dailyModel || weatherDetail.dailyModel.length === 0) return "—"
            // Show today's snowfall from daily data
            var today = weatherDetail.dailyModel[0]
            if (today && today.snow > 0) return today.snow + " cm"
            return "0 cm"
        }

        // ═══════════════════════════════════════════════════════
        // HOURLY FORECAST — Scrollable strip (next 24h)
        // ═══════════════════════════════════════════════════════
        Rectangle {
            width: parent.width
            height: 120
            radius: 10
            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
            border.color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.15)
            border.width: 1
            clip: true

            Behavior on color { ColorAnimation { duration: 600 } }

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Text {
                    text: t("hourly_forecast", "Prévisions horaires")
                    color: BeeTheme.textSecondary
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.5
                    Behavior on color { ColorAnimation { duration: 600 } }
                }

                ListView {
                    id: hourlyList
                    width: parent.width
                    height: parent.height - 22
                    orientation: ListView.Horizontal
                    spacing: 4
                    clip: true
                    model: weatherDetail.hourlyModel
                    snapMode: ListView.SnapToItem

                    delegate: Rectangle {
                        width: 62
                        height: hourlyList.height
                        radius: 8
                        color: model.index === 0
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.08)
                        border.color: model.index === 0
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
                            : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.1)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 300 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: model.index === 0
                                    ? t("now", "Maint.")
                                    : String(modelData.hour).padStart(2, "0") + "h"
                                color: model.index === 0 ? BeeTheme.accent : BeeTheme.textSecondary
                                font.pixelSize: 10
                                font.bold: model.index === 0
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            Text {
                                text: modelData.icon
                                font.pixelSize: 22
                                font.family: "Noto Color Emoji"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: modelData.temp
                                color: BeeTheme.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            // Precipitation probability
                            Text {
                                text: modelData.precipProb > 0 ? modelData.precipProb + "%" : ""
                                color: Qt.rgba(0.4, 0.7, 1.0, 1.0)
                                font.pixelSize: 9
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: modelData.precipProb > 0
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        // 7-DAY FORECAST — Vertical list
        // ═══════════════════════════════════════════════════════
        Rectangle {
            width: parent.width
            height: parent.height - 90 - 72 - 120 - 12 * 3 - 10  // remaining space
            radius: 10
            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
            border.color: Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.15)
            border.width: 1
            clip: true

            Behavior on color { ColorAnimation { duration: 600 } }

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    text: t("seven_day_forecast", "Prévisions 7 jours")
                    color: BeeTheme.textSecondary
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.5
                    Behavior on color { ColorAnimation { duration: 600 } }
                }

                ListView {
                    id: dailyList
                    width: parent.width
                    height: parent.height - 22
                    spacing: 3
                    clip: true
                    model: weatherDetail.dailyModel

                    delegate: Rectangle {
                        width: dailyList.width
                        height: 42
                        radius: 8
                        color: model.index === 0
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                            : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.06)
                        border.color: model.index === 0
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                            : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 300 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Day name
                            Text {
                                text: model.index === 0
                                    ? t("today", "Auj.")
                                    : modelData.dayName
                                color: model.index === 0 ? BeeTheme.accent : BeeTheme.textPrimary
                                font.pixelSize: 13
                                font.bold: model.index === 0
                                width: 45
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            // Weather icon
                            Text {
                                text: modelData.icon
                                font.pixelSize: 20
                                font.family: "Noto Color Emoji"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Condition text
                            Text {
                                text: modelData.condition
                                color: BeeTheme.textSecondary
                                font.pixelSize: 11
                                width: 100
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            // Max/Min temps
                            Text {
                                text: modelData.maxTemp
                                color: BeeTheme.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                text: "/"
                                color: BeeTheme.textSecondary
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.minTemp
                                color: BeeTheme.textSecondary
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            // Spacer
                            Item { width: 10; height: 1 }

                            // Precipitation
                            Text {
                                text: modelData.precip > 0 ? "🌧 " + modelData.precip.toFixed(1) + " mm" : ""
                                color: Qt.rgba(0.4, 0.7, 1.0, 1.0)
                                font.pixelSize: 11
                                visible: modelData.precip > 0
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Snowfall (critical for skiing!)
                            Text {
                                text: modelData.snow > 0 ? "⛷ " + modelData.snow.toFixed(1) + " cm" : ""
                                color: Qt.rgba(0.7, 0.85, 1.0, 1.0)
                                font.pixelSize: 11
                                font.bold: modelData.snow > 5
                                visible: modelData.snow > 0
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Wind
                            Text {
                                text: modelData.windMax > 30 ? "💨 " + modelData.windMax : ""
                                color: BeeTheme.textSecondary
                                font.pixelSize: 10
                                visible: modelData.windMax > 30
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }
                }
            }
        }

        // ─── Loading overlay ──────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.85)
            radius: 16
            visible: weatherDetail.isLoading
            opacity: weatherDetail.isLoading ? 1.0 : 0.0

            Behavior on opacity { NumberAnimation { duration: 300 } }

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "🌤️"
                    font.pixelSize: 48
                    anchors.horizontalCenter: parent.horizontalCenter

                    SequentialAnimation on y {
                        running: weatherDetail.isLoading
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: -8; duration: 1000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: -8; to: 0; duration: 1000; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    text: t("loading", "Chargement…")
                    color: BeeTheme.textSecondary
                    font.pixelSize: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    Behavior on color { ColorAnimation { duration: 600 } }
                }
            }
        }
    }
}