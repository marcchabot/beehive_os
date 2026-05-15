import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
// BeeReminder.qml — Calendar Push Notification Popup 🐝⏰
// v0.8.27 — Slide-in reminder with snooze/dismiss actions
// Supports multiple concurrent reminders, auto-dismiss, persistence
// ═══════════════════════════════════════════════════════════════

Item {
    id: reminderRoot
    anchors.fill: parent

    // ─── Data model for active reminders ─────────────────────
    ListModel {
        id: activeReminders
    }

    // ─── Show a reminder popup ────────────────────────────────
    // Call with: { id, title, time, calendarLabel, calendarColor, icon, timestamp }
    function showReminder(evt) {
        if (!evt || !evt.id) return

        // Avoid duplicates
        for (var i = 0; i < activeReminders.count; i++) {
            if (activeReminders.get(i).evtId === evt.id) return
        }

        activeReminders.append({
            "evtId":          evt.id || "",
            "evtTitle":       evt.title || (BeeConfig.uiLang === "fr" ? "Rappel" : "Reminder"),
            "evtTime":        evt.time || "",
            "evtCalendarLabel": evt.calendarLabel || evt.sub || "",
            "evtCalendarColor": evt.calendarColor || "#FFB81C",
            "evtIcon":        evt.icon || "📅",
            "evtTimestamp":    evt.timestamp || 0,
            "isSnoozed":      evt.isSnoozed || false
        })

        // Play reminder sound
        BeeSound.playEvent(BeeConfig.beeCalendarReminderSound || "notify.info", {})

        // Also push to BeeNotify for history
        var title = evt.isSnoozed
            ? (BeeConfig.uiLang === "fr" ? "📅 Rappel (snooze)" : "📅 Reminder (snooze)")
            : (BeeConfig.uiLang === "fr" ? "📅 Rappel" : "📅 Reminder")
        BeeBarState.dispatchNotification(title, evt.title + " — " + (evt.time || ""), evt.icon || "📅")
    }

    // ─── Dismiss a reminder ───────────────────────────────────
    function dismissReminder(evtId) {
        for (var i = 0; i < activeReminders.count; i++) {
            if (activeReminders.get(i).evtId === evtId) {
                activeReminders.remove(i)
                return
            }
        }
    }

    // ─── Signal emitted when a reminder is snoozed ──────────
    signal reminderSnoozed(var evtData, int minutes)

    // ─── Snooze a reminder ───────────────────────────────────
    function snoozeReminder(evtId, minutes) {
        // Find the reminder data before removing
        var found = false
        var evtData = null
        for (var i = 0; i < activeReminders.count; i++) {
            if (activeReminders.get(i).evtId === evtId) {
                evtData = {
                    id:          activeReminders.get(i).evtId,
                    title:       activeReminders.get(i).evtTitle,
                    time:        activeReminders.get(i).evtTime,
                    sub:         activeReminders.get(i).evtCalendarLabel,
                    timestamp:   activeReminders.get(i).evtTimestamp,
                    icon:        activeReminders.get(i).evtIcon
                }
                activeReminders.remove(i)
                found = true
                break
            }
        }
        if (!found || !evtData) return

        // 🐝 v0.8.27 — Delegate to BeeHiveShell global snooze handler
        // BeeHiveShell manages snooze persistence across restarts
        // Set lastTriggeredEvent so the snooze handler can pick it up
        var shell = Qt.resolveType("BeeHiveShell") ? null : null  // Not resolvable directly
        // Use the global context approach: BeeHiveShell is our parent shell
        // We walk up the parent tree to find the ShellRoot
        var p = reminderRoot.parent
        var shellRef = null
        while (p) {
            if (p.objectName === "beehiveShell" || p.snoozeReminder) {
                shellRef = p
                break
            }
            p = p.parent
        }
        // Alternative: use the id-based approach (BeeHiveShell is the root context)
        // Quickshell scope: the shell's root object is accessible
        if (shellRef && shellRef.snoozeReminder) {
            shellRef._lastTriggeredEvent = evtData
            shellRef.snoozeReminder(evtId, minutes)
        } else {
            // Fallback: use Process to write snooze state directly
            var nowTs = Math.floor(new Date().getTime() / 1000)
            var snoozeTs = nowTs + (minutes * 60)
            var sr = {
                evtId: evtData.id,
                evtTitle: evtData.title,
                evtTime: evtData.time,
                evtIcon: evtData.icon,
                evtSub: evtData.sub,
                evtTimestamp: evtData.timestamp,
                snoozeTriggerTs: snoozeTs
            }
            // Push to BeeHiveShell's snoozed reminders
            // We'll use a signal to communicate
            reminderSnoozed(evtData, minutes)
        }
    }

    // ─── Reminder popups (stacked top-right) ─────────────────
    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: 16
        spacing: 10
        z: 300

        Repeater {
            model: activeReminders

            Rectangle {
                id: reminderPopup
                width: 310
                height: reminderContent.height + 24
                radius: 14
                clip: true

                // Glass morphism style
                color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.95)
                border.color: model.evtCalendarColor || BeeTheme.accent
                border.width: 2

                // Drop shadow
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, BeeTheme.mode === "HoneyDark" ? 0.5 : 0.15)
                    shadowBlur: 0.6
                    shadowVerticalOffset: 4
                    shadowHorizontalOffset: 0
                }

                // ─── Slide-in animation ──────────────────────
                SequentialAnimation {
                    id: slideInAnim
                    NumberAnimation {
                        target: reminderPopup
                        property: "x"
                        from: 350
                        to: 0
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: reminderPopup
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 200
                    }
                }
                Component.onCompleted: slideInAnim.start()

                // ─── Content ─────────────────────────────────
                Column {
                    id: reminderContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 8

                    // Header row: icon + title + close button
                    Row {
                        spacing: 8
                        width: parent.width

                        // Calendar color dot
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: model.evtCalendarColor || BeeTheme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: model.evtTitle
                            font.pixelSize: 14
                            font.bold: true
                            color: BeeTheme.textPrimary
                            elide: Text.ElideRight
                            width: parent.width - 70
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Snoozed badge
                        Rectangle {
                            visible: model.isSnoozed
                            width: 52; height: 18; radius: 4
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: BeeConfig.uiLang === "fr" ? "Snooze" : "Snooze"
                                font.pixelSize: 8
                                font.bold: true
                                color: BeeTheme.accent
                            }
                        }

                        // Close (dismiss) button — BeeHive style
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            color: dismissHov.containsMouse
                                ? Qt.rgba(1.0, 0.3, 0.3, 0.2)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                            border.color: dismissHov.containsMouse
                                ? Qt.rgba(1.0, 0.3, 0.3, 0.5)
                                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                text: "✕"; anchors.centerIn: parent
                                color: dismissHov.containsMouse ? "#ff5555" : BeeTheme.accent
                                font.pixelSize: 10; font.bold: true
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                id: dismissHov; anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: reminderRoot.dismissReminder(model.evtId)
                            }
                        }
                    }

                    // Time row
                    Row {
                        spacing: 6
                        Text {
                            text: "🕐"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: model.evtTime
                            font.pixelSize: 12
                            color: BeeTheme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            visible: model.evtCalendarLabel !== ""
                            text: "— " + model.evtCalendarLabel
                            font.pixelSize: 11
                            color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.7)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Action buttons row
                    Row {
                        spacing: 6
                        width: parent.width

                        // Snooze buttons (5, 10, 15 min)
                        Repeater {
                            model: [
                                { label: BeeConfig.uiLang === "fr" ? "5 min" : "5 min", value: 5 },
                                { label: BeeConfig.uiLang === "fr" ? "10 min" : "10 min", value: 10 },
                                { label: BeeConfig.uiLang === "fr" ? "15 min" : "15 min", value: 15 }
                            ]
                            Rectangle {
                                width: 62; height: 26; radius: 6
                                color: snoozeBtnHov.containsMouse
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                                    : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "💤 " + modelData.label
                                    font.pixelSize: 9; font.bold: true
                                    color: BeeTheme.accent
                                }
                                MouseArea {
                                    id: snoozeBtnHov; anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: reminderRoot.snoozeReminder(reminderPopup.model.evtId, modelData.value)
                                }
                            }
                        }

                        // Spacer
                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        // Dismiss button
                        Rectangle {
                            width: 80; height: 26; radius: 6
                            color: dismissBtnHov.containsMouse
                                ? Qt.rgba(1.0, 0.3, 0.3, 0.15)
                                : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                            border.color: dismissBtnHov.containsMouse
                                ? Qt.rgba(1.0, 0.3, 0.3, 0.4)
                                : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b, 0.3)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: BeeConfig.uiLang === "fr" ? "✕ Fermer" : "✕ Dismiss"
                                font.pixelSize: 9; font.bold: true
                                color: dismissBtnHov.containsMouse ? "#ff5555" : BeeTheme.textSecondary
                            }
                            MouseArea {
                                id: dismissBtnHov; anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: reminderRoot.dismissReminder(reminderPopup.model.evtId)
                            }
                        }
                    }
                }

                // ─── Auto-dismiss progress bar ─────────────
                Item {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 3

                    Rectangle {
                        id: reminderProgress
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width
                        radius: 2
                        color: model.evtCalendarColor || BeeTheme.accent

                        PropertyAnimation on width {
                            from: reminderProgress.parent.width; to: 0
                            duration: 30000  // 30 seconds auto-dismiss
                            onFinished: reminderRoot.dismissReminder(reminderPopup.model.evtId)
                        }
                    }
                }
            }
        }
    }
}