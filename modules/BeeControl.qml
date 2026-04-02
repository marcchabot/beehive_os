import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════════
// BeeControl.qml — "The Hive" Control Center 🐝🍯
// Consolidation v2.0 : Settings + Studio + History
// Navigation latérale intuitive, design Glassmorphism
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: controlRoot
    width:  820
    height: 620
    radius: 28
    visible: false
    anchors.centerIn: parent

    onVisibleChanged: {
        if (visible) {
            // Pas de son ici, il est déjà géré par les triggers IPC ou boutons
        }
    }

    // ─── State ──────────────────────────────────────────────
    property int currentTab: 0   // 0=MyHive 1=Design 2=Stats 3=System 4=Logs
    property var _s: BeeConfig.tr.settings || {}

    // ─── Styles ─────────────────────────────────────────────
    color: BeeTheme.mode === "HoneyDark"
        ? Qt.rgba(0.06, 0.05, 0.08, 0.94)
        : Qt.rgba(0.96, 0.94, 0.90, 0.96)
    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
    border.width: 1

    Behavior on color        { ColorAnimation { duration: 600 } }
    Behavior on border.color { ColorAnimation { duration: 600 } }

    // Drop shadow
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0,0,0, BeeTheme.mode === "HoneyDark" ? 0.45 : 0.12)
        shadowBlur: 1.0
        shadowVerticalOffset: 6
    }

    // ─── Reusable Components ───────────────────────────────
    
    // Une ligne de réglage standard (Texte + Switch)
    component SettingRow: RowLayout {
        property string label: ""
        property string desc:  ""
        property bool checked: false
        signal toggled(bool val)
        spacing: 20
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text {
                text: label; color: BeeTheme.textPrimary
                font { bold: true; pixelSize: 14 }
                Behavior on color { ColorAnimation { duration: 600 } }
            }
            Text { text: desc; color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4); font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        Switch { checked: parent.checked; onCheckedChanged: parent.toggled(checked) }
    }

    // Un en-tête de section
    component SectionHeader: ColumnLayout {
        property string title: ""
        spacing: 10
        Item { width: 1; height: 10 }
        Text { text: title; color: BeeTheme.accent; font { bold: true; pixelSize: 13; letterSpacing: 1.2 } }
        Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }
    }

    // ─── Close button ───────────────────────────────────────
    Rectangle {
        anchors { top: parent.top; right: parent.right; margins: 16 }
        width: 32; height: 32; radius: 16; z: 100
        color: closeHov.containsMouse ? Qt.rgba(1.0, 0.3, 0.3, 0.2) : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
        border.color: closeHov.containsMouse ? Qt.rgba(1.0, 0.3, 0.3, 0.6) : BeeTheme.accent
        border.width: 1
        Text { text: "✕"; anchors.centerIn: parent; color: closeHov.containsMouse ? "#ff5555" : BeeTheme.accent; font { bold: true; pixelSize: 14 } }
        MouseArea { id: closeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { controlRoot.visible = false } }
    }

    // ─── Sidebar + Content ──────────────────────────────────
    RowLayout {
        anchors.fill: parent; spacing: 0

        // ─── Sidebar (Navigation) ───
        Rectangle {
            Layout.fillHeight: true
            width: 85
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
            
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: BeeTheme.separator }

            Column {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 35 }
                spacing: 22
                Text { text: "🐝"; font.pixelSize: 28; anchors.horizontalCenter: parent.horizontalCenter; bottomPadding: 15 }

                Repeater {
                    model: [
                        { icon: "🍯", label: "Hive",    idx: 0 },
                        { icon: "🎨", label: "Design",  idx: 1 },
                        { icon: "📊", label: "Stats",   idx: 2 },
                        { icon: "⚙️", label: "System",  idx: 3 },
                        { icon: "📜", label: "Logs",    idx: 4 }
                    ]
                    
                    Item {
                        width: 55; height: 55; anchors.horizontalCenter: parent.horizontalCenter
                        Rectangle {
                            anchors.fill: parent; radius: 15
                            color: controlRoot.currentTab === modelData.idx ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2) : "transparent"
                            border.color: controlRoot.currentTab === modelData.idx ? BeeTheme.accent : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text { text: modelData.icon; anchors.centerIn: parent; font.pixelSize: 22; opacity: controlRoot.currentTab === modelData.idx ? 1.0 : 0.6 }
                        MouseArea { 
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (controlRoot.currentTab !== modelData.idx) {
                                    controlRoot.currentTab = modelData.idx 
                                    BeeSound.playEvent("ui.cell.click", {})
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── Main Content (Tabs) ───
        StackLayout {
            id: contentStack
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: controlRoot.currentTab

            // Tab 0 : My Hive (Dashboard Cells Editor — BeeStudio embedded)
            Item {
                BeeStudio {
                    anchors.fill: parent
                    embedded: true
                    activeCategory: 0
                    visible: controlRoot.currentTab === 0
                }
            }

            // Tab 1 : Design (Theme + Wallpapers)
            Item {
                ColumnLayout {
                    anchors.fill: parent; spacing: 0

                    // ─── Theme controls (compact bar on top) ───
                    Rectangle {
                        Layout.fillWidth: true; height: 70
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                        border.color: BeeTheme.separator; border.width: 1

                        RowLayout {
                            anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                            spacing: 30

                            // Theme toggle
                            RowLayout {
                                spacing: 10
                                Text { text: "🎨"; font.pixelSize: 18 }
                                Text { text: "HoneyDark / HoneyLight"; color: BeeTheme.textPrimary; font.pixelSize: 13 }
                                Switch {
                                    checked: BeeTheme.mode === "HoneyLight"
                                    onCheckedChanged: {
                                        let mode = checked ? "HoneyLight" : "HoneyDark"
                                        BeeTheme.setMode(mode)
                                        BeeConfig.saveConfig()
                                        BeeBarState.logAction("Design", "Mode " + mode + " activé", checked ? "☀️" : "🌙")
                                    }
                                }
                            }

                            // Nectar Sync toggle
                            RowLayout {
                                spacing: 10
                                Text { text: "🍯"; font.pixelSize: 18 }
                                Text { text: "Nectar Sync"; color: BeeTheme.textPrimary; font.pixelSize: 13 }
                                Switch {
                                    checked: BeeTheme.nectarSync
                                    onCheckedChanged: {
                                        BeeTheme.nectarSync = checked
                                        BeeConfig.saveConfig()
                                        BeeBarState.logAction("Design", "Nectar Sync " + (checked ? "activé" : "désactivé"), "🍯")
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }

                    // ─── Wallpaper browser (BeeStudio cat 1) ───
                    Item {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        BeeStudio {
                            anchors.fill: parent
                            embedded: true
                            activeCategory: 1   // Wallpapers tab
                            visible: controlRoot.currentTab === 1
                        }
                    }
                }
            }

            // Tab 2 : BeeBar (Stats Monitoring)
            Item {
                ColumnLayout {
                    anchors { fill: parent; margins: 35 }
                    spacing: 25

                    Text { text: "📊 BeeBar Stats"; color: BeeTheme.accent; font { bold: true; pixelSize: 22 } }
                    SectionHeader { title: "INDICATORS VISIBILITY" }

                    Flow {
                        Layout.fillWidth: true; spacing: 12
                        Repeater {
                            model: [
                                { label: BeeConfig.tr.bar.tooltip_cpu || "CPU", prop: "showCpu", icon: "📟" },
                                { label: BeeConfig.tr.bar.tooltip_ram || "RAM", prop: "showRam", icon: "🧠" },
                                { label: BeeConfig.tr.bar.tooltip_net || "NET", prop: "showNet", icon: "🌐" },
                                { label: BeeConfig.tr.bar.tooltip_disk || "DISK", prop: "showDisk", icon: "💾" },
                                { label: BeeConfig.tr.bar.tooltip_battery || "BAT", prop: "showBattery", icon: "🔋" }
                            ]
                            Rectangle {
                                width: 75; height: 45; radius: 12
                                color: BeeConfig[modelData.prop] ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2) : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                                border.color: BeeConfig[modelData.prop] ? BeeTheme.accent : BeeTheme.separator
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text { text: modelData.icon; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 14 }
                                    Text { text: modelData.label; anchors.horizontalCenter: parent.horizontalCenter; color: BeeConfig[modelData.prop] ? BeeTheme.accent : BeeTheme.textSecondary; font { pixelSize: 10; bold: BeeConfig[modelData.prop] } }
                                }

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        BeeConfig[modelData.prop] = !BeeConfig[modelData.prop]
                                        BeeConfig.saveConfig()
                                        BeeBarState.logAction("BeeBar", "Indicateur " + modelData.label + (BeeConfig[modelData.prop] ? " affiché" : " masqué"), modelData.icon)
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // Tab 3 : System (General)
            Item {
                ScrollView {
                    anchors.fill: parent; contentWidth: -1; clip: true
                ColumnLayout {
                    anchors { left: parent.left; right: parent.right; margins: 35 }
                    spacing: 25

                    Item { height: 5 }
                    Text { text: "⚙️ System & Preferences"; color: BeeTheme.accent; font { bold: true; pixelSize: 22 } }
                    
                    SectionHeader { title: "LANGUAGE" }
                    RowLayout {
                        spacing: 12
                        Repeater {
                            model: [ { code: "fr", label: "🇫🇷 Français" }, { code: "en", label: "🇬🇧 English" } ]
                            Rectangle {
                                property bool isActive: BeeConfig.uiLang === modelData.code
                                width: 120; height: 40; radius: 10
                                color: isActive ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2) : "transparent"
                                border.color: isActive ? BeeTheme.accent : BeeTheme.separator
                                border.width: 1
                                Text { anchors.centerIn: parent; text: modelData.label; color: isActive ? BeeTheme.accent : BeeTheme.textPrimary; font { bold: isActive; pixelSize: 13 } }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { BeeConfig.setLang(modelData.code); BeeConfig.saveConfig(); BeeBarState.logAction("System", "Langue changée : " + modelData.label, "🌍") } }
                            }
                        }
                    }

                    SectionHeader { title: (BeeConfig.uiLang === "fr" ? "CALENDRIERS 📅" : "CALENDARS 📅") }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 15

                        SettingRow {
                            label: (BeeConfig.uiLang === "fr" ? "Widget Événements" : "Upcoming Events Widget")
                            desc: (BeeConfig.uiLang === "fr" ? "Afficher le panneau des rendez-vous sur le bureau." : "Show upcoming events panel on the desktop (bottom-left).")
                            checked: BeeConfig.eventsEnabled
                            onToggled: (val) => { BeeConfig.eventsEnabled = val; BeeConfig.saveConfig(); BeeBarState.logAction("Calendar", "Widget événements " + (val ? "activé" : "désactivé"), "📅") }
                        }

                        // V2 Multi-Calendar Management
                        Repeater {
                            model: BeeConfig.calendars
                            delegate: ColumnLayout {
                                Layout.fillWidth: true; spacing: 8
                                
                                RowLayout {
                                    spacing: 10
                                    Rectangle {
                                        width: 12; height: 12; radius: 6
                                        color: (model.color && model.color !== "") ? model.color : BeeTheme.accent
                                    }
                                    Text {
                                        text: (model.label && model.label !== "") ? model.label : "Calendar"
                                        color: BeeTheme.textPrimary; font { bold: true; pixelSize: 13 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    
                                    // Remove button
                                    Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: delHov.containsMouse ? "#442222" : "transparent"
                                        border.color: delHov.containsMouse ? "#ff5555" : "transparent"
                                        border.width: 1
                                        Text { text: "🗑️"; anchors.centerIn: parent; font.pixelSize: 14; opacity: delHov.containsMouse ? 1.0 : 0.6 }
                                        MouseArea {
                                            id: delHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                BeeConfig.calendars.remove(index)
                                                BeeConfig.saveConfig()
                                                BeeBarState.logAction("Calendar", "Calendrier supprimé", "🗑️")
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 10
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 10
                                        color: Qt.rgba(0, 0, 0, 0.2)
                                        border.color: icsIn.activeFocus ? BeeTheme.accent : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                                        border.width: 1
                                        
                                        TextInput {
                                            id: icsIn
                                            anchors { fill: parent; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                            text: model.url; color: BeeTheme.textPrimary; font.pixelSize: 11; clip: true
                                            onEditingFinished: {
                                                if (text !== model.url) {
                                                    BeeConfig.calendars.setProperty(index, "url", text)
                                                    BeeConfig.saveConfig()
                                                }
                                            }
                                        }
                                        Text {
                                            visible: !icsIn.text && !icsIn.activeFocus
                                            text: "URL du calendrier (.ics)"
                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                                            font.pixelSize: 11
                                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                        }
                                    }
                                }
                                Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator; opacity: 0.3 }
                            }
                        }

                        // Add Calendar Button (Stylisé)
                        Rectangle {
                            width: 180; height: 36; radius: 10
                            color: addHov.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2) : "transparent"
                            border.color: BeeTheme.accent; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: (BeeConfig.uiLang === "fr" ? "+ Ajouter un calendrier" : "+ Add Calendar")
                                color: BeeTheme.accent; font { bold: true; pixelSize: 12 }
                            }
                            MouseArea {
                                id: addHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BeeConfig.calendars.append({
                                        id: "cal_" + Date.now(),
                                        label: (BeeConfig.uiLang === "fr" ? "Nouveau Calendrier" : "New Calendar"),
                                        url: "",
                                        color: "#FFB81C",
                                        type: "ics"
                                    })
                                    BeeConfig.saveConfig()
                                }
                            }
                        }

                        // Global Sync Now (Stylisé)
                        Rectangle {
                            Layout.fillWidth: true; height: 42; radius: 12
                            color: BeeTheme.accent; opacity: syncHov.containsMouse ? 0.9 : 1.0
                            Text {
                                anchors.centerIn: parent
                                text: (BeeConfig.uiLang === "fr" ? "⟳ Synchroniser tout" : "⟳ Sync All")
                                color: "#000000"; font { bold: true; pixelSize: 13 }
                            }
                            MouseArea {
                                id: syncHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BeeConfig.reloadLiveEvents()
                                    BeeBarState.logAction("Calendar", "Synchronisation globale lancée", "📅")
                                }
                            }
                        }
                    }

                    SectionHeader { title: "PRIVACY & FOCUS" }
                    SettingRow {
                        label: controlRoot._s.stealth || "Stealth Mode 👤"
                        desc: "Hide BeeBar until mouse enters the top sensor area."
                        checked: BeeConfig.stealthMode
                        onToggled: (val) => { BeeConfig.stealthMode = val; BeeConfig.saveConfig(); BeeBarState.logAction("System", "Mode Furtif " + (val ? "activé" : "désactivé"), "👤") }
                    }
                    SettingRow {
                        label: controlRoot._s.focus || "Focus Mode 🎯"
                        desc: "Hide Dashboard and background elements for maximum focus."
                        checked: BeeConfig.focusMode
                        onToggled: (val) => { BeeConfig.focusMode = val; BeeConfig.saveConfig(); BeeBarState.logAction("System", "Mode Focus " + (val ? "activé" : "désactivé"), "🎯") }
                    }

                    Item { height: 20 }
                }
                } // ScrollView
            }

            // Tab 4 : History (📜 Logs)
            Item {
                ColumnLayout {
                    anchors { fill: parent; margins: 35 }
                    RowLayout {
                        spacing: 12
                        Text { text: "📜 Hive Activity Log"; color: BeeTheme.accent; font { bold: true; pixelSize: 22 } }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "Clear All"; flat: true
                            onClicked: BeeBarState.clearHistory()
                        }
                    }
                    Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }
                    
                    ListView {
                        id: historyList; Layout.fillWidth: true; Layout.fillHeight: true
                        model: BeeBarState.historyModel; spacing: 12; clip: true
                        delegate: Rectangle {
                            width: historyList.width; height: 62; radius: 15
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.04)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                            border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 15
                                Text { text: modelData.icon; font.pixelSize: 22 }
                                ColumnLayout {
                                    spacing: 2; Layout.fillWidth: true
                                    Text { text: modelData.category; color: BeeTheme.accent; font { bold: true; pixelSize: 13 } }
                                    Text { text: modelData.message; color: BeeTheme.textPrimary; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Text { text: modelData.timestamp; color: BeeTheme.textSecondary; font.pixelSize: 11; opacity: 0.7 }
                            }
                        }
                        Text { visible: historyList.count === 0; text: "No activity recorded yet... 🐝💤"; anchors.centerIn: parent; color: BeeTheme.textSecondary; font.italic: true }
                    }
                }
            }
        }
    }
}
