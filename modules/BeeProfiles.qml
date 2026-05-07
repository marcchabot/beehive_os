pragma Singleton
import QtQuick
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════════
// BeeProfiles.qml — Multi-User Profile Manager 🐝👤
// v0.8.22: Profile switching with independent configs
// NOTE: Persistence temporarily disabled — profiles are in-memory only.
//       JSON persistence will be re-implemented in a future release
//       using the proper Quickshell Process + SplitParser pattern.
// ═══════════════════════════════════════════════════════════════════

Item {
    id: beeProfiles

    // ─── Profile Data (in-memory only for now) ────────────
    property var profiles: [
        { id: "marc", name: "Marc", icon: "👨‍💻", activeTheme: "HoneyDark", activePreset: "Travail", calendarFilter: ["Personnel","Famille","Pharmacie"], lastSwitched: "" },
        { id: "johanne", name: "Johanne", icon: "👩‍💼", activeTheme: "HoneyLight", activePreset: "Weekend", calendarFilter: ["Famille"], lastSwitched: "" },
        { id: "noah", name: "Noah", icon: "🧒", activeTheme: "HoneyDark", activePreset: "Gaming", calendarFilter: ["Famille"], lastSwitched: "" }
    ]

    property string activeProfileId: "marc"

    // ─── Computed ─────────────────────────────────────────
    readonly property var currentProfile: {
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === activeProfileId) return profiles[i]
        }
        return profiles[0]
    }

    readonly property int profileCount: profiles.length

    // ─── Profile Operations ───────────────────────────────
    function switchProfile(profileId) {
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === profileId) {
                var p = profiles[i]
                p.lastSwitched = new Date().toISOString()
                activeProfileId = profileId
                applyProfileSettings(p)
                return true
            }
        }
        return false
    }

    function createProfile(name, icon) {
        var id = name.toLowerCase().replace(/\s+/g, "_")
        var newProfile = {
            id: id,
            name: name,
            icon: icon || "👤",
            activeTheme: BeeTheme.mode || "HoneyDark",
            activePreset: "Travail",
            calendarFilter: ["Famille"],
            lastSwitched: ""
        }
        profiles.push(newProfile)
        return id
    }

    function deleteProfile(profileId) {
        if (profileId === "marc") return false
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === profileId) {
                profiles.splice(i, 1)
                if (activeProfileId === profileId) {
                    activeProfileId = "marc"
                }
                return true
            }
        }
        return false
    }

    function getProfileById(profileId) {
        for (var i = 0; i < profiles.length; i++) {
            if (profiles[i].id === profileId) return profiles[i]
        }
        return null
    }

    // ─── Load config from BeeConfig (stub for now) ───────
    function loadFromConfig(cfg) {
        if (cfg && cfg.profiles) {
            profiles = cfg.profiles
        }
        if (cfg && cfg.activeProfile) {
            activeProfileId = cfg.activeProfile
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
