pragma Singleton
import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════════
// BeePresets.qml — Alvéoles Presets Manager 🐝✨
// Permet de basculer entre des configurations de grille prédéfinies.
// v2.1: Fixed QtObject child property error; drag reordering support
// ═══════════════════════════════════════════════════════════════════

QtObject {
    id: beePresets

    // ─── Built-in default presets (fallback if none in config) ───
    readonly property var _builtInPresets: [
        {
            name: "Travail",
            icon: "💼",
            cells: [
                { icon: "📅", title: "Calendrier", subtitle: "Planning", detail: "Réunions & Tâches", action: "app:calendar", highlighted: true, customizable: true },
                { icon: "📧", title: "Emails", subtitle: "Inbox", detail: "Courriers prioritaires", action: "app:email", highlighted: true, customizable: true },
                { icon: "📝", title: "Notes", subtitle: "BeeNotes", detail: "Idées & Rappels", action: "app:notes", highlighted: false, customizable: true },
                { icon: "🐝", title: "Bee-Hive OS", subtitle: "Système", detail: "Framework Active", action: "none", highlighted: true, customizable: false },
                { icon: "🌐", title: "Réseau", subtitle: "Connecté", detail: "Vitesse & Latence", action: "detail:network", highlighted: false, customizable: true },
                { icon: "🖥️", title: "Système", subtitle: "CachyOS", detail: "Ressources", action: "app:terminal", highlighted: false, customizable: true },
                { icon: "📊", title: "Analytique", subtitle: "KPIs", detail: "Performance", action: "none", highlighted: false, customizable: true },
                { icon: "⚙️", title: "Paramètres", subtitle: "Config", detail: "Préférences", action: "toggle:settings", highlighted: false, customizable: true }
            ]
        },
        {
            name: "Gaming",
            icon: "🎮",
            cells: [
                { icon: "🎮", title: "Gaming", subtitle: "GeForce Now", detail: "Cloud Gaming\nNVIDIA GeForce Now", action: "app:flatpak run com.nvidia.geforcenow", highlighted: true, customizable: true },
                { icon: "🎧", title: "Audio", subtitle: "Mixer", detail: "Optimisation Gaming", action: "app:mixer", highlighted: false, customizable: true },
                { icon: "🌐", title: "Réseau", subtitle: "Ping", detail: "Stats temps réel", action: "detail:network", highlighted: true, customizable: true },
                { icon: "🐝", title: "Bee-Hive OS", subtitle: "Système", detail: "Game Mode Active", action: "none", highlighted: true, customizable: false },
                { icon: "🖥️", title: "Système", subtitle: "CachyOS", detail: "GPU/CPU Temp", action: "app:terminal", highlighted: true, customizable: true },
                { icon: "🌙", title: "Focus", subtitle: "Anti-distraction", detail: "Notifications OFF", action: "toggle:focus", highlighted: false, customizable: true },
                { icon: "🔋", title: "Power", subtitle: "Performance", detail: "High Performance Mode", action: "none", highlighted: false, customizable: true },
                { icon: "⚙️", title: "Paramètres", subtitle: "Config", detail: "Préférences", action: "toggle:settings", highlighted: false, customizable: true }
            ]
        },
        {
            name: "Weekend",
            icon: "🌿",
            cells: [
                { icon: "🌤️", title: "Météo", subtitle: "Prévisions", detail: "Sortie prévue ?", action: "none", highlighted: true, customizable: true },
                { icon: "🍿", title: "Loisirs", subtitle: "Streaming", detail: "Films & Séries", action: "app:browser", highlighted: false, customizable: true },
                { icon: "🎨", title: "Design", subtitle: "Création", detail: "Projets Artistiques", action: "app:design", highlighted: false, customizable: true },
                { icon: "🐝", title: "Bee-Hive OS", subtitle: "Système", detail: "Mode Détente", action: "none", highlighted: true, customizable: false },
                { icon: "📅", title: "Agenda", subtitle: "Sorties", detail: "Événements sociaux", action: "app:calendar", highlighted: false, customizable: true },
                { icon: "📖", title: "Lecture", subtitle: "Kindle/PDF", detail: "Lecture en cours", action: "app:reader", highlighted: false, customizable: true },
                { icon: "🌿", title: "Wellness", subtitle: "Santé", detail: "Hydratation & Pauses", action: "none", highlighted: false, customizable: true },
                { icon: "⚙️", title: "Paramètres", subtitle: "Config", detail: "Préférences", action: "toggle:settings", highlighted: false, customizable: true }
            ]
        }
    ]

    // ─── Active presets list (loaded from config or built-in) ───
    property var presets: _builtInPresets

    // ─── i18n helper ──────────────────────────────────────────
    function tr(key) {
        if (BeeConfig.tr && BeeConfig.tr.presets && BeeConfig.tr.presets[key])
            return BeeConfig.tr.presets[key]
        // Fallbacks
        var fb = {
            "title": "Presets",
            "apply": "Apply",
            "save": "Save current",
            "delete": "Delete",
            "applied": "Preset applied",
            "saved": "Preset saved",
            "deleted": "Preset deleted",
            "confirm_delete": "Delete preset?",
            "default_name": "My Preset",
            "module_library": "Module Library",
            "current_grid": "Current Grid",
            "drag_hint": "Drag modules to rearrange"
        }
        return fb[key] || key
    }

    // ─── Available module library for preset editing ────────────
    readonly property var moduleLibrary: [
        { icon: "📅", title: "Calendrier", subtitle: "Planning", detail: "Événements du jour", action: "app:calendar", highlighted: false, customizable: true },
        { icon: "📧", title: "Emails", subtitle: "Inbox", detail: "Courriers", action: "app:email", highlighted: false, customizable: true },
        { icon: "🐝", title: "Bee-Hive OS", subtitle: "Système", detail: "Framework Active", action: "none", highlighted: true, customizable: false },
        { icon: "🌤️", title: "Météo", subtitle: "Prévisions", detail: "Conditions météo", action: "none", highlighted: false, customizable: true },
        { icon: "🌐", title: "Réseau", subtitle: "Connecté", detail: "Stats temps réel", action: "detail:network", highlighted: false, customizable: true },
        { icon: "🖥️", title: "Système", subtitle: "CachyOS", detail: "Ressources", action: "app:terminal", highlighted: false, customizable: true },
        { icon: "🎮", title: "Gaming", subtitle: "GeForce Now", detail: "Cloud Gaming", action: "app:flatpak run com.nvidia.geforcenow", highlighted: false, customizable: true },
        { icon: "📊", title: "Analytique", subtitle: "Dashboard", detail: "Performance", action: "none", highlighted: false, customizable: true },
        { icon: "📝", title: "Notes", subtitle: "BeeNotes", detail: "Idées & Rappels", action: "app:notes", highlighted: false, customizable: true },
        { icon: "⚙️", title: "Paramètres", subtitle: "Config", detail: "Préférences", action: "toggle:settings", highlighted: false, customizable: true },
        { icon: "🌙", title: "Focus", subtitle: "Anti-distraction", detail: "Notifications OFF", action: "toggle:focus", highlighted: false, customizable: true },
        { icon: "🔋", title: "Power", subtitle: "Performance", detail: "High Performance", action: "none", highlighted: false, customizable: true },
        { icon: "🎧", title: "Audio", subtitle: "Mixer", detail: "Contrôle du son", action: "app:mixer", highlighted: false, customizable: true },
        { icon: "🍿", title: "Loisirs", subtitle: "Streaming", detail: "Films & Séries", action: "app:browser", highlighted: false, customizable: true },
        { icon: "📖", title: "Lecture", subtitle: "Kindle/PDF", detail: "Lecture en cours", action: "app:reader", highlighted: false, customizable: true },
        { icon: "🎨", title: "Design", subtitle: "Création", detail: "Projets artistiques", action: "app:design", highlighted: false, customizable: true },
        { icon: "🌿", title: "Wellness", subtitle: "Santé", detail: "Hydratation & Pauses", action: "none", highlighted: false, customizable: true }
    ]

    // ─── Load presets from BeeConfig._rawConfig.cellPresets ─────
    function loadFromConfig() {
        if (!BeeConfig._rawConfig || !BeeConfig._rawConfig.cellPresets) {
            presets = _builtInPresets
            return
        }
        var loaded = BeeConfig._rawConfig.cellPresets
        if (!Array.isArray(loaded) || loaded.length === 0) {
            presets = _builtInPresets
            return
        }
        // Validate each preset has required fields
        var valid = []
        for (var i = 0; i < loaded.length; i++) {
            var p = loaded[i]
            if (p.name && Array.isArray(p.cells) && p.cells.length > 0) {
                valid.push({
                    name: p.name,
                    icon: p.icon || "🍯",
                    cells: p.cells
                })
            }
        }
        if (valid.length > 0) {
            presets = valid
        } else {
            presets = _builtInPresets
        }
    }

    // ─── Apply a preset by name ────────────────────────────────
    function applyPreset(presetName) {
        var preset = null
        for (var i = 0; i < presets.length; i++) {
            if (presets[i].name === presetName) {
                preset = presets[i]
                break
            }
        }
        if (!preset) return false

        BeeConfig.cells.clear()
        for (var i = 0; i < preset.cells.length; i++) {
            var c = preset.cells[i]
            BeeConfig.cells.append({
                icon:         c.icon || "📦",
                title:        c.title || "Module",
                subtitle:     c.subtitle || "",
                detail:       c.detail || "",
                action:       c.action || "none",
                highlighted:  c.highlighted === true,
                customizable: c.customizable !== false,
                color:        c.color || ""
            })
        }
        BeeConfig.cellsRevision++
        BeeConfig.saveConfig()
        BeeBarState.dispatchNotification("Bee-Hive OS", tr("applied") + ": " + presetName, "🍯")
        return true
    }

    // ─── Save current cells as a new preset ─────────────────────
    function saveCurrentAsPreset(name, icon) {
        if (!name || name.trim() === "") return false

        var cells = []
        for (var i = 0; i < BeeConfig.cells.count; i++) {
            var c = BeeConfig.cells.get(i)
            cells.push({
                icon:         c.icon,
                title:        c.title,
                subtitle:     c.subtitle || "",
                detail:       c.detail || "",
                action:       c.action || "none",
                highlighted:  c.highlighted || false,
                customizable: c.customizable !== false,
                color:        c.color || ""
            })
        }

        // Check if preset with same name exists → update it
        var found = false
        var newPresets = []
        for (var i = 0; i < presets.length; i++) {
            if (presets[i].name === name) {
                newPresets.push({ name: name, icon: icon || presets[i].icon, cells: cells })
                found = true
            } else {
                newPresets.push(presets[i])
            }
        }
        if (!found) {
            newPresets.push({ name: name, icon: icon || "🍯", cells: cells })
        }

        presets = newPresets
        _syncToConfig()
        BeeBarState.dispatchNotification("Bee-Hive OS", tr("saved") + ": " + name, "💾")
        return true
    }

    // ─── Delete a preset by name ────────────────────────────────
    function deletePreset(presetName) {
        var newPresets = []
        for (var i = 0; i < presets.length; i++) {
            if (presets[i].name !== presetName) {
                newPresets.push(presets[i])
            }
        }
        if (newPresets.length === presets.length) return false  // not found

        presets = newPresets
        _syncToConfig()
        BeeBarState.dispatchNotification("Bee-Hive OS", tr("deleted") + ": " + presetName, "🗑️")
        return true
    }

    // ─── Move a cell within the current grid (for drag & drop) ──
    function moveCell(fromIndex, toIndex) {
        if (fromIndex === toIndex) return false
        if (fromIndex < 0 || fromIndex >= BeeConfig.cells.count) return false
        if (toIndex < 0 || toIndex >= BeeConfig.cells.count) return false

        // Get source cell data
        var src = BeeConfig.cells.get(fromIndex)
        var cellData = {
            icon:         src.icon,
            title:        src.title,
            subtitle:     src.subtitle || "",
            detail:       src.detail || "",
            action:       src.action || "none",
            highlighted:  src.highlighted || false,
            customizable: src.customizable !== false,
            color:        src.color || ""
        }

        // Remove from old position
        BeeConfig.cells.remove(fromIndex)

        // Re-insert at new position (adjust for removal shift)
        var insertAt = toIndex > fromIndex ? toIndex : toIndex
        BeeConfig.cells.insert(insertAt, cellData)

        BeeConfig.cellsRevision++
        BeeConfig.saveConfig()
        return true
    }

    // ─── Swap two cells (for drag & drop) ───────────────────────
    function swapCells(indexA, indexB) {
        if (indexA === indexB) return false
        if (indexA < 0 || indexA >= BeeConfig.cells.count) return false
        if (indexB < 0 || indexB >= BeeConfig.cells.count) return false

        // Snapshot ALL cells into plain JS objects BEFORE any mutation.
        // ListModel.get() returns a live reference that becomes invalid after
        // remove(), so we must copy everything upfront.
        var snapshot = []
        for (var i = 0; i < BeeConfig.cells.count; i++) {
            var c = BeeConfig.cells.get(i)
            snapshot.push({
                icon:         c.icon         || "",
                title:        c.title        || "",
                subtitle:     c.subtitle     || "",
                detail:       c.detail       || "",
                action:       c.action       || "none",
                highlighted:  c.highlighted   || false,
                customizable: c.customizable !== false,
                color:        c.color        || ""
            })
        }

        // Swap the two entries in the snapshot
        var tmp = snapshot[indexA]
        snapshot[indexA] = snapshot[indexB]
        snapshot[indexB] = tmp

        // Rebuild the entire ListModel from the snapshot
        BeeConfig.cells.clear()
        for (var j = 0; j < snapshot.length; j++) {
            BeeConfig.cells.append(snapshot[j])
        }

        BeeConfig.cellsRevision++
        BeeConfig.saveConfig()
        return true
    }

    // ─── Sync presets to BeeConfig._rawConfig and save ──────────
    function _syncToConfig() {
        if (!BeeConfig._rawConfig) return
        BeeConfig._rawConfig.cellPresets = presets
        BeeConfig.saveConfig()
    }

    // ─── Initialization: load from config or fallback ───────────
    // Using a Timer instead of Component.onCompleted because QtObject
    // doesn't have a default property for child items (Connections, etc.)
    property Timer _initTimer: Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            if (BeeConfig._loaded) {
                beePresets.loadFromConfig()
            }
        }
    }

    // Listen for BeeConfig load completion
    property Connections _configConn: Connections {
        target: BeeConfig
        function onConfigLoaded() {
            beePresets.loadFromConfig()
        }
    }
}