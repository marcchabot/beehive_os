pragma Singleton
import QtQuick
import Quickshell

// ═══════════════════════════════════════════════════════════
// BeeBarState.qml — Shared Stealth Mode state
// Singleton accessible from shell.qml AND BeeBar.qml
// ═══════════════════════════════════════════════════════════
QtObject {
    id: root

    // true  = sentinel detected mouse → force display
    // false = normal state (handled by BeeBar)
    property bool forceVisible: false

    // Inter-window signals to open Settings/Studio from BeeSearch
    property bool openSettingsRequested: false
    property bool openStudioRequested:   false

    // Synchronized states between BeeSettings (Layer Top) and widgets (Background)
    property bool cornersActive: true
    property bool motionActive:  true
    property bool vibeActive:    false

    // Mode Focus 🎯 (masque Dashboard, Events, Horloge)
    property bool focusActive: false

    // BeePower menu visibility
    property bool powerVisible: false

    // ─── BeeAura Notification System 🔔 ───────────────────────
    signal notificationReceived(string title, string body, string icon)

    // ─── Notification History (max 50) ────────────────────────
    // Note: ListModel cannot be a direct child of a QtObject (Singleton).
    // We use a JS array (property var) — compatible with ListView model.
    property var notificationHistory: []
    readonly property int maxHistorySize: 50

    function dispatchNotification(title, body, icon) {
        notificationReceived(title, body, icon)
        var entry = {
            "title":     title,
            "body":      body,
            "icon":      icon,
            "timestamp": new Date().toLocaleTimeString(Qt.locale("fr_CA"), "HH:mm")
        }
        var updated = [entry].concat(notificationHistory)
        if (updated.length > maxHistorySize)
            updated = updated.slice(0, maxHistorySize)
        notificationHistory = updated
    }

    function clearNotificationHistory() {
        notificationHistory = []
    }

    function removeNotification(index) {
        var updated = notificationHistory.slice()
        updated.splice(index, 1)
        notificationHistory = updated
    }

    // ─── BeeAura OSD System 🎚️ ────────────────────────────────
    // type: "volume" | "mute" | "brightness" | "kbd"
    // value: 0-100 (ignored if type === "mute")
    signal osdReceived(string type, int value)
    function showOSD(type, value) {
        osdReceived(type, parseInt(value))
    }
}
