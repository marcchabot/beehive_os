pragma Singleton
import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════════
// BeeProfiles.qml — Multi-User Profile Manager 🐝👤
// v0.8.31: Persistent profiles via profiles.json + profile switching UI
// ═══════════════════════════════════════════════════════════════════

Item {
    id: beeProfiles

    // ─── Hardcoded default profiles (used as fallback) ─────
    readonly property var defaultProfiles: [
        { id: "marc", name: "Marc", icon: "👨‍💻", activeTheme: "HoneyDark", activePreset: "Travail", calendarFilter: ["Personnel","Famille","Pharmacie"], lastSwitched: "" },
        { id: "johanne", name: "Johanne", icon: "👩‍💼", activeTheme: "HoneyLight", activePreset: "Weekend", calendarFilter: ["Famille"], lastSwitched: "" },
        { id: "noah", name: "Noah", icon: "🧒", activeTheme: "HoneyDark", activePreset: "Gaming", calendarFilter: ["Famille"], lastSwitched: "" }
    ]

    // ─── Profile Data ──────────────────────────────────────
    property var profiles: []

    property string activeProfileId: "marc"

    // ─── Computed ───────────────────────────────────────────
    readonly property var currentProfile: {
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === activeProfileId) return profiles[i]
        }
        return profiles.length > 0 ? profiles[0] : defaultProfiles[0]
    }

    readonly property int profileCount: profiles.length

    // ─── Profiles file path ─────────────────────────────────
    readonly property string profilesPath: BeeConfig.configDir + "/profiles.json"

    // ─── Initialization flag ────────────────────────────────
    property bool _initialized: false

    // ─── Process for saving profiles.json ───────────────────
    property Process _saveProc: Process {
        id: _saveProfilesProc
        running: false
    }

    // ─── Load profiles from file on startup ──────────────────
    Component.onCompleted: {
        _loadProfilesFromFile()
    }

    // ─── Load profiles from JSON file ────────────────────────
    function _loadProfilesFromFile() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + profilesPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            var savedProfiles = null
            var savedActiveId = null
            if (xhr.status === 200 || xhr.status === 0) {
                try {
                    var text = xhr.responseText.trim()
                    if (text !== "") {
                        var parsed = JSON.parse(text)
                        if (Array.isArray(parsed)) {
                            savedProfiles = parsed
                        } else if (parsed && parsed.profiles) {
                            savedProfiles = parsed.profiles
                            savedActiveId = parsed.activeProfile || null
                        }
                    }
                } catch (e) {
                    console.warn("BeeProfiles: Error parsing profiles.json →", e)
                }
            }
            _mergeAndApply(savedProfiles, savedActiveId)
        }
        xhr.send()
    }

    // ─── Merge saved profiles with defaults ─────────────────
    // If a saved profile matches by ID, use the saved data.
    // New hardcoded defaults not in the file get added.
    function _mergeAndApply(savedProfiles, savedActiveId) {
        var merged = []
        var savedById = {}

        // Index saved profiles by ID for O(1) lookup
        if (savedProfiles && Array.isArray(savedProfiles)) {
            for (var s = 0; s < savedProfiles.length; s++) {
                if (savedProfiles[s] && savedProfiles[s].id) {
                    savedById[savedProfiles[s].id] = savedProfiles[s]
                }
            }
        }

        // Start with defaults, override with saved data
        for (var d = 0; d < defaultProfiles.length; d++) {
            var def = defaultProfiles[d]
            if (savedById[def.id]) {
                // Saved profile exists — merge: saved overrides defaults
                var mergedProfile = {}
                for (var key in def) mergedProfile[key] = def[key]
                for (var key in savedById[def.id]) mergedProfile[key] = savedById[def.id][key]
                merged.push(mergedProfile)
                delete savedById[def.id]
            } else {
                // No saved version — use default
                merged.push(JSON.parse(JSON.stringify(def)))
            }
        }

        // Add any saved profiles not in defaults (user-created profiles)
        for (var id in savedById) {
            if (savedById.hasOwnProperty(id)) {
                merged.push(savedById[id])
            }
        }

        profiles = merged

        // Set active profile
        if (savedActiveId) {
            activeProfileId = savedActiveId
        }

        _initialized = true

        // Save to file if no saved profiles existed (first run)
        if (!savedProfiles) {
            _saveProfiles()
        }
    }

    // ─── Save profiles to JSON file ─────────────────────────
    function _saveProfiles() {
        if (!_initialized) return  // Don't save before loading
        var data = {
            activeProfile: activeProfileId,
            profiles: profiles
        }
        var jsonStr = JSON.stringify(data, null, 2)

        // Ensure directory exists and write file via Process
        var dir = profilesPath.substring(0, profilesPath.lastIndexOf("/"))
        _saveProc.running = false
        _saveProc.command = ["bash", "-c",
            "mkdir -p '" + dir + "' && cat << 'BEEEOF' > '" + profilesPath + "'\n" + jsonStr + "\nBEEEOF"
        ]
        _saveProc.running = true
    }

    // ─── Profile Operations ────────────────────────────────
    function switchProfile(profileId) {
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === profileId) {
                var p = profiles[i]
                p.lastSwitched = new Date().toISOString()
                activeProfileId = profileId
                applyProfileSettings(p)
                _saveProfiles()
                // Sync to BeeConfig
                if (typeof BeeConfig !== 'undefined') {
                    BeeConfig.activeProfileId = profileId
                    BeeConfig.saveConfig()
                }
                return true
            }
        }
        return false
    }

    function createProfile(name, icon) {
        var id = name.toLowerCase().replace(/\s+/g, "_").replace(/[^a-z0-9_]/g, "")
        // Ensure unique ID
        var baseId = id
        var counter = 1
        while (getProfileById(id)) {
            id = baseId + "_" + counter
            counter++
        }
        var newProfile = {
            id: id,
            name: name,
            icon: icon || "👤",
            activeTheme: (typeof BeeTheme !== 'undefined') ? (BeeTheme.mode || "HoneyDark") : "HoneyDark",
            activePreset: "Travail",
            calendarFilter: ["Famille"],
            lastSwitched: ""
        }
        var newProfiles = profiles.slice()
        newProfiles.push(newProfile)
        profiles = newProfiles
        _saveProfiles()
        // Sync to BeeConfig
        if (typeof BeeConfig !== 'undefined') {
            BeeConfig.saveConfig()
        }
        return id
    }

    function deleteProfile(profileId) {
        if (profileId === "marc") return false  // Can't delete default
        var newProfiles = []
        var found = false
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === profileId) {
                found = true
                continue  // Skip deleted profile
            }
            newProfiles.push(profiles[i])
        }
        if (!found) return false
        profiles = newProfiles
        if (activeProfileId === profileId) {
            activeProfileId = "marc"
        }
        _saveProfiles()
        // Sync to BeeConfig
        if (typeof BeeConfig !== 'undefined') {
            BeeConfig.activeProfileId = activeProfileId
            BeeConfig.saveConfig()
        }
        return true
    }

    function getProfileById(profileId) {
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === profileId) return profiles[i]
        }
        return null
    }

    // ─── Load config from BeeConfig ─────────────────────────
    // Called by BeeConfig after loading user_config.json
    // BeeProfiles loads its own profiles.json first, then BeeConfig may
    // pass additional data from user_config.json for backwards compatibility.
    function loadFromConfig(cfg) {
        if (!_initialized) {
            // BeeProfiles hasn't loaded its own file yet.
            // loadFromConfig will be called again after BeeConfig finishes loading.
            // We'll let _loadProfilesFromFile handle initialization.
            // But store the config data for later.
            _pendingConfig = cfg
            return
        }

        // BeeProfiles is already initialized from profiles.json.
        // If BeeConfig also has profiles data, we merge it in.
        if (cfg && cfg.profiles && Array.isArray(cfg.profiles) && cfg.profiles.length > 0) {
            _mergeAndApply(cfg.profiles, cfg.activeProfile)
        } else if (cfg && cfg.activeProfile) {
            activeProfileId = cfg.activeProfile
        }
    }

    // Store pending config from BeeConfig if we haven't loaded yet
    property var _pendingConfig: null

    // After initialization, apply pending config if any
    on_InitializedChanged: {
        if (_initialized && _pendingConfig) {
            loadFromConfig(_pendingConfig)
            _pendingConfig = null
        }
    }

    function applyProfileSettings(profile) {
        if (profile.activeTheme && typeof BeeTheme !== 'undefined') {
            BeeTheme.mode = profile.activeTheme
        }
        if (profile.activePreset && typeof BeePresets !== 'undefined') {
            BeePresets.applyPreset(profile.activePreset)
        }
    }

    // ─── Transition overlay state ─────────────────────────
    property bool transitionActive: false
    property real transitionOpacity: 0.0

    function switchWithTransition(profileId) {
        transitionActive = true
        transitionOpacity = 0.0
        transitionAnim.start()
        switchProfile(profileId)
        // Toast notification
        var profile = getProfileById(profileId)
        if (profile && typeof BeeBarState !== 'undefined') {
            BeeBarState.dispatchNotification("👤 Profile", profile.name, profile.icon || "👤")
        }
    }

    NumberAnimation {
        id: transitionAnim
        target: beeProfiles
        property: "transitionOpacity"
        from: 0.0
        to: 1.0
        duration: 300
        easing.type: Easing.InOutQuad
        onFinished: {
            fadeOutAnim.start()
        }
    }

    NumberAnimation {
        id: fadeOutAnim
        target: beeProfiles
        property: "transitionOpacity"
        from: 1.0
        to: 0.0
        duration: 300
        easing.type: Easing.InOutQuad
        onFinished: {
            transitionActive = false
        }
    }
}