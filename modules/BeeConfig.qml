pragma Singleton
import QtQuick
import QtCore
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeConfig.qml — BeeConfig System 🐝📋  (Global Singleton)
// Loads user_config.json and exposes dashboard data
// Access: BeeConfig.cells, BeeConfig.weatherCity, etc.
// ═══════════════════════════════════════════════════════════════

QtObject {
    id: root

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

    // ─── Mode Focus 🎯 ──────────────────────────────────────────
    property bool focusMode: false
    onFocusModeChanged: {
        BeeBarState.focusActive = focusMode
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

    // ─── Window Icons Configuration ──────────────────────────
    property var window_icons: ({})

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

    signal eventsReloadRequested()
    signal configLoaded()

    function reloadLiveEvents() {
        eventsReloadRequested()
    }

    // ─── Sync properties to BeeBarState ─────────────────────
    // Removed old redundant listeners as they are now handled above with auto-save.

    // ─── UI language (i18n) ────────────────────────────────────
    property string uiLang: "fr"
    property var    tr:     ({})

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

        if (overlayCfg.auto_theme && typeof overlayCfg.auto_theme === "object" &&
            overlayCfg.auto_theme.palette && typeof overlayCfg.auto_theme.palette === "object") {
            merged.auto_theme = {
                enabled: overlayCfg.auto_theme.enabled !== false,
                source_wallpaper: overlayCfg.auto_theme.source_wallpaper || "",
                generated_at: overlayCfg.auto_theme.generated_at || "",
                engine: overlayCfg.auto_theme.engine || "",
                palette: overlayCfg.auto_theme.palette
            }
        } else {
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
        _autoThemeProc.command = [
            "python3",
            autoThemeScriptPath,
            "--wallpaper",
            normalized,
            "--mode",
            modeArg,
            "--output",
            autoThemeOverlayPath
        ]
        _autoThemeProc.running = true
        return true
    }

    function applyConfig(cfg, rawCfg) {
        _rawConfig = JSON.parse(JSON.stringify(rawCfg !== undefined ? rawCfg : cfg))
        console.log("BeeConfig: Application de la configuration...")
        
        // ... (autres propriétés)
        if (cfg.stealth_mode !== undefined) stealthMode = cfg.stealth_mode === true
        if (cfg.vibe_mode !== undefined)    vibeMode = cfg.vibe_mode === true
        if (cfg.focus_mode !== undefined)   focusMode = cfg.focus_mode === true
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
                color: "#FFB81C"
            })
            console.log("BeeConfig: Legacy URL migrée dans la liste.")
        }

        // Ajouter les autres calendriers de la config
        for (var c = 0; c < calendarsList.length; c++) {
            // Éviter les doublons si on vient de migrer
            if (calendarsList[c].url !== cfg.events_ics_url || !hasLegacyUrl) {
                _calendars.append(calendarsList[c])
            }
        }

        if (cfg.lang !== undefined && cfg.lang !== uiLang) {
            uiLang = cfg.lang
            loadI18n(uiLang)
        }

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
                    
                    // --- MIGRATION CRITIQUE ---
                    // On force le déverrouillage de TOUT sauf du logo central
                    // Cela règle les problèmes de fichiers config corrompus par d'anciennes versions
                    var isLogo = (cell.title === "Bee-Hive OS" || cell.icon === "🐝")
                    var canEdit = isLogo ? false : true
                    
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
                            var isDefLogo = (cellKeys[k] === "beehive")
                            _cells.append({
                                icon: def.icon, title: def.title, subtitle: def.subtitle,
                                detail: def.detail, action: def.action,
                                highlighted: def.highlighted, customizable: !isDefLogo
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
        if (cfg.nectar_sync !== undefined) BeeTheme.nectarSync = cfg.nectar_sync === true

        root._loaded = true
        root.configLoaded()
    }

    // ─── Sauvegarde vers user_config.json ────────────────────
    function saveConfig() {
        // CRITICAL PROTECTION: NEVER save if cells are not loaded!
        if (_cells.count === 0) {
            console.warn("BeeConfig: REFUSING to save — empty cells! Protection enabled. 🐝🛡️")
            return
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
        cfg.stealth_mode = stealthMode
        cfg.vibe_mode    = vibeMode
        cfg.focus_mode   = focusMode
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
        cfg.events_enabled = eventsEnabled
        cfg.events_live_path = eventsLivePath
        
        // Save calendars array
        var calArray = []
        for (var k = 0; k < _calendars.count; k++) {
            var cal = _calendars.get(k)
            calArray.push({
                id: cal.id,
                type: cal.type || "ics",
                url: cal.url || "",
                label: cal.label || "",
                color: cal.color || "#FFB81C"
            })
        }
        cfg.calendars = calArray

        console.log("BeeConfig: Sauvegarde de pinned_apps →", JSON.stringify(cfg.pinned_apps))
        cfg.theme = BeeTheme.mode
        cfg.nectar_sync = BeeTheme.nectarSync
        
        if (!cfg.weather) cfg.weather = {}
        cfg.weather.city = weatherCity
        cfg.weather.unit = weatherUnit
        cfg.weather.lang = weatherLang

        if (!cfg.transitions) cfg.transitions = {}
        cfg.transitions.theme_duration_ms = BeeTheme.transitionDuration
        
        if (!cfg.dashboard) cfg.dashboard = {}
        cfg.dashboard.title = dashTitle
        cfg.dashboard.cells = cells

        console.log("BeeConfig: Saving", cells.length, "cells 🐝💾")
        
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
                // Special case: Bee-Hive logo cell is protected by default
                if (key === "beehive") cell.customizable = false
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
            _cells.append({ icon: "📅",  title: "Calendar",        subtitle: "Schedule",             detail: "3 events today\n1 reminder",               action: "app:calendar",    highlighted: false, customizable: true })
            _cells.append({ icon: "📧",  title: "Email",           subtitle: "Inbox",                detail: "5 unread messages\n2 drafts",              action: "app:email",       highlighted: false, customizable: true })
            _cells.append({ icon: "🐝",  title: "Bee-Hive OS",     subtitle: "Online",               detail: "Framework Active\nAll systems go",         action: "none",            highlighted: true,  customizable: false })
            _cells.append({ icon: "🌤️", title: "Weather",         subtitle: "Forecast",             detail: "Sunny, 22°C\nLight breeze",                action: "none",            highlighted: false, customizable: true })
            _cells.append({ icon: "🖥️", title: "System",          subtitle: "CachyOS",              detail: "Hyprland\nQuickshell",                     action: "app:terminal",    highlighted: false, customizable: true })
            _cells.append({ icon: "📊",  title: "Analytics",       subtitle: "Dashboard",            detail: "CPU: 15%\nRAM: 4.2 GB",                    action: "none",            highlighted: false, customizable: true })
            _cells.append({ icon: "🌐",  title: "Network",          subtitle: "Connected",           detail: "Real-time stats\n& Speed Test",             action: "detail:network",  highlighted: true,  customizable: true })
            _cells.append({ icon: "⚙️",  title: "Settings",        subtitle: "Bee-Hive OS",          detail: "Configuration\n& Preferences",            action: "toggle:settings", highlighted: false, customizable: true })
        }
    }
}
