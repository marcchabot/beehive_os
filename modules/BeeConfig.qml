pragma Singleton
import QtQuick
import QtCore
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeConfig.qml — BeeConfig System 🐝📋  (Global Singleton)
// v0.8.25 — CalDAV sync, Nectar Auto-Theme (time/weather)
// Loads user_config.json and exposes dashboard data
// Access: BeeConfig.cells, BeeConfig.weatherCity, etc.
// ═══════════════════════════════════════════════════════════════

QtObject {
    id: root

    // ─── Version 🐝 ──────────────────────────────────────────────
    property string appVersion: "0.8.25"

    // ─── General ────────────────────────────────────────────────
    property string configDir: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/bee-hive-os"
    property string clockFormat: "24h"        // "12h" | "24h"
    property string currentWallpaper: ""        // Path to current wallpaper
    property var extractedColors: []             // Colors extracted from wallpaper
    property string _activePaletteKey: "honey_gold" // Currently active palette key

    // ─── Stealth Mode ─────────────────────────────────────────
    property bool stealthMode: false
    onStealthModeChanged: {
        BeeBarState.stealthEnabled = stealthMode
        if (root._loaded) saveConfig()
    }

    // ─── BeeVibe ───────────────────────────────────────────────
    property bool vibeMode: false
    onVibeModeChanged: {
        BeeBarState.vibeActive = vibeMode
        if (root._loaded) saveConfig()
    }

    // ─── BeeVibe Backend ("auto" | "cava-bg" | "cava" | "simulation") ──
    property string vibeBackend: "auto"
    onVibeBackendChanged: {
        if (root._loaded) saveConfig()
    }

    // ─── BeeVibe X-Ray Mode 🐝🌀 ────────────────────────────
    property bool vibeXray: true
    onVibeXrayChanged: {
        if (root._loaded) saveConfig()
    }
    property string vibeXrayDir: ""
    onVibeXrayDirChanged: {
        if (root._loaded) saveConfig()
    }
    property real vibeXrayIntensity: 0.8
    onVibeXrayIntensityChanged: {
        if (root._loaded) saveConfig()
    }
    property string vibeXrayBlend: "Normal"
    onVibeXrayBlendChanged: {
        if (root._loaded) saveConfig()
    }

    // ─── Contextual Bar — dynamic icons/labels per active app ──
    property bool contextualBar: true
    onContextualBarChanged: {
        if (root._loaded) saveConfig()
    }

    // ─── Mode Focus 🎯 ──────────────────────────────────────────
    property bool focusMode: false
    onFocusModeChanged: {
        BeeBarState.focusActive = focusMode
        if (root._loaded) saveConfig()
    }

    // ─── BeeFocus 🍅 — Pomodoro & Health Timer ──────────────────
    property string beeFocusState: ""
    onBeeFocusStateChanged: {
        if (root._loaded) saveConfig()
    }
    function setBeeFocusState(json) {
        beeFocusState = json
    }

    // ─── BeeKeybinds ⌨️ — Configurable shortcuts ────────────────
    property string beeKeybinds: ""
    onBeeKeybindsChanged: {
        if (root._loaded) saveConfig()
    }

    // ─── BeeCorners 🐝📱 ───────────────────────────────────────
    property bool cornersMode: true
    onCornersModeChanged: {
        BeeBarState.cornersActive = cornersMode
        if (root._loaded) saveConfig()
    }

    // ─── BeeMotion (Parallax) ──────────────────────────────────
    property bool motionMode: true
    onMotionModeChanged: {
        BeeBarState.motionActive = motionMode
        if (root._loaded) saveConfig()
    }

    // ─── BeeBar Visibility ────────────────────────────────────
    property bool showCpu: true
    property bool showRam: true
    property bool showNet: true
    property bool showDisk: true
    property bool showBattery: true

    // ─── Battery Mode 🐝🔋 ────────────────────────────────────
    // batteryMode: true when on battery power (reduces animations)
    // batteryModeAuto: true = auto-detect from power supply, false = manual
    // batteryThreshold: percentage below which battery saver activates (default 20)
    // batterySaverActive: true when on battery AND below threshold
    // reducedAnimations: derived property, true when batteryMode or batterySaverActive
    property bool batteryMode: false
    property bool batteryModeAuto: true
    property int batteryThreshold: 20
    readonly property bool batterySaverActive: batteryMode && batteryPercentage <= batteryThreshold
    readonly property bool reducedAnimations: batteryMode || batterySaverActive

    onBatteryModeChanged: {
        BeeTheme.reducedAnimations = batteryMode || batterySaverActive
        if (root._loaded) saveConfig()
    }
    onBatteryModeAutoChanged: {
        if (root._loaded) saveConfig()
    }
    onBatteryThresholdChanged: {
        if (root._loaded) saveConfig()
    }
    onBatterySaverActiveChanged: {
        BeeTheme.reducedAnimations = batteryMode || batterySaverActive
        if (root._loaded) saveConfig()
    }

    // Battery info from system
    property int batteryPercentage: 100
    property string batteryStatus: "Unknown"

    // Process to monitor battery state
    property Process _batteryProc: Process {
        id: _batteryMonitor
        running: false
        command: ["bash", Qt.resolvedUrl("../scripts/bee_battery_mode.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line.trim())
                    if (data.on_battery !== undefined) {
                        if (batteryModeAuto) {
                            batteryMode = data.on_battery
                        }
                        batteryPercentage = data.percentage || 100
                        batteryStatus = data.status || "Unknown"
                        // Handle saver_active from enhanced battery script
                        if (data.saver_active !== undefined) {
                            // saver_active is already derived from batteryMode && batteryPercentage <= batteryThreshold
                            // Just ensure consistency
                        }
                    }
                } catch(e) {}
            }
        }
    }

    // Timer to periodically check battery status (every 30s)
    property Timer _batteryTimer: Timer {
        interval: 30000
        running: batteryModeAuto
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            _batteryMonitor.running = false
            _batteryMonitor.running = true
        }
    }

    // ─── Config Backup & Restore 🐝💾 ────────────────────────
    property string _backupScriptPath: Qt.resolvedUrl("../scripts/bee_config_backup.py").toString().replace("file://", "")
    property string _backupStatus: "idle"  // "idle" | "loading" | "done" | "error"
    property var _backupList: []

    function createBackup() {
        _backupStatus = "loading"
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["python3", "' + _backupScriptPath + '", "backup"] }',
            root, "backupCreateProc"
        )
        proc.stdout.connect(function(line) {
            try {
                var data = JSON.parse(line.trim())
                if (data.status === "ok") {
                    _backupStatus = "done"
                    refreshBackupList()
                    BeeBarState.logAction("Backup", BeeConfig.uiLang === "fr" ? "Sauvegarde créée" : "Backup created", "💾")
                } else {
                    _backupStatus = "error"
                }
            } catch(e) { _backupStatus = "error" }
        })
    }

    function refreshBackupList() {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["python3", "' + _backupScriptPath + '", "list"] }',
            root, "backupListProc"
        )
        var output = ""
        proc.stdout.connect(function(line) {
            output += line
        })
        proc.exited.connect(function(code, status) {
            try {
                var data = JSON.parse(output.trim())
                _backupList = data.backups || []
            } catch(e) {
                _backupList = []
            }
        })
    }

    function restoreBackup(filepath) {
        _backupStatus = "loading"
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["python3", "' + _backupScriptPath + '", "restore", "' + filepath + '"] }',
            root, "backupRestoreProc"
        )
        proc.stdout.connect(function(line) {
            try {
                var data = JSON.parse(line.trim())
                if (data.status === "ok") {
                    _backupStatus = "done"
                    // Reload config from file after restore
                    loadConfig()
                    BeeBarState.logAction("Backup", BeeConfig.uiLang === "fr" ? "Configuration restaurée" : "Config restored", "🔄")
                } else {
                    _backupStatus = "error"
                }
            } catch(e) { _backupStatus = "error" }
        })
    }

    function deleteBackup(filepath) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["python3", "' + _backupScriptPath + '", "delete", "' + filepath + '"] }',
            root, "backupDeleteProc"
        )
        proc.stdout.connect(function(line) {
            try {
                var data = JSON.parse(line.trim())
                if (data.status === "ok") {
                    refreshBackupList()
                    BeeBarState.logAction("Backup", BeeConfig.uiLang === "fr" ? "Sauvegarde supprimée" : "Backup deleted", "🗑️")
                }
            } catch(e) {}
        })
    }

    // ─── Window Icons Configuration ──────────────────────────
    property var window_icons: ({})

    // ─── Contextual Bar Rules 🐝🧭 ──────────────────────────
    // Per-app contextual shortcuts shown in BeeBar when that app is active.
    // Format: { "kitty": [{icon: "📊", label: "CPU", action: "shell:btop"}], ... }
    property var context_rules: ({
        "kitty":        [{ icon: "📊", label: "CPU",  action: "shell:btop" }],
        "alacritty":    [{ icon: "📊", label: "CPU",  action: "shell:btop" }],
        "foot":         [{ icon: "📊", label: "CPU",  action: "shell:btop" }],
        "firefox":      [{ icon: "📁", label: "DLs",  action: "shell:dolphin ~/Downloads" }],
        "zen-browser":  [{ icon: "📁", label: "DLs",  action: "shell:dolphin ~/Downloads" }],
        "zen":          [{ icon: "📁", label: "DLs",  action: "shell:dolphin ~/Downloads" }],
        "code":         [{ icon: "🧠", label: "RAM",  action: "shell:btop" }],
        "zeditor":       [{ icon: "🧠", label: "RAM",  action: "shell:btop" }],
        "discord":      [{ icon: "🌐", label: "NET",  action: "detail:network" }],
        "spotify":       [{ icon: "🔊", label: "VOL",  action: "shell:pavucontrol" }],
        "steam":        [{ icon: "🎮", label: "LIB",  action: "shell:steam" }],
        "dolphin":       [{ icon: "💿", label: "DISK", action: "shell:btop" }],
        "thunar":        [{ icon: "💿", label: "DISK", action: "shell:btop" }]
    })

    // ─── BeeVoice — Maya AI Assistant 🐝🎤 ─────────────────────
    property bool voiceEnabled: true
    property string voiceOllamaModel: "gemma4:31b-cloud"
    property string voiceOllamaUrl: "http://127.0.0.1:11434"
    property string voiceElevenlabsVoiceId: "BZgkqPqms7Kj9ulSkVzn"
    property string voiceElevenlabsModelId: "eleven_flash_v2_5"
    property string voiceTtsBackend: "edge-tts"
    property string voiceEdgeTtsVoice: "fr-CA-SylvieNeural"
    property string voiceEdgeTtsRate: "+0%"
    property int voiceRecordDuration: 6
    property string voiceWhisperModel: "tiny"

    // ─── BeeAlarm — Calendar Reminders ⏰ ──────────────────────
    property bool alarmEnabled: true
    property int alarmAdvanceMin: 15    // minutes before event
    property int alarmSnoozeMin: 10    // snooze duration
    onAlarmEnabledChanged:  { if (root._loaded) saveConfig() }
    onAlarmAdvanceMinChanged: { if (root._loaded) saveConfig() }
    onAlarmSnoozeMinChanged:  { if (root._loaded) saveConfig() }

    // ─── Nectar Sync 2.0 — Color Therapy & Auto Schedule 🍯🎨 ────
    property bool nectarAutoSchedule: true    // Auto day/night theme suggestion
    property bool colorTherapyEnabled: false   // Accent color pulse cycle
    property string colorTherapyMode: "cycle" // "cycle" | "breathe"
    property bool timeOfDayEnabled: true       // Auto theme based on time of day
    property bool weatherAmbientEnabled: false  // Weather-based ambient theming
    property bool adaptiveEnabled: true         // Adaptive mode (Nectar Sync master)
    property string adaptiveMode: "auto"       // "auto" | "manual"
    // ─── Nectar Auto-Theme Mode 🐝🎨☀️🌧️ v0.8.25 ─────────────
    // "off" = no auto theme, "timeOfDay" = day/night auto-switch,
    // "weather" = weather-based accent, "combined" = both
    property string autoThemeMode: "off"   // "off" | "timeOfDay" | "weather" | "combined"
    onNectarAutoScheduleChanged: { if (root._loaded) saveConfig() }
    onColorTherapyEnabledChanged: {
        if (root._loaded) saveConfig()
        BeeTheme.colorTherapyEnabled = colorTherapyEnabled
    }
    onColorTherapyModeChanged: { if (root._loaded) saveConfig() }
    onTimeOfDayEnabledChanged: { if (root._loaded) saveConfig() }
    onWeatherAmbientEnabledChanged: { if (root._loaded) saveConfig() }
    onAdaptiveEnabledChanged: { if (root._loaded) saveConfig() }
    onAdaptiveModeChanged: { if (root._loaded) saveConfig() }
    onAutoThemeModeChanged: { if (root._loaded) saveConfig() }

    // ─── BeeSound: Mode Nuit ─────────────────────────────────
    property bool soundNightMode: true
    property int soundNightStartHour: 22
    property int soundNightEndHour: 7
    property real soundDayGain: 0.35
    property real soundNightGain: 0.18

    // ─── Horloge Analogique (Bee-Hive Time) ───────────────────
    property bool analogClock: true

    // ─── BeeSearch (Favoris) ──────────────────────────────────
    property var pinnedApps: []
    onPinnedAppsChanged: {
        console.log("BeeConfig: pinnedApps changed (via binding or set) →", JSON.stringify(pinnedApps))
        // If BeeApps.pinnedCmds is not already updated by binding, force it
        if (JSON.stringify(BeeApps.pinnedCmds) !== JSON.stringify(pinnedApps))
            BeeApps.pinnedCmds = pinnedApps
    }

    // ─── BeeEvents & History ──────────────────────────────────
    property bool eventsEnabled: true
    property bool historyEnabled: true
    property string icsUrl: ""  // URL ICS (Legacy support)
    property ListModel calendars: ListModel { id: _calendars }

    // ─── Bee-Live Sync v2 ────────────────────────────────────
    // Par défaut, on laisse vide pour utiliser le fichier local (data/events.json)
    // Sauf si l'utilisateur définit un chemin spécifique dans user_config.json
    property string eventsLivePath: ""
    property var liveSyncMeta: null
    property int liveSyncCount: 0

    // ─── BeeCalendar properties ──────────────────────────
    property string beeCalendarDefaultView: "day"
    property string calendarView: "month"  // "month" | "day"
    property int beeCalendarPollIntervalMin: 15
    // 🐝 v0.8.21 — Reminder system config
    property bool beeCalendarReminderEnabled: true
    property int  beeCalendarReminderMinutes: 5
    property int  beeCalendarSnoozeDurationMin: 5
    property string beeCalendarReminderSound: "notify.info"

    // ─── CalDAV Sync properties 🐝☁️ v0.8.23 ────────────────
    property bool   caldavEnabled: false
    property string caldavUrl: ""
    property string caldavUsername: ""
    property string caldavPassword: ""
    property string caldavCalendarName: ""
    property bool   caldavAutoSync: false
    property int    caldavAutoSyncIntervalMin: 30
    property string caldavSyncStatus: "idle"  // "idle" | "syncing" | "synced" | "error"
    property string caldavLastSync: ""
    property int    caldavEventCount: 0

    onCalendarViewChanged: {
        if (root._loaded) {
            beeCalendarDefaultView = calendarView
            saveConfig()
        }
    }

    // ─── Accessibility 🐝♿ ──────────────────────────────────
    property bool   accessibilityHighContrast: false
    property real   accessibilityTextScale: 1.0   // 1.0 | 1.2 | 1.4
    property bool   accessibilityReducedMotion: false
    property string accessibilityLevel: "none"  // "none" | "AA" | "AAA"

    onAccessibilityHighContrastChanged: {
        BeeTheme.highContrast = accessibilityHighContrast
        if (root._loaded) saveConfig()
    }
    onAccessibilityTextScaleChanged: {
        BeeTheme.textScale = accessibilityTextScale
        if (root._loaded) saveConfig()
    }
    onAccessibilityReducedMotionChanged: {
        BeeTheme.reducedMotion = accessibilityReducedMotion
        BeeTheme.reducedAnimations = reducedAnimations
        if (root._loaded) saveConfig()
    }
    // ─── Screen Reader (Orca) 🐝♿ ────────────────────────
    property bool screenReaderEnabled: false
    property bool accessibilityScreenReader: false  // persistent pref (user wants SR)
    property string screenReaderStatus: "unknown"   // "running" | "stopped" | "not_installed" | "unknown"

    onScreenReaderEnabledChanged: {
        BeeTheme.highContrastForScreenReader = screenReaderEnabled
        if (root._loaded) saveConfig()
    }
    onAccessibilityScreenReaderChanged: {
        if (root._loaded) saveConfig()
    }

    onAccessibilityLevelChanged: {
        BeeTheme.accessibilityLevel = accessibilityLevel
        if (root._loaded) saveConfig()
    }

    // ─── BeeProfiles — Profile Switching Multi-User 🐝👥 ───────
    property var    profilesConfig: null     // raw profiles from config
    property string activeProfileId: "marc"

    // ─── Plugin System v2 🐝🧩 ────────────────────────────────
    property bool   pluginsEnabled: false   // Disabled until plugin manager script is implemented
    property var    pluginList: []        // list of enabled plugin ids
    property bool   pluginAutoUpdate: false
    property string pluginStatus: "idle"  // "idle" | "loading" | "ready" | "error"

    signal eventsReloadRequested()
    signal configLoaded()

    function reloadLiveEvents() {
        eventsReloadRequested()
    }

    // ─── Sync properties to BeeBarState ─────────────────────
    // Removed old redundant listeners as they are now handled above with auto-save.

    // ─── UI language (i18n) ────────────────────────────────────
    property string uiLang: "fr"
    property bool   launchAtStartup: false
    property var    tr:     ({})
    onLaunchAtStartupChanged: { if (root._loaded) saveConfig() }

    function loadI18n(lang) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../i18n/" + lang + ".json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200 || xhr.status === 0) {
                try {
                    tr = JSON.parse(xhr.responseText)
                } catch(e) {
                    console.warn("BeeConfig: i18n error →", e)
                }
            }
        }
        xhr.send()
    }

    function setLang(lang) {
        uiLang = lang
        loadI18n(lang)
    }

    // ─── Cell translation helper ─────────────────────────────────
    // Returns translated cell data based on current language
    // Falls back to English if translation missing
    function trCell(key) {
        if (!tr || !tr.cells) return null
        var cell = tr.cells[key]
        if (!cell) return null
        // Return a fresh object to avoid reference issues
        return {
            icon: cell.icon || "",
            title: cell.title || "",
            subtitle: cell.subtitle || "",
            detail: cell.detail || "",
            action: cell.action || "none",
            highlighted: cell.highlighted || false,
            customizable: true
        }
    }

    // ─── Weather ───────────────────────────────────────────────
    property string weatherCity: "Blainville"
    property string weatherUnit: "metric"
    property string weatherLang: "fr"
    property real   weatherLat:  45.67
    property real   weatherLon:  -73.88

    // ─── Dashboard ────────────────────────────────────────────
    property string dashTitle: "🍯 Maya Dashboard"

    // ─── Cells model ───────────────────────────────────────────
    property ListModel cells: ListModel { id: _cells }

    // ─── Revision — incremented on each cell set() ────────────
    // Allows external bindings (MayaDash) to re-evaluate
    // since ListModel.get() does not create fine-grained dependency.
    property int cellsRevision: 0

    property bool _loaded: false

    // ─── Raw config (preserved for saving) ─────────────────────
    property var _rawConfig: ({})

    // ─── Save process ──────────────────────────────────────────
    property Process saveProc: Process {
        id: _saveProc
        running: false
    }

    // ─── Auto Theme Runtime (user_config.auto.json) ───────────
    property string autoThemeScriptPath: Qt.resolvedUrl("../scripts/bee_theme_auto.py").toString().replace("file://", "")
    property string autoThemeOverlayPath: Qt.resolvedUrl("../user_config.auto.json").toString().replace("file://", "")
    property string autoThemeStatus: "idle"
    property string autoThemeLastWallpaper: ""
    property string _autoThemePendingWallpaper: ""

    property Process autoThemeProc: Process {
        id: _autoThemeProc
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var msg = (line || "").trim()
                if (msg.length > 0) console.log("BeeThemeAuto:", msg)
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                autoThemeStatus = "error"
                console.warn("BeeConfig: auto-theme process failed with code", code, "status", status)
                BeeBarState.dispatchNotification("BeeTheme Auto", "Echec generation theme", "❌")
                return
            }

            autoThemeLastWallpaper = _autoThemePendingWallpaper
            _loadAutoOverlay(
                function(overlayCfg) {
                    var applied = _applyOverlayTheme(overlayCfg, "BeeConfig:")
                    if (applied) {
                        autoThemeStatus = "ok"
                        BeeBarState.dispatchNotification("BeeTheme Auto", "Theme applique depuis wallpaper", "🎨")
                    } else {
                        autoThemeStatus = "warn"
                        BeeBarState.dispatchNotification("BeeTheme Auto", "Overlay genere mais palette invalide", "⚠️")
                    }
                },
                function(reason) {
                    autoThemeStatus = "error"
                    console.warn("BeeConfig: auto overlay load failed after generation:", reason)
                    BeeBarState.dispatchNotification("BeeTheme Auto", "Overlay indisponible apres generation", "⚠️")
                }
            )
        }
    }

    // ─── Color Therapy Timer & Process (persistent, survives TheHive close) ──
    property string _colorTherapyScript: Qt.resolvedUrl("../scripts/bee_color_therapy.py").toString().replace("file://", "")

    // adaptiveEnabled is already declared in Nectar Sync section above (line ~288)
    property bool breatheActive: false  // true when breathe mode is active (QML-native animation)
    property int _therapyFrameCount: 0
    property string _lastTherapyWallpaper: ""  // track wallpaper to detect changes and reset

    property Timer colorTherapyTimer: Timer {
        interval: 30000  // 30 seconds per frame (cycle mode only; breathe uses QML animation)
        repeat: true
        running: root.colorTherapyEnabled && !root.breatheActive
        onTriggered: root._runColorTherapyFrame()
    }

    property Process colorTherapyProc: Process {
        running: false
        command: ["python3", root._colorTherapyScript, "--mode", "cycle", "--once"]
        onExited: function(code, status) {
            if (code === 0) {
                root._therapyFrameCount++
                root._therapyReloading = true
                root._reloadAutoOverlay()
            } else {
                root._therapyReloading = false
            }
        }
    }

    property bool _therapyReloading: false

    function _resetColorTherapy() {
        // Clear stale therapy data so next frame extracts fresh wallpaper colors
        colorTherapyTimer.stop()
        colorTherapyProc.running = false
        _therapyFrameCount = 0
        _therapyReloading = false
        Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["python3", "' + root._colorTherapyScript + '", "--reset"] }',
            controlRoot, "colorTherapyReset"
        )
        // Small delay to let --reset write the cleared config, then reload
        Qt.callLater(function() {
            root._reloadAutoOverlay()
        })
        console.log("[BeeConfig] Color Therapy reset — stale colors cleared")
    }

    // ─── Wallpaper functions ────────────────────────────
    function pickWallpaper() {
        console.log("BeeConfig: pickWallpaper() — TODO: implement file dialog")
    }
    function randomWallpaper() {
        console.log("BeeConfig: randomWallpaper() — TODO: implement random picker")
    }

    // ─── Palette functions ────────────────────────────────────
    function setPalette(key) {
        root._activePaletteKey = key
        BeeBarState.logAction("Design", "Palette: " + key, "🎨")
        if (root._loaded) saveConfig()
    }
    function importPalette(path) {
        console.log("BeeConfig: importPalette() — TODO: implement palette import")
    }
    function exportPalette(path) {
        console.log("BeeConfig: exportPalette() — TODO: implement palette export")
    }
    function listPalettes() {
        return ["honey_gold", "ember_blaze", "copper_coin", "forest_mist", "rose_garden", "deep_ocean"]
    }

    // ─── Calendar add functions ──────────────────────────
    function addGoogleCalendar() {
        console.log("BeeConfig: addGoogleCalendar() — TODO: implement Google OAuth flow")
    }
    function addIcsCalendar() {
        console.log("BeeConfig: addIcsCalendar() — TODO: implement ICS URL input")
    }

    function _runColorTherapyFrame() {
        if (colorTherapyProc.running || root._therapyReloading)
            return
        var ns = root._rawConfig ? root._rawConfig.nectar_sync : null
        if (!ns || typeof ns !== 'object' || !ns.color_therapy || !ns.color_therapy.enabled)
            return

        var mode = (ns.color_therapy.mode === "breathe") ? "breathe" : "cycle"
        var progress = (Date.now() % 120000) / 120000.0  // 2-minute cycle

        var wallpaper = ""
        if (root._rawConfig) {
            var at = root._rawConfig.auto_theme
            if (at && at.source_wallpaper) wallpaper = at.source_wallpaper
            else if (BeeTheme.wallpaperOverride) wallpaper = BeeTheme.wallpaperOverride
        }

        // Detect wallpaper change → reset stale therapy data
        if (wallpaper && wallpaper !== root._lastTherapyWallpaper) {
            console.log("[BeeConfig] Wallpaper changed during therapy (" + root._lastTherapyWallpaper + " → " + wallpaper + "), resetting")
            root._lastTherapyWallpaper = wallpaper
            root._resetColorTherapy()
            // Restart after a short delay to let reset complete
            Qt.callLater(function() {
                colorTherapyTimer.interval = 2000  // quick first frame after reset
                colorTherapyTimer.start()
                Qt.callLater(function() { colorTherapyTimer.interval = 30000 })  // back to normal
            })
            return
        }
        if (!wallpaper) wallpaper = root._lastTherapyWallpaper
        if (wallpaper) root._lastTherapyWallpaper = wallpaper

        var cmd = ["python3", root._colorTherapyScript, "--mode", mode, "--progress", progress.toFixed(6), "--once"]
        if (wallpaper) cmd.push("--wallpaper", wallpaper)

        colorTherapyProc.command = cmd
        colorTherapyProc.running = true
    }

    function stopColorTherapy() {
        colorTherapyTimer.stop()
        colorTherapyProc.running = false
        BeeTheme.breatheEnabled = false
        root.breatheActive = false
    }

    function _colorTherapyProcRunning() {
        return colorTherapyProc.running
    }

    function _runColorTherapyBreathe(paletteKey) {
        var cmd = ["python3", _colorTherapyScript, "--mode", "breathe", "--palette", paletteKey, "--once"]
        var wallpaper = ""
        if (_rawConfig) {
            var at = _rawConfig.auto_theme
            if (at && at.source_wallpaper) wallpaper = at.source_wallpaper
            else if (BeeTheme.wallpaperOverride) wallpaper = BeeTheme.wallpaperOverride
        }
        if (wallpaper) cmd.push("--wallpaper", wallpaper)
        colorTherapyProc.command = cmd
        colorTherapyProc.running = true
    }

    // ─── Adaptive Mode Timer & Process (persistent) ────────────────
    property string _adaptiveScript: Qt.resolvedUrl("../scripts/bee_adaptive.py").toString().replace("file://", "")

    property Timer adaptiveTimer: Timer {
        interval: 300000  // 5 minutes
        repeat: true
        running: root.adaptiveEnabled
        onTriggered: root._runAdaptiveFrame()
    }

    property Process adaptiveProc: Process {
        running: false
        command: ["python3", root._adaptiveScript, "--adaptive", "--timezone", "America/Toronto"]
        onExited: function(code, status) {
            if (code === 0) {
                root._reloadAutoOverlay()
            }
        }
    }

    function _runAdaptiveFrame() {
        if (adaptiveProc.running) return
        adaptiveProc.running = true
    }

    function stopAdaptive() {
        adaptiveTimer.stop()
        adaptiveProc.running = false
    }

    // ─── Load at startup ───────────────────────────────────────
    Component.onCompleted: {
        loadI18n("fr")   // Pre-load French by default
        loadConfig()
    }

    function loadConfig() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../user_config.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200 || xhr.status === 0) {
                try {
                    var text = xhr.responseText.trim()
                    if (text === "") {
                        console.log("BeeConfig: user_config.json est vide, chargement des défauts.")
                        loadDefaults()
                        return
                    }
                    var baseCfg = JSON.parse(text)
                    _loadAutoOverlay(
                        function(overlayCfg) {
                            var mergedCfg = _mergeThemeOverlay(baseCfg, overlayCfg)
                            applyConfig(mergedCfg, baseCfg)
                        },
                        function(reason) {
                            if (reason === "invalid") {
                                console.warn("BeeConfig: user_config.auto.json invalide, fallback sur base.")
                            }
                            applyConfig(baseCfg, baseCfg)
                        }
                    )
                    return
                } catch (e) {
                    console.warn("BeeConfig: Erreur JSON →", e)
                }
            }
            loadDefaults()
        }
        xhr.send()
    }

    function _normalizeWallpaperPath(path) {
        if (path === undefined || path === null) return ""
        var p = (path + "").trim()
        if (!p) return ""
        if (p.startsWith("file://")) return p.replace("file://", "")
        if (p.startsWith("..")) return Qt.resolvedUrl(p).toString().replace("file://", "")
        return p
    }

    function _loadAutoOverlay(onDone, onFail) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../user_config.auto.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200 || xhr.status === 0) {
                try {
                    var text = (xhr.responseText || "").trim()
                    if (text === "") {
                        if (onFail) onFail("empty")
                        return
                    }
                    var overlayCfg = JSON.parse(text)
                    if (onDone) onDone(overlayCfg)
                    return
                } catch (e) {
                    console.warn("BeeConfig: Erreur JSON auto overlay →", e)
                    if (onFail) onFail("invalid")
                    return
                }
            }
            if (onFail) onFail("missing")
        }
        xhr.send()
    }

    function _mergeThemeOverlay(baseCfg, overlayCfg) {
        var merged = JSON.parse(JSON.stringify(baseCfg || {}))
        if (!overlayCfg || typeof overlayCfg !== "object") return merged

        if (overlayCfg.theme === "HoneyDark" || overlayCfg.theme === "HoneyLight") {
            merged.theme = overlayCfg.theme
        }

        // ─── Color Therapy overlay (theme colors) ───
        // bee_color_therapy.py writes color overrides into overlayCfg.theme
        // (accent, accentLight, secondary, textPrimary, textSecondary)
        // We merge these into auto_theme.palette so BeeTheme applies them.
        if (overlayCfg.theme && typeof overlayCfg.theme === "object") {
            var therapyMeta = overlayCfg.theme.color_therapy || overlayCfg.theme.color_therapy_active
            if (therapyMeta) {
                // Color therapy is active — merge its color overrides into auto_theme.palette
                if (!merged.auto_theme || typeof merged.auto_theme !== "object") {
                    merged.auto_theme = { enabled: true, palette: {} }
                }
                if (!merged.auto_theme.palette || typeof merged.auto_theme.palette !== "object") {
                    merged.auto_theme.palette = {}
                }
                // Map therapy theme keys to BeeTheme palette keys
                var therapyKeys = {
                    "accent": "accent",
                    "accentLight": "accentLight",
                    "secondary": "secondary",
                    "textPrimary": "textPrimary",
                    "textSecondary": "textSecondary"
                }
                for (var tk in therapyKeys) {
                    if (overlayCfg.theme[tk]) {
                        merged.auto_theme.palette[therapyKeys[tk]] = overlayCfg.theme[tk]
                    }
                }
                // Preserve therapy metadata
                merged.auto_theme.color_therapy = overlayCfg.theme.color_therapy
                // Ensure auto_theme stays enabled
                merged.auto_theme.enabled = true
                // Keep existing source info if present
                if (overlayCfg.auto_theme && overlayCfg.auto_theme.source_wallpaper) {
                    merged.auto_theme.source_wallpaper = overlayCfg.auto_theme.source_wallpaper
                }
                if (overlayCfg.auto_theme && overlayCfg.auto_theme.generated_at) {
                    merged.auto_theme.generated_at = overlayCfg.auto_theme.generated_at
                }
                if (overlayCfg.auto_theme && overlayCfg.auto_theme.engine) {
                    merged.auto_theme.engine = overlayCfg.auto_theme.engine
                }
            }
        }

        // ─── Standard auto_theme overlay (from wallpaper analysis) ───
        if (overlayCfg.auto_theme && typeof overlayCfg.auto_theme === "object" &&
            overlayCfg.auto_theme.palette && typeof overlayCfg.auto_theme.palette === "object") {
            // Don't overwrite palette if color therapy already set it (therapy takes priority)
            var therapyActive = overlayCfg.theme && typeof overlayCfg.theme === "object" &&
                                (overlayCfg.theme.color_therapy || overlayCfg.theme.color_therapy_active)
            if (!therapyActive) {
                merged.auto_theme = {
                    enabled: overlayCfg.auto_theme.enabled !== false,
                    source_wallpaper: overlayCfg.auto_theme.source_wallpaper || "",
                    generated_at: overlayCfg.auto_theme.generated_at || "",
                    engine: overlayCfg.auto_theme.engine || "",
                    palette: overlayCfg.auto_theme.palette
                }
            }
        } else if (!merged.auto_theme || !merged.auto_theme.color_therapy) {
            // Only clear auto_theme if color therapy is NOT active
            delete merged.auto_theme
        }

        return merged
    }

    function _applyOverlayTheme(overlayCfg, logPrefix) {
        if (!overlayCfg || typeof overlayCfg !== "object") {
            BeeTheme.clearAutoPalette()
            return false
        }

        var mode = (overlayCfg.theme === "HoneyLight") ? "HoneyLight" : "HoneyDark"
        var autoTheme = overlayCfg.auto_theme

        // ─── Color Therapy: theme colors override palette ───
        // If color therapy is active, the overlayCfg.theme has color overrides
        // that we need to merge into the palette for BeeTheme.applyAutoPalette
        if (overlayCfg.theme && typeof overlayCfg.theme === "object" &&
            (overlayCfg.theme.color_therapy || overlayCfg.theme.color_therapy_active)) {
            if (!autoTheme || typeof autoTheme !== "object") {
                autoTheme = { enabled: true, palette: {} }
            }
            if (!autoTheme.palette || typeof autoTheme.palette !== "object") {
                autoTheme.palette = {}
            }
            // Merge therapy colors into palette
            var therapyMap = {
                "accent": "accent",
                "accentLight": "accentLight",
                "secondary": "secondary",
                "textPrimary": "textPrimary",
                "textSecondary": "textSecondary"
            }
            for (var tk in therapyMap) {
                if (overlayCfg.theme[tk]) {
                    autoTheme.palette[therapyMap[tk]] = overlayCfg.theme[tk]
                }
            }
            autoTheme.enabled = true
        }

        if (!autoTheme || autoTheme.enabled === false || !autoTheme.palette || typeof autoTheme.palette !== "object") {
            BeeTheme.clearAutoPalette()
            return false
        }

        BeeTheme.applyAutoPalette(mode, autoTheme.palette, autoTheme.source_wallpaper || "")
        if (BeeTheme.mode !== mode) BeeTheme.setMode(mode)

        var sourcePath = _normalizeWallpaperPath(autoTheme.source_wallpaper || "")
        if (sourcePath) autoThemeLastWallpaper = sourcePath
        if (logPrefix) console.log(logPrefix, "overlay auto-thème appliqué →", mode)
        return true
    }

    // ─── Reload auto overlay (called by color therapy / adaptive timers) ──
    function _reloadAutoOverlay() {
        _loadAutoOverlay(
            function(overlayCfg) {
                var mergedCfg = _mergeThemeOverlay(JSON.parse(JSON.stringify(_rawConfig)), overlayCfg)
                applyConfig(mergedCfg, _rawConfig)
                root._therapyReloading = false
            },
            function(reason) {
                console.warn("BeeConfig: Auto overlay reload failed →", reason)
            }
        )
    }

    function applyAutoThemeFromWallpaper(wallpaperPath, force) {
        var normalized = _normalizeWallpaperPath(wallpaperPath)
        if (!normalized) {
            autoThemeStatus = "invalid"
            console.warn("BeeConfig: wallpaper path vide, auto-theme ignoré.")
            return false
        }

        if (!BeeTheme.nectarSync) {
            autoThemeStatus = "disabled"
            return true
        }

        if (_autoThemeProc.running) {
            autoThemeStatus = "busy"
            console.log("BeeConfig: auto-theme déjà en cours, requête ignorée.")
            return false
        }

        if (!force && normalized === autoThemeLastWallpaper) {
            autoThemeStatus = "dedup"
            return true
        }

        _autoThemePendingWallpaper = normalized
        autoThemeStatus = "running"
        var modeArg = (BeeTheme.mode === "HoneyLight") ? "HoneyLight" : "HoneyDark"
        _autoThemeProc.running = false
        var cmd = [
            "python3",
            autoThemeScriptPath,
            "--wallpaper",
            normalized,
            "--mode",
            modeArg,
            "--output",
            autoThemeOverlayPath
        ]
        // 🐝 v0.8.21 — Nectar Sync 2.0 time/weather flags
        var nectarObj = _rawConfig.nectar_sync
        if (typeof nectarObj === 'object' && nectarObj !== null) {
            if (nectarObj.time_aware === true) {
                cmd.push("--time-aware")
                cmd.push("--timezone")
                cmd.push(nectarObj.timezone || "America/Toronto")
            }
            if (nectarObj.weather_aware === true) {
                cmd.push("--weather-aware")
                cmd.push("--weather-city")
                cmd.push(weatherCity || "Blainville")
            }
        }
        _autoThemeProc.command = cmd
        _autoThemeProc.running = true
        return true
    }

    function applyConfig(cfg, rawCfg) {
        // Always use the merged config as the new source of truth.
        // Previously, using rawCfg would cause stale values (e.g. analog_clock)
        // to resurface on subsequent overlay reloads.
        _rawConfig = JSON.parse(JSON.stringify(cfg))
        console.log("BeeConfig: Application de la configuration...")
        
        // ... (autres propriétés)
        if (cfg.stealth_mode !== undefined) stealthMode = cfg.stealth_mode === true
        if (cfg.vibe_mode !== undefined)    vibeMode = cfg.vibe_mode === true
        if (cfg.vibe_backend !== undefined) vibeBackend = cfg.vibe_backend
        if (cfg.vibe_xray !== undefined) vibeXray = cfg.vibe_xray === true
        if (cfg.vibe_xray_dir !== undefined) vibeXrayDir = cfg.vibe_xray_dir
        if (cfg.vibe_xray_intensity !== undefined) {
            var xInt = Number(cfg.vibe_xray_intensity)
            if (!isNaN(xInt)) vibeXrayIntensity = Math.max(0.1, Math.min(1.0, xInt))
        }
        if (cfg.vibe_xray_blend !== undefined) vibeXrayBlend = cfg.vibe_xray_blend
        if (cfg.contextual_bar !== undefined) contextualBar = cfg.contextual_bar === true
        if (cfg.focus_mode !== undefined)   focusMode = cfg.focus_mode === true
        if (cfg.bee_focus_state !== undefined) beeFocusState = cfg.bee_focus_state
        if (cfg.bee_keybinds !== undefined) beeKeybinds = cfg.bee_keybinds
        if (cfg.corners_mode !== undefined) cornersMode = cfg.corners_mode === true
        if (cfg.motion_mode !== undefined)  motionMode = cfg.motion_mode === true
        if (cfg.analog_clock !== undefined) analogClock = cfg.analog_clock === true
        
        if (cfg.beebar_stats !== undefined) {
            showCpu = cfg.beebar_stats.cpu !== false
            showRam = cfg.beebar_stats.ram !== false
            showNet = cfg.beebar_stats.net !== false
            showDisk = cfg.beebar_stats.disk !== false
            showBattery = cfg.beebar_stats.battery === true
        }

        if (cfg.pinned_apps !== undefined && Array.isArray(cfg.pinned_apps))
            pinnedApps = cfg.pinned_apps

        if (cfg.alarm_enabled !== undefined) alarmEnabled = cfg.alarm_enabled === true
        if (cfg.alarm_advance_min !== undefined) alarmAdvanceMin = Math.max(1, Math.min(60, parseInt(cfg.alarm_advance_min) || 15))
        if (cfg.alarm_snooze_min !== undefined) alarmSnoozeMin = Math.max(1, Math.min(60, parseInt(cfg.alarm_snooze_min) || 10))
        if (cfg.nectar_auto_schedule !== undefined) nectarAutoSchedule = cfg.nectar_auto_schedule === true
        if (cfg.color_therapy_enabled !== undefined) {
            colorTherapyEnabled = cfg.color_therapy_enabled === true
            BeeTheme.colorTherapyEnabled = colorTherapyEnabled
        }
        // ─── Nectar Auto-Theme Mode 🐝🎨☀️🌧️ v0.8.25 ─────────
        if (cfg.auto_theme_mode !== undefined) autoThemeMode = cfg.auto_theme_mode

        if (cfg.sound) {
            if (cfg.sound.night_mode !== undefined) soundNightMode = cfg.sound.night_mode === true
            if (cfg.sound.night_start_hour !== undefined) soundNightStartHour = Math.max(0, Math.min(23, parseInt(cfg.sound.night_start_hour) || 22))
            if (cfg.sound.night_end_hour !== undefined) soundNightEndHour = Math.max(0, Math.min(23, parseInt(cfg.sound.night_end_hour) || 7))
            if (cfg.sound.day_gain !== undefined) {
                var dayGain = Number(cfg.sound.day_gain)
                if (!isNaN(dayGain)) soundDayGain = Math.max(0.0, Math.min(1.0, dayGain))
            }
            if (cfg.sound.night_gain !== undefined) {
                var nightGain = Number(cfg.sound.night_gain)
                if (!isNaN(nightGain)) soundNightGain = Math.max(0.0, Math.min(1.0, nightGain))
            }
        }

        if (cfg.window_icons !== undefined)
            window_icons = cfg.window_icons

        if (cfg.context_rules !== undefined)
            context_rules = cfg.context_rules

        // ─── BeeVoice config ──────────────────────────────────
        if (cfg.bee_voice !== undefined) {
            var bv = cfg.bee_voice
            voiceEnabled = bv.enabled !== false
            if (bv.ollama_model !== undefined) voiceOllamaModel = bv.ollama_model
            if (bv.ollama_url !== undefined) voiceOllamaUrl = bv.ollama_url
            if (bv.elevenlabs_voice_id !== undefined) voiceElevenlabsVoiceId = bv.elevenlabs_voice_id
            if (bv.elevenlabs_model_id !== undefined) voiceElevenlabsModelId = bv.elevenlabs_model_id
            if (bv.tts_backend !== undefined) voiceTtsBackend = bv.tts_backend
            if (bv.edge_tts_voice !== undefined) voiceEdgeTtsVoice = bv.edge_tts_voice
            if (bv.edge_tts_rate !== undefined) voiceEdgeTtsRate = bv.edge_tts_rate
            if (bv.record_duration !== undefined) voiceRecordDuration = parseInt(bv.record_duration) || 6
            if (bv.whisper_model !== undefined) voiceWhisperModel = bv.whisper_model
        }

        if (cfg.events_enabled !== undefined)
            eventsEnabled = cfg.events_enabled === true
        else if (cfg.bee_events !== undefined)
            eventsEnabled = cfg.bee_events.enabled !== false

        if (cfg.events_live_path !== undefined)
            eventsLivePath = cfg.events_live_path
        else if (cfg.bee_events !== undefined && cfg.bee_events.live_path !== undefined)
            eventsLivePath = cfg.bee_events.live_path

        // Nettoyage immédiat des chemins malformés hérités des versions précédentes (file://file://)
        if (eventsLivePath && eventsLivePath.indexOf("file://file://") !== -1) {
            eventsLivePath = eventsLivePath.replace("file://file://", "file://");
            console.log("BeeConfig: Correction d'un chemin malformé détecté →", eventsLivePath);
        }

        // Auto-compute default if not set: use ~/beehive_os/data/events_live.json
        if (!eventsLivePath || eventsLivePath.indexOf("/home/node") !== -1 || (eventsLivePath.indexOf("/beehive_os/data") === -1 && eventsLivePath.indexOf("/.config/beehive_os") === -1)) {
            var homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString()
            var basePath = homeDir + "/beehive_os/data/events_live.json"
            if (!basePath.startsWith("file://")) basePath = "file://" + basePath
            eventsLivePath = basePath
            console.log("BeeConfig: Resetting eventsLivePath to auto-detected →", eventsLivePath)
        }

        if (cfg.events_ics_url !== undefined)
            icsUrl = cfg.events_ics_url

        // ─── BeeCalendar config ────────────────────────────
        if (cfg.bee_calendar !== undefined) {
            var bc = cfg.bee_calendar
            if (bc.default_view !== undefined) {
                beeCalendarDefaultView = bc.default_view
                calendarView = bc.default_view
            }
            if (bc.reminder_minutes !== undefined) beeCalendarReminderMinutes = parseInt(bc.reminder_minutes) || 5
            if (bc.poll_interval_min !== undefined) beeCalendarPollIntervalMin = parseInt(bc.poll_interval_min) || 15
            // 🐝 v0.8.21 — Reminder system config keys
            if (bc.reminder_enabled !== undefined) beeCalendarReminderEnabled = bc.reminder_enabled !== false
            if (bc.snooze_duration_min !== undefined) beeCalendarSnoozeDurationMin = parseInt(bc.snooze_duration_min) || 5
            if (bc.reminder_sound !== undefined) beeCalendarReminderSound = bc.reminder_sound
        }

        // ─── CalDAV config 🐝☁️ v0.8.23 ─────────────────────
        if (cfg.caldav !== undefined) {
            var cd = cfg.caldav
            caldavEnabled = cd.enabled === true
            if (cd.server_url !== undefined) caldavUrl = cd.server_url
            else if (cd.url !== undefined) caldavUrl = cd.url
            if (cd.username !== undefined) caldavUsername = cd.username
            if (cd.password !== undefined) caldavPassword = cd.password
            if (cd.calendar_name !== undefined) caldavCalendarName = cd.calendar_name
            if (cd.auto_sync !== undefined) caldavAutoSync = cd.auto_sync === true
            if (cd.auto_sync_interval_min !== undefined) caldavAutoSyncIntervalMin = parseInt(cd.auto_sync_interval_min) || 30
            if (cd.last_sync !== undefined) caldavLastSync = cd.last_sync
        }

        // Migration intelligente v1 -> v2
        var hasLegacyUrl = (cfg.events_ics_url && cfg.events_ics_url !== "")
        var calendarsList = (cfg.calendars && Array.isArray(cfg.calendars)) ? cfg.calendars : []
        
        // Vérifier si la legacy URL est déjà dans la liste
        var alreadyMigrated = false
        for (var i = 0; i < calendarsList.length; i++) {
            if (calendarsList[i].url === cfg.events_ics_url) {
                alreadyMigrated = true
                break
            }
        }

        _calendars.clear()
        // Si on a une legacy URL non migrée, on l'ajoute en premier
        if (hasLegacyUrl && !alreadyMigrated) {
            _calendars.append({
                id: "famille",
                type: "ics",
                url: cfg.events_ics_url,
                label: "Famille",
                color: "#FFB81C",
                calendar_id: ""
            })
            console.log("BeeConfig: Legacy URL migrée dans la liste.")
        }

        // Ajouter les calendriers de la config
        for (var c = 0; c < calendarsList.length; c++) {
            // Éviter les doublons si on vient de migrer
            if (calendarsList[c].url !== cfg.events_ics_url || !hasLegacyUrl) {
                var cal = calendarsList[c]
                _calendars.append({
                    id: cal.id || "",
                    type: cal.type || "ics",
                    label: cal.label || "",
                    color: cal.color || "#FFB81C",
                    calendar_id: cal.calendar_id || "",
                    url: cal.url || ""
                })
            }
        }

        if (cfg.lang !== undefined && cfg.lang !== uiLang) {
            uiLang = cfg.lang
            loadI18n(uiLang)
        }
        if (cfg.launch_at_startup !== undefined) launchAtStartup = cfg.launch_at_startup === true

        if (cfg.weather) {
            weatherCity = cfg.weather.city || weatherCity
            weatherUnit = cfg.weather.unit || weatherUnit
            weatherLang = cfg.weather.lang || weatherLang
            if (weatherCity === "Blainville") { weatherLat = 45.67; weatherLon = -73.88 }
            else if (weatherCity === "Tremblant") { weatherLat = 46.12; weatherLon = -74.60 }
        }

        if (cfg.dashboard) {
            dashTitle = cfg.dashboard.title || dashTitle
            if (cfg.dashboard.cells && cfg.dashboard.cells.length > 0) {
                _cells.clear()
                for (var i = 0; i < cfg.dashboard.cells.length; i++) {
                    var cell = cfg.dashboard.cells[i]
                    
                    // All cells are now editable — protection only prevents deletion
                    var canEdit = true
                    
                    _cells.append({
                        icon:         cell.icon || "📦",
                        title:        cell.title || "Module",
                        subtitle:     cell.subtitle || "",
                        detail:       cell.detail || "",
                        action:       cell.action || "none",
                        highlighted:  cell.highlighted === true,
                        customizable: canEdit,
                        color:        cell.color || ""
                    })
                }
                
                // Remplissage si nécessaire
                if (_cells.count < 8) {
                    var cellKeys = ["calendar", "email", "beehive", "weather", "system", "network", "analytics", "settings"]  // v0.9.1: network replaces gaming in defaults
                    for (var k = 0; k < cellKeys.length; k++) {
                        if (_cells.count >= 8) break
                        
                        var def = trCell(cellKeys[k])
                        if (!def) continue
                        
                        // Vérifier si déjà présent par le titre
                        var exists = false
                        for (var j = 0; j < _cells.count; j++) {
                            if (_cells.get(j).title === def.title) { exists = true; break }
                        }
                        
                        if (!exists) {
                            _cells.append({
                                icon: def.icon, title: def.title, subtitle: def.subtitle,
                                detail: def.detail, action: def.action,
                                highlighted: def.highlighted, customizable: true
                            })
                        }
                    }
                }
            } else {
                loadDefaults()
            }
        }

        if (cfg.auto_theme !== undefined) {
            _applyOverlayTheme({
                theme: cfg.theme || BeeTheme.mode,
                auto_theme: cfg.auto_theme
            }, "BeeConfig:")
        } else {
            BeeTheme.clearAutoPalette()
        }

        if (cfg.theme && cfg.theme !== BeeTheme.mode) BeeTheme.setMode(cfg.theme)
        if (cfg.nectar_sync !== undefined) {
            if (typeof cfg.nectar_sync === 'object') {
                BeeTheme.nectarSync = cfg.nectar_sync.enabled !== false
                // Sync dedicated timer flags (survive _rawConfig replacement)
                var ct = cfg.nectar_sync.color_therapy
                root.colorTherapyEnabled = ct && ct.enabled === true
                // Enable QML-native breathe animation when breathe mode is active
                var isBreathe = ct && ct.enabled === true && ct.mode === "breathe"
                root.breatheActive = isBreathe
                BeeTheme.breatheEnabled = isBreathe
                if (isBreathe) {
                    // Store current accent as breathe base
                    BeeTheme._breatheBaseAccent = BeeTheme._baseAccent
                    BeeTheme._breatheBaseAccentLight = BeeTheme.accentLight || BeeTheme._baseAccent
                }
                var ad = cfg.nectar_sync.adaptive
                root.adaptiveEnabled = ad && ad.enabled === true
            } else {
                BeeTheme.nectarSync = cfg.nectar_sync === true
            }
        }

        // ─── Accessibility config 🐝♿ ──────────────────────────
        if (cfg.accessibility !== undefined) {
            var ac = cfg.accessibility
            if (ac.high_contrast !== undefined) {
                accessibilityHighContrast = ac.high_contrast === true
                BeeTheme.highContrast = accessibilityHighContrast
            }
            if (ac.text_scale !== undefined) {
                var ts = Number(ac.text_scale)
                if (!isNaN(ts) && [1.0, 1.2, 1.4].indexOf(ts) >= 0) {
                    accessibilityTextScale = ts
                    BeeTheme.textScale = ts
                }
            }
            if (ac.reduced_motion !== undefined) {
                accessibilityReducedMotion = ac.reduced_motion === true
                BeeTheme.reducedMotion = accessibilityReducedMotion
                // Battery mode: reducedAnimations is bound via onBatteryModeChanged
                BeeTheme.reducedAnimations = batteryMode
            }
            if (ac.level !== undefined) {
                accessibilityLevel = ac.level
                BeeTheme.accessibilityLevel = ac.level
            }
            // ─── Screen Reader config 🐝♿ v0.9.2 ─────────────
            if (ac.screen_reader !== undefined) {
                accessibilityScreenReader = ac.screen_reader === true
            }
        }

        // ─── Battery Mode config 🐝🔋 ──────────────────────
        if (cfg.battery_mode !== undefined) {
            var bm = cfg.battery_mode
            if (bm.auto !== undefined) batteryModeAuto = bm.auto !== false
            if (bm.enabled !== undefined) {
                if (batteryModeAuto) {
                    // Auto mode: will be overridden by battery monitor
                } else {
                    batteryMode = bm.enabled === true
                }
            }
            if (bm.threshold !== undefined) batteryThreshold = bm.threshold
        }

        // ─── Plugin System v2 config 🐝🧩 ─────────────────────
        if (cfg.plugins !== undefined) {
            var pl = cfg.plugins
            if (pl.enabled !== undefined) pluginsEnabled = pl.enabled !== false
            if (pl.auto_update !== undefined) pluginAutoUpdate = pl.auto_update === true
            if (pl.list !== undefined && Array.isArray(pl.list)) pluginList = pl.list
        }

        // ─── BeeProfiles config ────────────────────────────
        if (cfg.profiles !== undefined) {
            profilesConfig = cfg.profiles
        }
        if (cfg.active_profile !== undefined) {
            activeProfileId = cfg.active_profile
        }
        // Initialize BeeProfiles singleton with loaded config
        BeeProfiles.loadFromConfig({ profiles: profilesConfig, activeProfile: activeProfileId })

        root._loaded = true
        root.configLoaded()

        // 🛡️ One-time migration of legacy cell actions (only if not already done)
        if (!_rawConfig._migrated || _rawConfig._migrated !== "0.8.17") {
            _migrateCells()
        }
    }

    // ─── Migrate legacy cell actions (ONE-TIME, version-gated) ──
    function _migrateCells() {
        var changed = false
        for (var i = 0; i < _cells.count; i++) {
            var c = _cells.get(i)
            // 🖥️ Only migrate "Système/System" cells that still have app:terminal
            if (c.action === "app:terminal" && (c.title === "Système" || c.title === "System")) {
                _cells.setProperty(i, "action", "detail:monitor")
                if (c.detail === "Ressources" || c.detail === "Hyprland\nQuickshell")
                    _cells.setProperty(i, "detail", "CPU/GPU/RAM")
                changed = true
            }
            // 📅 Only migrate "Calendrier/Calendar/Agenda" cells that still have app:gnome-calendar
            if (c.action === "app:gnome-calendar" && (c.title === "Calendrier" || c.title === "Calendar" || c.title === "Agenda")) {
                _cells.setProperty(i, "action", "detail:calendar")
                changed = true
            }
        }
        // Mark migration as done so it never runs again
        _rawConfig._migrated = "0.8.17"
        saveConfig()
    }

    // ─── Sauvegarde vers user_config.json ────────────────────
    function saveConfig() {
        // CRITICAL PROTECTION: Only warn about empty cells, but still save
        // all other settings (toggles, preferences, etc.)
        if (_cells.count === 0) {
            console.warn("BeeConfig: Saving with empty cells model — cells may not be loaded yet. 🐝⚠️")
        }
        
        // Rebuild cells array from live model
        var cells = []
        for (var i = 0; i < _cells.count; i++) {
            var c = _cells.get(i)
            cells.push({
                icon:         c.icon,
                title:        c.title,
                subtitle:     c.subtitle  || "",
                detail:       c.detail    || "",
                action:       c.action    || "none",
                highlighted:  c.highlighted  || false,
                customizable: c.customizable !== false,
                color:        c.color     || ""
            })
        }

        // Create a COPY of _rawConfig to avoid modifying the original
        var cfg = JSON.parse(JSON.stringify(_rawConfig))
        
        // Update only dynamically managed fields
        cfg.lang         = uiLang
        cfg.launch_at_startup = launchAtStartup
        cfg.stealth_mode = stealthMode
        cfg.vibe_mode    = vibeMode
        cfg.vibe_backend  = vibeBackend
        cfg.vibe_xray     = vibeXray
        cfg.vibe_xray_dir = vibeXrayDir
        cfg.vibe_xray_intensity = vibeXrayIntensity
        cfg.vibe_xray_blend    = vibeXrayBlend
        cfg.contextual_bar = contextualBar
        cfg.focus_mode   = focusMode
        cfg.bee_focus_state = beeFocusState
        cfg.bee_keybinds = beeKeybinds
        cfg.corners_mode = cornersMode
        cfg.motion_mode  = motionMode
        cfg.analog_clock = analogClock
        cfg.beebar_stats = {
            cpu: showCpu,
            ram: showRam,
            net: showNet,
            disk: showDisk,
            battery: showBattery
        }
        cfg.sound = {
            night_mode: soundNightMode,
            night_start_hour: soundNightStartHour,
            night_end_hour: soundNightEndHour,
            day_gain: soundDayGain,
            night_gain: soundNightGain
        }
        cfg.pinned_apps  = Array.isArray(pinnedApps) ? pinnedApps : []
        cfg.context_rules = context_rules
        cfg.events_enabled = eventsEnabled
        cfg.events_live_path = eventsLivePath
        
        // Save calendars array
        var calArray = []
        for (var k = 0; k < _calendars.count; k++) {
            var cal = _calendars.get(k)
            var entry = {
                id: cal.id,
                type: cal.type || "ics",
                label: cal.label || "",
                color: cal.color || "#FFB81C"
            }
            // Preserve type-specific fields
            if (cal.type === "google_api" || cal.calendar_id) {
                entry.calendar_id = cal.calendar_id || ""
            }
            if (cal.type === "ics" || cal.url) {
                entry.url = cal.url || ""
            }
            calArray.push(entry)
        }
        cfg.calendars = calArray

        // ─── BeeCalendar config ────────────────────────────
        cfg.bee_calendar = {
            enabled: true,
            default_view: calendarView,
            reminder_enabled: beeCalendarReminderEnabled,
            reminder_minutes: beeCalendarReminderMinutes,
            snooze_duration_min: beeCalendarSnoozeDurationMin,
            reminder_sound: beeCalendarReminderSound,
            poll_interval_min: beeCalendarPollIntervalMin,
            calendars: [
                { id: "powerland@gmail.com", label: "Personnel", color: "#4A90D9" },
                { id: "family01761025763253819175@group.calendar.google.com", label: "Famille", color: "#FFB81C" },
                { id: "e2vcp5c26oqp0aobdfpoceg687mr8h4h@import.calendar.google.com", label: "Pharmacie", color: "#4CAF50" }
            ]
        }

        console.log("BeeConfig: Sauvegarde de pinned_apps →", JSON.stringify(cfg.pinned_apps))
        cfg.alarm_enabled = alarmEnabled
        cfg.alarm_advance_min = alarmAdvanceMin
        cfg.alarm_snooze_min = alarmSnoozeMin
        cfg.nectar_auto_schedule = nectarAutoSchedule
        cfg.color_therapy_enabled = colorTherapyEnabled
        cfg.auto_theme_mode = autoThemeMode
        cfg.theme = BeeTheme.mode
        cfg.nectar_sync = {
            enabled: BeeTheme.nectarSync,
            auto_suggest: true,
            time_aware: (_rawConfig.nectar_sync && typeof _rawConfig.nectar_sync === 'object') ? (_rawConfig.nectar_sync.time_aware !== false) : true,
            weather_aware: (_rawConfig.nectar_sync && typeof _rawConfig.nectar_sync === 'object') ? (_rawConfig.nectar_sync.weather_aware !== false) : true,
            timezone: (_rawConfig.nectar_sync && _rawConfig.nectar_sync.timezone) || "America/Toronto",
            color_therapy: (_rawConfig.nectar_sync && typeof _rawConfig.nectar_sync === 'object' && _rawConfig.nectar_sync.color_therapy) ? JSON.parse(JSON.stringify(_rawConfig.nectar_sync.color_therapy)) : {},
            adaptive: (_rawConfig.nectar_sync && typeof _rawConfig.nectar_sync === 'object' && _rawConfig.nectar_sync.adaptive) ? JSON.parse(JSON.stringify(_rawConfig.nectar_sync.adaptive)) : {}
        }
        
        if (!cfg.weather) cfg.weather = {}
        cfg.weather.city = weatherCity
        cfg.weather.unit = weatherUnit
        cfg.weather.lang = weatherLang

        if (!cfg.transitions) cfg.transitions = {}
        cfg.transitions.theme_duration_ms = BeeTheme.transitionDuration

        // ─── BeeVoice config ──────────────────────────────────
        cfg.bee_voice = {
            enabled: voiceEnabled,
            ollama_model: voiceOllamaModel,
            ollama_url: voiceOllamaUrl,
            elevenlabs_voice_id: voiceElevenlabsVoiceId,
            elevenlabs_model_id: voiceElevenlabsModelId,
            tts_backend: voiceTtsBackend,
            edge_tts_voice: voiceEdgeTtsVoice,
            edge_tts_rate: voiceEdgeTtsRate,
            record_duration: voiceRecordDuration,
            whisper_model: voiceWhisperModel
        }

        if (!cfg.dashboard) cfg.dashboard = {}
        cfg.dashboard.title = dashTitle
        cfg.dashboard.cells = cells

        // ─── CalDAV config 🐝☁️ v0.8.23 ─────────────────────
        cfg.caldav = {
            enabled: caldavEnabled,
            server_url: caldavUrl,
            username: caldavUsername,
            password: caldavPassword,
            calendar_name: caldavCalendarName,
            auto_sync: caldavAutoSync,
            auto_sync_interval_min: caldavAutoSyncIntervalMin,
            last_sync: caldavLastSync
        }

        // ─── Accessibility config 🐝♿ ──────────────────────────
        cfg.accessibility = {
            high_contrast: accessibilityHighContrast,
            text_scale: accessibilityTextScale,
            reduced_motion: accessibilityReducedMotion,
            level: accessibilityLevel,
            screen_reader: accessibilityScreenReader
        }

        // ─── Battery Mode config 🐝🔋 ──────────────────────
        cfg.battery_mode = {
            enabled: batteryMode,
            auto: batteryModeAuto,
            threshold: batteryThreshold
        }

        // ─── Plugin System v2 config 🐝🧩 ─────────────────────
        cfg.plugins = {
            enabled: pluginsEnabled,
            auto_update: pluginAutoUpdate,
            list: Array.isArray(pluginList) ? pluginList : []
        }

        // ─── BeeProfiles config ────────────────────────────
        cfg.active_profile = BeeProfiles.activeProfileId
        cfg.profiles = BeeProfiles.profiles

        console.log("BeeConfig: Saving", cells.length, "cells 🐝💾")
        
        // Update _rawConfig in memory so subsequent overlays use current values
        _rawConfig = JSON.parse(JSON.stringify(cfg))
        
        var jsonStr = JSON.stringify(cfg, null, 2)
        var filepath = Qt.resolvedUrl("../user_config.json").toString().replace("file://", "")

        // Robust save via heredoc to avoid escaping issues
        // and the absence of 'env' property on some Quickshell versions.
        _saveProc.running = false
        _saveProc.command = ["bash", "-c", "cat << 'BEEEOF' > " + filepath + "\n" + jsonStr + "\nBEEEOF"]
        _saveProc.running = true
    }

    function loadDefaults() {
        _cells.clear()
        // Try to load localized cells if i18n is available
        var localized = false
        var cellKeys = ["calendar", "email", "beehive", "weather", "system", "network", "analytics", "settings"]
        for (var i = 0; i < cellKeys.length; i++) {
            var key = cellKeys[i]
            var cell = trCell(key)
            if (cell) {
                _cells.append(cell)
                localized = true
            } else {
                // Fallback to hardcoded English if translation missing
                localized = false
                break
            }
        }
        if (!localized) {
            // Fallback to English defaults
            _cells.clear()
            _cells.append({ icon: "📅",  title: "Calendar",        subtitle: "Schedule",             detail: "3 events today\n1 reminder",               action: "detail:calendar", highlighted: false, customizable: true })
            _cells.append({ icon: "📧",  title: "Email",           subtitle: "Inbox",                detail: "5 unread messages\n2 drafts",              action: "app:thunderbird",    highlighted: false, customizable: true })
            _cells.append({ icon: "🐝",  title: "Bee-Hive OS",     subtitle: "Online",               detail: "Framework Active\nAll systems go",         action: "none",            highlighted: true,  customizable: true })
            _cells.append({ icon: "🌤️", title: "Weather",         subtitle: "Forecast",             detail: "Sunny, 22°C\nLight breeze",                action: "none",            highlighted: false, customizable: true })
            _cells.append({ icon: "🖥️", title: "System",          subtitle: "CachyOS",              detail: "CPU/GPU/RAM\nTemperatures",                    action: "detail:sysmon",    highlighted: false, customizable: true })
            _cells.append({ icon: "📊",  title: "Analytics",       subtitle: "Dashboard",            detail: "CPU: 15%\nRAM: 4.2 GB",                    action: "detail:sysmon",  highlighted: false, customizable: true })
            _cells.append({ icon: "🌐",  title: "Network",          subtitle: "Connected",           detail: "Real-time stats\n& Speed Test",             action: "detail:network",  highlighted: true,  customizable: true })
            _cells.append({ icon: "⚙️",  title: "Settings",        subtitle: "Bee-Hive OS",          detail: "Configuration\n& Preferences",            action: "toggle:settings", highlighted: false, customizable: true })
        }
    }
}
