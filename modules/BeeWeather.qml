import QtQuick
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════
// BeeWeather.qml — Universal Weather Module 🐝🌦️
// Utilise l'API gratuite Open-Meteo (Sans clé API)
// v1.2: Enhanced data model — hourly/7day forecast, snow data
//       Lazy-load: detail data fetched only when detail panel opens
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeWeather
    clip: true
    implicitWidth: Math.min(mainLayout.implicitWidth, 150)
    implicitHeight: 48

    // ─── Propriétés de configuration ──────────────────────
    property string city: "Blainville"
    property real lat: 45.67
    property real lon: -73.88
    property string unit: "celsius"
    property string lang: "fr"

    // ─── Current weather data ──────────────────────────────
    property string temperature: "—"
    property string condition: (BeeConfig.tr.weather && BeeConfig.tr.weather.loading) || "Loading…"
    property string icon: "🌡️"
    property bool loading: true
    property int conditionMaxWidth: 80
    property int _retryCount: 0
    property int _maxRetries: 5

    // ─── Enhanced current conditions ────────────────────────
    property string feelsLike: "—"
    property string humidity: "—"
    property string windSpeed: "—"
    property string windDirection: "—"
    property string uvIndex: "—"
    property string precipitation: "—"
    property string snowDepth: "—"
    property bool isDay: true

    // ─── Hourly forecast (next 24h) ────────────────────────
    property var hourlyData: []   // [{hour, temp, code, precipProb, wind}]

    // ─── 7-day forecast ────────────────────────────────────
    property var dailyData: []    // [{date, maxTemp, minTemp, code, precip, snow, windMax}]

    // ─── Detail data loading state ─────────────────────────
    property bool detailLoading: false
    property bool detailLoaded: false

    // ─── Wind direction degrees → compass label ───────────
    function windDirLabel(deg) {
        var dirs = (BeeConfig.tr && BeeConfig.tr.weather && BeeConfig.tr.weather.wind_directions)
            ? BeeConfig.tr.weather.wind_directions : null
        var labels = dirs
            ? [dirs.N, dirs.NNE, dirs.NE, dirs.ENE, dirs.E, dirs.ESE, dirs.SE, dirs.SSE,
               dirs.S, dirs.SSW, dirs.SW, dirs.WSW, dirs.W, dirs.WNW, dirs.NW, dirs.NNW]
            : ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
               "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        var idx = Math.round(deg / 22.5) % 16
        return labels[idx]
    }

    // ─── Signal to open detail panel (via BeeBarState) ──
    // BeeWeather emits through BeeBarState.weatherDetailToggled()

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

    // ─── Data retrieval — Current weather (Open-Meteo) ────
    function updateWeather() {
        loading = true
        condition = (BeeConfig.tr.weather && BeeConfig.tr.weather.loading) || "Loading…"
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m,uv_index,is_day&timezone=auto`

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
                    beeWeather.feelsLike = Math.round(current.apparent_temperature) + "°"
                    beeWeather.humidity = current.relative_humidity_2m + "%"
                    beeWeather.windSpeed = current.wind_speed_10m + " km/h"
                    if (current.wind_direction_10m !== undefined && current.wind_direction_10m !== null) {
                        beeWeather.windDirection = windDirLabel(current.wind_direction_10m)
                    } else {
                        beeWeather.windDirection = "—"
                    }
                    beeWeather.uvIndex = current.uv_index !== undefined && current.uv_index !== null ? String(current.uv_index) : "—"
                    beeWeather.precipitation = current.precipitation + " mm"
                    beeWeather.isDay = current.is_day === 1
                    beeWeather._retryCount = 0  // Reset retry counter on success
                } else {
                    beeWeather.condition = (BeeConfig.tr.weather && BeeConfig.tr.weather.error) || "Weather unavailable"
                    // Auto-retry with exponential backoff (15s, 30s, 60s, 120s, 240s)
                    if (beeWeather._retryCount < beeWeather._maxRetries) {
                        beeWeather._retryCount++
                        var delay = 15000 * Math.pow(2, beeWeather._retryCount - 1)
                        console.log("[BeeWeather] XHR failed (status " + xhr.status + "), retry #" + beeWeather._retryCount + " in " + (delay/1000) + "s")
                        retryTimer.interval = delay
                        retryTimer.start()
                    } else {
                        console.log("[BeeWeather] Max retries reached, giving up until next 30min refresh")
                    }
                }
                loading = false
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    // ─── Lazy-load detail data (hourly + daily) ──────────
    function fetchDetailData() {
        if (detailLoading) return
        detailLoading = true

        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}`
            + `&hourly=temperature_2m,weather_code,precipitation_probability,wind_speed_10m`
            + `&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum,snowfall_sum,wind_speed_10m_max`
            + `&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m,uv_index,is_day`
            + `&timezone=auto&forecast_days=7`

        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const data = JSON.parse(xhr.responseText)

                        // ── Update current conditions ──
                        if (data.current) {
                            const c = data.current
                            beeWeather.temperature = Math.round(c.temperature_2m) + "°"
                            const info = getWmoInfo(c.weather_code)
                            beeWeather.icon = info[0]
                            beeWeather.condition = info[1]
                            beeWeather.feelsLike = Math.round(c.apparent_temperature) + "°"
                            beeWeather.humidity = c.relative_humidity_2m + "%"
                            beeWeather.windSpeed = c.wind_speed_10m + " km/h"
                            if (c.wind_direction_10m !== undefined && c.wind_direction_10m !== null) {
                                beeWeather.windDirection = windDirLabel(c.wind_direction_10m)
                            } else {
                                beeWeather.windDirection = "—"
                            }
                            beeWeather.uvIndex = c.uv_index !== undefined && c.uv_index !== null ? String(c.uv_index) : "—"
                            beeWeather.precipitation = c.precipitation + " mm"
                            beeWeather.isDay = c.is_day === 1
                        }

                        // ── Parse hourly (next 24h) ──
                        if (data.hourly) {
                            var hours = []
                            var now = new Date()
                            var nowISO = now.toISOString().slice(0, 13)
                            var startIdx = 0
                            // Find current hour index
                            for (var i = 0; i < data.hourly.time.length; i++) {
                                if (data.hourly.time[i].slice(0, 13) >= nowISO) {
                                    startIdx = i
                                    break
                                }
                            }
                            for (var j = startIdx; j < Math.min(startIdx + 24, data.hourly.time.length); j++) {
                                var hourDate = new Date(data.hourly.time[j])
                                var hInfo = getWmoInfo(data.hourly.weather_code[j])
                                hours.push({
                                    hour: hourDate.getHours(),
                                    temp: Math.round(data.hourly.temperature_2m[j]) + "°",
                                    icon: hInfo[0],
                                    precipProb: data.hourly.precipitation_probability[j] !== null ? data.hourly.precipitation_probability[j] : 0,
                                    wind: data.hourly.wind_speed_10m[j] !== null ? Math.round(data.hourly.wind_speed_10m[j]) : 0
                                })
                            }
                            beeWeather.hourlyData = hours
                        }

                        // ── Parse daily (7-day) ──
                        if (data.daily) {
                            var days = []
                            var dayNames = (BeeConfig.uiLang === "fr")
                                ? ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]
                                : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                            for (var d = 0; d < data.daily.time.length; d++) {
                                var dayDate = new Date(data.daily.time[d] + "T12:00:00")
                                var dInfo = getWmoInfo(data.daily.weather_code[d])
                                days.push({
                                    date: data.daily.time[d],
                                    dayName: dayNames[dayDate.getDay()],
                                    maxTemp: Math.round(data.daily.temperature_2m_max[d]) + "°",
                                    minTemp: Math.round(data.daily.temperature_2m_min[d]) + "°",
                                    icon: dInfo[0],
                                    condition: dInfo[1],
                                    precip: data.daily.precipitation_sum[d] !== null ? data.daily.precipitation_sum[d] : 0,
                                    snow: data.daily.snowfall_sum[d] !== null ? data.daily.snowfall_sum[d] : 0,
                                    windMax: data.daily.wind_speed_10m_max[d] !== null ? Math.round(data.daily.wind_speed_10m_max[d]) : 0
                                })
                            }
                            beeWeather.dailyData = days
                        }

                        beeWeather.detailLoaded = true
                    } catch(e) {
                        console.warn("[BeeWeather] Detail parse error:", e)
                    }
                } else {
                    console.warn("[BeeWeather] Detail fetch failed, status:", xhr.status)
                }
                detailLoading = false
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    // Retry timer — started dynamically on error, stopped on success
    Timer {
        id: retryTimer
        interval: 15000
        repeat: false
        onTriggered: updateWeather()
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

    // Initialisation — delay first fetch by 3s to let network settle
    Component.onCompleted: startupTimer.start()

    Timer {
        id: startupTimer
        interval: 3000
        repeat: false
        onTriggered: updateWeather()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Open detail view — signal through BeeBarState
            BeeBarState.weatherDetailToggled()
        }
    }

    Timer {
        interval: BeeConfig.reducedAnimations ? 600000 : 300000  // 10min battery / 5min normal
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
            font.pixelSize: 22; font.family: "Noto Color Emoji"
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            spacing: -2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: beeWeather.temperature
                color: BeeTheme.accent
                font.pixelSize: 14; font.bold: true; font.family: "monospace"
                Behavior on color { ColorAnimation { duration: 600 } }
            }
            Text {
                text: beeWeather.city
                color: BeeTheme.textSecondary
                font.pixelSize: 9; font.letterSpacing: 0.5; font.bold: true
                textFormat: Text.PlainText
                Behavior on color { ColorAnimation { duration: 600 } }
            }
        }

        // Tooltip simple / Condition au survol ou à côté
        Text {
            text: beeWeather.condition
            color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.7)
            font.pixelSize: 10; font.italic: true
            visible: true
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: beeWeather.conditionMaxWidth
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }
}