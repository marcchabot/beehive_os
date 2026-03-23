pragma Singleton
import QtQuick
import Quickshell

// ═══════════════════════════════════════════════════════════
// BeeBarState.qml — État partagé du Stealth Mode
// Singleton accessible depuis shell.qml ET BeeBar.qml
// ═══════════════════════════════════════════════════════════
QtObject {
    id: root

    // true  = la sentinelle a détecté la souris → forcer l'affichage
    // false = état normal (géré par BeeBar)
    property bool forceVisible: false

    // Signaux inter-fenêtres pour ouvrir Settings/Studio depuis BeeSearch
    property bool openSettingsRequested: false
    property bool openStudioRequested:   false

    // États synchronisés entre BeeSettings (Layer Top) et widgets (Background)
    property bool cornersActive: true
    property bool motionActive:  true
    property bool vibeActive:    false

    // Mode Focus 🎯 (masque Dashboard, Events, Horloge)
    property bool focusActive: false

    // Visibilité du menu d'alimentation BeePower
    property bool powerVisible: false

    // ─── Système de Notifications BeeAura 🔔 ─────────────────
    signal notificationReceived(string title, string body, string icon)

    // ─── Historique des Notifications (max 50) ────────────────
    // Note: ListModel ne peut pas être enfant direct d'un QtObject (Singleton).
    // On utilise un tableau JS (property var) — compatible avec ListView model.
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

    // ─── Système OSD BeeAura 🎚️ ──────────────────────────────
    // type : "volume" | "mute" | "brightness" | "kbd"
    // value : 0-100 (ignoré si type === "mute")
    signal osdReceived(string type, int value)
    function showOSD(type, value) {
        osdReceived(type, parseInt(value))
    }
}
