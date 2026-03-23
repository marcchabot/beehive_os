pragma Singleton
import QtQuick
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

    // ─── BeeVibe ───────────────────────────────────────────────
    property bool vibeMode: false

    // ─── Mode Focus 🎯 ──────────────────────────────────────────
    property bool focusMode: false

    // ─── BeeCorners 🐝📱 ───────────────────────────────────────
    property bool cornersMode: true

    // ─── BeeMotion (Parallax) ──────────────────────────────────
    property bool motionMode: true

    // ─── BeeBar Visibility ────────────────────────────────────
    property bool showCpu: true
    property bool showRam: true
    property bool showNet: true
    property bool showDisk: true
    property bool showBattery: true

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

    // ─── BeeEvents ────────────────────────────────────────────
    property bool eventsEnabled: true

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

    // ─── Raw config (preserved for saving) ─────────────────────
    property var _rawConfig: ({})

    // ─── Save process ──────────────────────────────────────────
    property Process saveProc: Process {
        id: _saveProc
        running: false
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
                    applyConfig(JSON.parse(xhr.responseText))
                    return
                } catch (e) {
                    console.warn("BeeConfig: Erreur JSON →", e)
                }
            }
            loadDefaults()
        }
        xhr.send()
    }

    function applyConfig(cfg) {
        _rawConfig = cfg
        console.log("BeeConfig: Application de la configuration (pinned_apps:", JSON.stringify(cfg.pinned_apps || []), ")")
        if (cfg.stealth_mode !== undefined)
            stealthMode = cfg.stealth_mode === true
        if (cfg.vibe_mode !== undefined)
            vibeMode = cfg.vibe_mode === true
        if (cfg.focus_mode !== undefined)
            focusMode = cfg.focus_mode === true
        if (cfg.corners_mode !== undefined)
            cornersMode = cfg.corners_mode === true
        if (cfg.motion_mode !== undefined)
            motionMode = cfg.motion_mode === true
        if (cfg.analog_clock !== undefined)
            analogClock = cfg.analog_clock === true
        if (cfg.beebar_stats !== undefined) {
            showCpu = cfg.beebar_stats.cpu !== false
            showRam = cfg.beebar_stats.ram !== false
            showNet = cfg.beebar_stats.net !== false
            showDisk = cfg.beebar_stats.disk !== false
            showBattery = cfg.beebar_stats.battery === true
        }
        if (cfg.pinned_apps !== undefined && Array.isArray(cfg.pinned_apps))
            pinnedApps = cfg.pinned_apps
        if (cfg.bee_events !== undefined)
            eventsEnabled = cfg.bee_events.enabled !== false
        if (cfg.lang !== undefined && cfg.lang !== uiLang) {
            uiLang = cfg.lang
            loadI18n(uiLang)
        }
        if (cfg.weather) {
            weatherCity = cfg.weather.city || weatherCity
            weatherUnit = cfg.weather.unit || weatherUnit
            weatherLang = cfg.weather.lang || weatherLang

            // Auto-update coordinates if it's a known location
            if (weatherCity === "Blainville") {
                weatherLat = 45.67
                weatherLon = -73.88
            } else if (weatherCity === "Mont-Tremblant" || weatherCity === "Tremblant") {
                weatherLat = 46.12
                weatherLon = -74.60
            }
        }
        if (cfg.dashboard) {
            dashTitle = cfg.dashboard.title || dashTitle
            if (cfg.dashboard.cells && cfg.dashboard.cells.length > 0) {
                _cells.clear()
                for (var i = 0; i < cfg.dashboard.cells.length; i++)
                    _cells.append(cfg.dashboard.cells[i])
            } else {
                loadDefaults()
            }
        }
        // Apply configured transition duration
        if (cfg.transitions && cfg.transitions.theme_duration_ms)
            BeeTheme.transitionDuration = cfg.transitions.theme_duration_ms
        // Nectar Sync 🍯
        if (cfg.nectar_sync !== undefined)
            BeeTheme.nectarSync = cfg.nectar_sync === true
        // Apply saved theme (animated via setMode)
        if (cfg.theme && cfg.theme !== BeeTheme.mode)
            BeeTheme.setMode(cfg.theme)
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
        cfg.pinned_apps  = Array.isArray(pinnedApps) ? pinnedApps : []
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
        _cells.append({ icon: "📅",  title: "Calendar",        subtitle: "Schedule",             detail: "3 events today\n1 reminder",               action: "app:calendar",    highlighted: false })
        _cells.append({ icon: "📧",  title: "Email",           subtitle: "Inbox",                detail: "5 unread messages\n2 drafts",              action: "app:email",       highlighted: false })
        _cells.append({ icon: "🐝",  title: "Bee-Hive OS",     subtitle: "Online",               detail: "Framework Active\nAll systems go",         action: "none",            highlighted: true  })
        _cells.append({ icon: "🌤️", title: "Weather",         subtitle: "Forecast",             detail: "Sunny, 22°C\nLight breeze",                action: "none",            highlighted: false })
        _cells.append({ icon: "🖥️", title: "System",          subtitle: "CachyOS",              detail: "Hyprland\nQuickshell",                     action: "app:terminal",    highlighted: false })
        _cells.append({ icon: "📊",  title: "Analytics",       subtitle: "Dashboard",            detail: "CPU: 15%\nRAM: 4.2 GB",                    action: "none",            highlighted: false })
        _cells.append({ icon: "🎮",  title: "Gaming",          subtitle: "Steam",                detail: "Ready to play?\nLibrary: 42 games",        action: "app:steam",       highlighted: false })
        _cells.append({ icon: "⚙️",  title: "Settings",        subtitle: "Bee-Hive OS",          detail: "Configuration\n& Preferences",            action: "toggle:settings", highlighted: false })
    }
}
alse })
    }
}
    }
}
}

    }
}
}
  }
}
}
