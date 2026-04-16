import QtQuick
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════
// BeeWeather.qml — Universal Weather Module 🐝🌦️
// Utilise l'API gratuite Open-Meteo (Sans clé API)
// v1.1: i18n — weather conditions and translated texts via BeeConfig.tr
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeWeather
    clip: true
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: 48

    // ─── Propriétés de configuration ──────────────────────
    property string city: "Blainville"
    property real lat: 45.67
    property real lon: -73.88
    property string unit: "celsius"
    property string lang: "fr"

    // ─── Weather data ──────────────────────────────────────
    property string temperature: "—"
    property string condition: (BeeConfig.tr.weather && BeeConfig.tr.weather.loading) || "Loading…"
    property string icon: "🌡️"
    property bool loading: true
    property int conditionMaxWidth: 170

    // ─── Mappage des codes WMO (depuis les traductions) ──
    function getWmoInfo(code) {
        var conditions = BeeConfig.tr.weather && BeeConfig.tr.weather.conditions
        if (conditions) {
            var entry = conditions[String(code)]
            if (entry && entry.length >= 2) return [entry[0], entry[1]]
            var unknown = conditions["unknown"]
            return unknown ? [unknown[0], unknown[1]] : ["❓", "?"]
        }
        // Fallback intégré si les traductions ne sont pas encore chargées
        var fallback = {
            0:  ["☀️", "Dégagé"],        1:  ["🌤️", "Plutôt dégagé"],
            2:  ["⛅", "Partiellement nuageux"], 3: ["☁️", "Couvert"],
            45: ["🌁", "Brouillard"],    48: ["🌁", "Brouillard givrant"],
            51: ["🌦️", "Bruine légère"], 53: ["🌦️", "Bruine modérée"], 55: ["🌦️", "Bruine dense"],
            61: ["🌧️", "Pluie légère"],  63: ["🌧️", "Pluie modérée"],  65: ["🌧️", "Pluie forte"],
            71: ["🌨️", "Neige légère"],  73: ["🌨️", "Neige modérée"],  75: ["🌨️", "Neige forte"],
            77: ["🌨️", "Grains de neige"],
            80: ["🌦️", "Averses légères"], 81: ["🌦️", "Averses modérées"], 82: ["🌦️", "Averses violentes"],
            85: ["🌨️", "Averses de neige légères"], 86: ["🌨️", "Averses de neige fortes"],
            95: ["⛈️", "Orage"], 96: ["⛈️", "Orage avec grêle légère"], 99: ["⛈️", "Orage avec grêle forte"]
        }
        return fallback[code] || ["❓", "Inconnu"]
    }

    // ─── Data retrieval (Open-Meteo) ───────────────────────
    function updateWeather() {
        loading = true
        condition = (BeeConfig.tr.weather && BeeConfig.tr.weather.loading) || "Loading…"
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code&timezone=auto`

        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    const data = JSON.parse(xhr.responseText)
                    const current = data.current
                    beeWeather.temperature = Math.round(current.temperature_2m) + "°"
                    const info = getWmoInfo(current.weather_code)
                    beeWeather.icon = info[0]
                    beeWeather.condition = info[1]
                } else {
                    beeWeather.condition = (BeeConfig.tr.weather && BeeConfig.tr.weather.error) || "Weather unavailable"
                }
                loading = false
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    // Reload weather when language changes (to update conditions)
    Connections {
        target: BeeConfig
        function onTrChanged() {
            if (!beeWeather.loading && beeWeather.temperature !== "—") {
                // Re-déclenche une mise à jour pour traduire la condition courante
                updateWeather()
            }
        }
    }

    // Initialisation & Timer
    Component.onCompleted: updateWeather()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: updateWeather()
    }

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        onTriggered: updateWeather()
    }

    // ─── Layout Visuel ─────────────────────────────────────
    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 8
        opacity: loading ? 0.5 : 1.0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        Text {
            text: beeWeather.icon
            font { pixelSize: 22; family: "Noto Color Emoji" }
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            spacing: -2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: beeWeather.temperature
                color: BeeTheme.accent
                font { pixelSize: 14; bold: true; family: "monospace" }
                Behavior on color { ColorAnimation { duration: 600 } }
            }
            Text {
                text: beeWeather.city
                color: BeeTheme.textSecondary
                font { pixelSize: 9; letterSpacing: 0.5; bold: true }
                textFormat: Text.PlainText
                Behavior on color { ColorAnimation { duration: 600 } }
            }
        }

        // Tooltip simple / Condition au survol ou à côté
        Text {
            text: beeWeather.condition
            color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.7)
            font { pixelSize: 10; italic: true }
            visible: true
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: beeWeather.conditionMaxWidth
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }
}
