import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io
import "."

// ═══════════════════════════════════════════════════════════════
// BeeWelcome.qml — Setup Wizard 🐝🧙 v2.0
// Multi-step first-run configuration
// Steps: Welcome → Theme → Language → MayaDash Cells → Done
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: welcomeRoot
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.75)

    signal dismissed()

    // ─── Wizard State ───────────────────────────────────────
    property int currentStep: 0
    property int totalSteps: 5
    property string selectedTheme: BeeTheme.mode   // "HoneyDark" | "HoneyLight" | "Auto"
    property string selectedLang: BeeConfig.uiLang || "fr"
    property var selectedCells: []   // list of cell keys chosen by user

    // ─── i18n ──────────────────────────────────────────────
    function tr(key) {
        var isFr = selectedLang === "fr"
        var map = {
            // Step 0 — Welcome
            "welcome_title":         isFr ? "Bienvenue dans Bee-Hive OS" : "Welcome to Bee-Hive OS",
            "welcome_tagline":       isFr ? "Votre ruche, votre style" : "Your hive, your style",
            "welcome_desc":          isFr
                ? "Configurons ensemble votre environnement.\nQuelques étapes rapides et vous serez prêt !"
                : "Let's set up your environment together.\nA few quick steps and you'll be ready!",

            // Step 1 — Theme
            "theme_title":           isFr ? "Choisissez votre thème" : "Choose your theme",
            "theme_desc":            isFr
                ? "Sélectionnez l'apparence de votre ruche.\nVous pourrez changer à tout moment."
                : "Select the look of your hive.\nYou can change it anytime.",
            "theme_dark":            "HoneyDark",
            "theme_light":           "HoneyLight",
            "theme_auto":            isFr ? "Auto" : "Auto",
            "theme_dark_desc":       isFr ? "Mode sombre élégant" : "Elegant dark mode",
            "theme_light_desc":      isFr ? "Mode clair chaleureux" : "Warm light mode",
            "theme_auto_desc":       isFr ? "S'adapte à l'heure du jour" : "Adapts to time of day",

            // Step 2 — Language
            "lang_title":            isFr ? "Choisissez votre langue" : "Choose your language",
            "lang_desc":             isFr
                ? "Sélectionnez la langue de l'interface.\nDisponible en français et anglais."
                : "Select the interface language.\nAvailable in French and English.",

            // Step 3 — MayaDash
            "dash_title":            isFr ? "Configurez votre MayaDash" : "Configure your MayaDash",
            "dash_desc":             isFr
                ? "Choisissez les alvéoles initiales de votre tableau de bord."
                : "Choose the initial cells for your dashboard.",
            "dash_select_all":       isFr ? "Tout sélectionner" : "Select all",
            "dash_deselect_all":     isFr ? "Tout désélectionner" : "Deselect all",

            // Step 4 — Done
            "done_title":            isFr ? "Tout est prêt !" : "All set!",
            "done_desc":             isFr
                ? "Votre ruche est configurée. Bonne exploration ! 🍯"
                : "Your hive is configured. Enjoy exploring! 🍯",
            "done_summary_theme":    isFr ? "Thème" : "Theme",
            "done_summary_lang":     isFr ? "Langue" : "Language",
            "done_summary_cells":    isFr ? "Alvéoles" : "Cells",

            // Navigation
            "btn_back":              isFr ? "Précédent" : "Back",
            "btn_next":              isFr ? "Suivant" : "Next",
            "btn_start":             isFr ? "🐝 Démarrer" : "🐝 Start",

            // Default cells
            "cell_calendar":         isFr ? "Calendrier" : "Calendar",
            "cell_email":            isFr ? "Email" : "Email",
            "cell_weather":          isFr ? "Météo" : "Weather",
            "cell_system":           isFr ? "Système" : "System",
            "cell_network":          isFr ? "Réseau" : "Network",
            "cell_beehive":          "Bee-Hive OS"
        }
        return map[key] || key
    }

    // ─── Default cell options ───────────────────────────────
    property var defaultCellOptions: [
        { key: "calendar", icon: "📅", color: "#4A90D9" },
        { key: "email",    icon: "📧", color: "#9B59B6" },
        { key: "weather",  icon: "🌤️", color: "#2ECC71" },
        { key: "system",   icon: "🖥️", color: "#E74C3C" },
        { key: "network",  icon: "🌐", color: "#3498DB" },
        { key: "beehive",  icon: "🐝", color: "#FFB81C" }
    ]

    // ─── Card ──────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 600; height: 520
        radius: 28
        color: BeeTheme.mode === "HoneyDark"
            ? Qt.rgba(0.06, 0.05, 0.08, 0.97)
            : Qt.rgba(0.97, 0.95, 0.91, 0.97)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0,0,0,0.5)
            shadowBlur: 1.0
            shadowVerticalOffset: 8
        }

        // Appear animation
        scale: 0.88; opacity: 0
        Component.onCompleted: appearAnim.start()
        ParallelAnimation {
            id: appearAnim
            NumberAnimation { target: card; property: "scale";   to: 1.0; duration: 450; easing.type: Easing.OutBack }
            NumberAnimation { target: card; property: "opacity"; to: 1.0; duration: 350; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 36 }
            spacing: 0

            // ─── Step Indicators ──────────────────────────
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Repeater {
                    model: welcomeRoot.totalSteps
                    Rectangle {
                        width: 32; height: 4; radius: 2
                        color: index <= welcomeRoot.currentStep
                            ? BeeTheme.accent
                            : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            Item { height: 18 }

            // ─── Step Content (slides) ────────────────────
            StackLayout {
                id: stepStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: welcomeRoot.currentStep

                // ─── Step 0: Welcome ─────────────────────
                Item {
                    ColumnLayout {
                        anchors { fill: parent; }
                        spacing: 0

                        Text {
                            text: "🐝"; font.pixelSize: 64
                            Layout.alignment: Qt.AlignHCenter
                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.12; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
                            }
                        }
                        Item { height: 12 }
                        Text {
                            text: tr("welcome_title")
                            color: BeeTheme.accent
                            font.bold: true; font.pixelSize: 28; font.letterSpacing: 0.5
                            Layout.alignment: Qt.AlignHCenter
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                        Item { height: 8 }
                        Text {
                            text: tr("welcome_tagline")
                            color: BeeTheme.textSecondary
                            font.italic: true; font.pixelSize: 16
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 20 }
                        Text {
                            text: tr("welcome_desc")
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.7)
                            font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // ─── Step 1: Theme Selection ─────────────
                Item {
                    ColumnLayout {
                        anchors { fill: parent; }
                        spacing: 0

                        Text {
                            text: "🎨"; font.pixelSize: 36
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 8 }
                        Text {
                            text: tr("theme_title")
                            color: BeeTheme.accent
                            font.bold: true; font.pixelSize: 22
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 4 }
                        Text {
                            text: tr("theme_desc")
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.6)
                            font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        Item { height: 16 }

                        // Theme cards
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Repeater {
                                model: [
                                    { key: "HoneyDark",  icon: "🌙", label: tr("theme_dark"),  desc: tr("theme_dark_desc"),  previewBg: "#0D0D0D", previewFg: "#FFFFFF" },
                                    { key: "HoneyLight", icon: "☀️", label: tr("theme_light"), desc: tr("theme_light_desc"), previewBg: "#F5F0E8", previewFg: "#2A1F0A" },
                                    { key: "Auto",        icon: "🔄", label: tr("theme_auto"),  desc: tr("theme_auto_desc"),  previewBg: "#333333", previewFg: "#CCCCCC" }
                                ]

                                Rectangle {
                                    Layout.preferredWidth: 160
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: 180
                                    radius: 16
                                    color: welcomeRoot.selectedTheme === modelData.key
                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                        : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.05)
                                    border.color: welcomeRoot.selectedTheme === modelData.key
                                        ? BeeTheme.accent
                                        : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                                    border.width: welcomeRoot.selectedTheme === modelData.key ? 2 : 1

                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    ColumnLayout {
                                        anchors { fill: parent; margins: 14 }
                                        spacing: 6

                                        // Preview mini-window
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 60
                                            radius: 8
                                            color: modelData.previewBg
                                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                                            border.width: 1

                                            Column {
                                                anchors { fill: parent; margins: 8 }
                                                spacing: 3
                                                Rectangle { width: 30; height: 3; radius: 1.5; color: modelData.previewFg; opacity: 0.9 }
                                                Rectangle { width: 50; height: 3; radius: 1.5; color: modelData.previewFg; opacity: 0.5 }
                                                Rectangle { width: 20; height: 3; radius: 1.5; color: BeeTheme.accent; opacity: 0.8 }
                                            }
                                        }

                                        Text {
                                            text: modelData.icon + " " + modelData.label
                                            color: welcomeRoot.selectedTheme === modelData.key ? BeeTheme.accent : BeeTheme.textPrimary
                                            font.bold: true; font.pixelSize: 14
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Text {
                                            text: modelData.desc
                                            color: BeeTheme.textSecondary
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            welcomeRoot.selectedTheme = modelData.key
                                            // Live preview: apply theme immediately
                                            if (modelData.key === "HoneyDark") BeeTheme.setMode("HoneyDark")
                                            else if (modelData.key === "HoneyLight") BeeTheme.setMode("HoneyLight")
                                            // "Auto" keeps current mode
                                        }
                                    }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // ─── Step 2: Language ─────────────────────
                Item {
                    ColumnLayout {
                        anchors { fill: parent; }
                        spacing: 0

                        Text {
                            text: "🌍"; font.pixelSize: 36
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 8 }
                        Text {
                            text: tr("lang_title")
                            color: BeeTheme.accent
                            font.bold: true; font.pixelSize: 22
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 4 }
                        Text {
                            text: tr("lang_desc")
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.6)
                            font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        Item { height: 24 }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 20

                            // French
                            Rectangle {
                                width: 180; height: 140; radius: 16
                                color: welcomeRoot.selectedLang === "fr"
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                    : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.05)
                                border.color: welcomeRoot.selectedLang === "fr"
                                    ? BeeTheme.accent
                                    : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                                border.width: welcomeRoot.selectedLang === "fr" ? 2 : 1

                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors { centerIn: parent }
                                    spacing: 8
                                    Text { text: "🇫🇷"; font.pixelSize: 48; Layout.alignment: Qt.AlignHCenter }
                                    Text {
                                        text: "Français"
                                        color: welcomeRoot.selectedLang === "fr" ? BeeTheme.accent : BeeTheme.textPrimary
                                        font.bold: true; font.pixelSize: 16
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: welcomeRoot.selectedLang = "fr"
                                }
                            }

                            // English
                            Rectangle {
                                width: 180; height: 140; radius: 16
                                color: welcomeRoot.selectedLang === "en"
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                    : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.05)
                                border.color: welcomeRoot.selectedLang === "en"
                                    ? BeeTheme.accent
                                    : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                                border.width: welcomeRoot.selectedLang === "en" ? 2 : 1

                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors { centerIn: parent }
                                    spacing: 8
                                    Text { text: "🇬🇧"; font.pixelSize: 48; Layout.alignment: Qt.AlignHCenter }
                                    Text {
                                        text: "English"
                                        color: welcomeRoot.selectedLang === "en" ? BeeTheme.accent : BeeTheme.textPrimary
                                        font.bold: true; font.pixelSize: 16
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: welcomeRoot.selectedLang = "en"
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // ─── Step 3: MayaDash Cells ──────────────
                Item {
                    ColumnLayout {
                        anchors { fill: parent; }
                        spacing: 0

                        Text {
                            text: "📱"; font.pixelSize: 36
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 6 }
                        Text {
                            text: tr("dash_title")
                            color: BeeTheme.accent
                            font.bold: true; font.pixelSize: 22
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 4 }
                        Text {
                            text: tr("dash_desc")
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.6)
                            font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        Item { height: 10 }

                        // Select all / deselect all
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 8
                            Text {
                                text: tr("dash_select_all")
                                color: BeeTheme.accent
                                font.pixelSize: 11; font.underline: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var all = []
                                        for (var i = 0; i < defaultCellOptions.length; i++)
                                            all.push(defaultCellOptions[i].key)
                                        selectedCells = all
                                    }
                                }
                            }
                            Text { text: "·"; color: BeeTheme.textSecondary; font.pixelSize: 11 }
                            Text {
                                text: tr("dash_deselect_all")
                                color: BeeTheme.accent
                                font.pixelSize: 11; font.underline: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: selectedCells = []
                                }
                            }
                        }
                        Item { height: 6 }

                        // Cell selection grid
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            rowSpacing: 10
                            columnSpacing: 10

                            Repeater {
                                model: defaultCellOptions

                                Rectangle {
                                    Layout.preferredWidth: 150
                                    height: 60; radius: 12
                                    property bool isSelected: selectedCells.indexOf(modelData.key) >= 0
                                    color: isSelected
                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                        : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.05)
                                    border.color: isSelected
                                        ? BeeTheme.accent
                                        : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.15)
                                    border.width: isSelected ? 2 : 1

                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        spacing: 8

                                        Text {
                                            text: modelData.icon
                                            font.pixelSize: 22
                                        }
                                        Text {
                                            text: tr("cell_" + modelData.key)
                                            color: isSelected ? BeeTheme.accent : BeeTheme.textPrimary
                                            font.bold: isSelected; font.pixelSize: 13
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: isSelected ? "✓" : ""
                                            color: BeeTheme.accent
                                            font.bold: true; font.pixelSize: 14
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var idx = selectedCells.indexOf(modelData.key)
                                            var arr = selectedCells.slice()
                                            if (idx >= 0) arr.splice(idx, 1)
                                            else arr.push(modelData.key)
                                            selectedCells = arr
                                        }
                                    }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // ─── Step 4: Done ─────────────────────────
                Item {
                    ColumnLayout {
                        anchors { fill: parent; }
                        spacing: 0

                        Item { height: 10 }
                        Text {
                            text: "🍯"; font.pixelSize: 64
                            Layout.alignment: Qt.AlignHCenter
                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.15; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0;  duration: 600; easing.type: Easing.InOutSine }
                            }
                        }
                        Item { height: 12 }
                        Text {
                            text: tr("done_title")
                            color: BeeTheme.accent
                            font.bold: true; font.pixelSize: 28
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { height: 6 }
                        Text {
                            text: tr("done_desc")
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.7)
                            font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        Item { height: 20 }

                        // Summary
                        Rectangle {
                            Layout.fillWidth: true; radius: 14
                            height: summaryCol.implicitHeight + 24
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                            border.width: 1

                            Column {
                                id: summaryCol
                                anchors { fill: parent; margins: 12 }
                                spacing: 8

                                // Theme
                                RowLayout {
                                    spacing: 10
                                    Text { text: "🎨"; font.pixelSize: 16 }
                                    Text {
                                        text: tr("done_summary_theme") + ":"
                                        color: BeeTheme.textSecondary; font.bold: true; font.pixelSize: 13
                                    }
                                    Text {
                                        text: selectedTheme
                                        color: BeeTheme.accent; font.pixelSize: 13
                                    }
                                }

                                // Language
                                RowLayout {
                                    spacing: 10
                                    Text { text: "🌍"; font.pixelSize: 16 }
                                    Text {
                                        text: tr("done_summary_lang") + ":"
                                        color: BeeTheme.textSecondary; font.bold: true; font.pixelSize: 13
                                    }
                                    Text {
                                        text: selectedLang === "fr" ? "Français 🇫🇷" : "English 🇬🇧"
                                        color: BeeTheme.accent; font.pixelSize: 13
                                    }
                                }

                                // Cells
                                RowLayout {
                                    spacing: 10
                                    Text { text: "📱"; font.pixelSize: 16 }
                                    Text {
                                        text: tr("done_summary_cells") + ":"
                                        color: BeeTheme.textSecondary; font.bold: true; font.pixelSize: 13
                                    }
                                    Text {
                                        text: selectedCells.length + " " + (selectedLang === "fr" ? "alvéoles" : "cells")
                                        color: BeeTheme.accent; font.pixelSize: 13
                                    }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ─── Navigation Buttons ────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12

                // Back button
                Rectangle {
                    visible: welcomeRoot.currentStep > 0
                    width: 110; height: 40; radius: 12
                    color: backHov.containsMouse
                        ? Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.15)
                        : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.05)
                    border.color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "← " + tr("btn_back")
                        color: BeeTheme.textSecondary
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: backHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (welcomeRoot.currentStep > 0) welcomeRoot.currentStep-- }
                    }
                }

                Item { Layout.fillWidth: true }

                // Next / Start button
                Rectangle {
                    Layout.fillWidth: true
                    height: 44; radius: 14
                    color: nextHov.containsMouse
                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                    border.color: BeeTheme.accent; border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: welcomeRoot.currentStep < welcomeRoot.totalSteps - 1
                            ? tr("btn_next") + " →"
                            : tr("btn_start")
                        color: BeeTheme.accent
                        font.bold: true; font.pixelSize: 15; font.letterSpacing: 0.5
                    }
                    MouseArea {
                        id: nextHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (welcomeRoot.currentStep < welcomeRoot.totalSteps - 1) {
                                welcomeRoot.currentStep++
                            } else {
                                // ─── Apply all choices & finish ───
                                // Apply theme
                                if (selectedTheme === "HoneyDark") {
                                    BeeTheme.setMode("HoneyDark")
                                } else if (selectedTheme === "HoneyLight") {
                                    BeeTheme.setMode("HoneyLight")
                                }
                                // "Auto" → enable adaptive if available
                                if (selectedTheme === "Auto") {
                                    var raw = JSON.parse(JSON.stringify(BeeConfig._rawConfig || {}))
                                    var ns = raw.nectar_sync || {}
                                    if (typeof ns !== 'object') ns = { enabled: true }
                                    if (!ns.adaptive) ns.adaptive = {}
                                    ns.adaptive.enabled = true
                                    ns.enabled = true
                                    raw.nectar_sync = ns
                                    BeeConfig._rawConfig = raw
                                    BeeConfig.adaptiveEnabled = true
                                }

                                // Apply language
                                BeeConfig.setLang(selectedLang)

                                // Apply cells — build default cells from selection
                                var cellDefs = {
                                    "calendar": { icon: "📅", title: tr("cell_calendar"), subtitle: selectedLang === "fr" ? "Planning" : "Schedule", detail: selectedLang === "fr" ? "3 événements" : "3 events", action: "detail:calendar", highlighted: false },
                                    "email":    { icon: "📧", title: tr("cell_email"),    subtitle: selectedLang === "fr" ? "Boîte" : "Inbox", detail: selectedLang === "fr" ? "5 non lus" : "5 unread", action: "app:thunderbird", highlighted: false },
                                    "weather":  { icon: "🌤️", title: tr("cell_weather"), subtitle: selectedLang === "fr" ? "Prévisions" : "Forecast", detail: "22°C", action: "none", highlighted: false },
                                    "system":   { icon: "🖥️", title: tr("cell_system"),  subtitle: "CachyOS", detail: "CPU/GPU/RAM", action: "detail:monitor", highlighted: false },
                                    "network":  { icon: "🌐", title: tr("cell_network"), subtitle: selectedLang === "fr" ? "Connecté" : "Connected", detail: selectedLang === "fr" ? "Stats temps réel" : "Real-time stats", action: "detail:network", highlighted: false },
                                    "beehive":  { icon: "🐝", title: "Bee-Hive OS",      subtitle: selectedLang === "fr" ? "En ligne" : "Online", detail: selectedLang === "fr" ? "Framework Actif" : "Framework Active", action: "none", highlighted: true }
                                }
                                var cellsArr = []
                                for (var i = 0; i < selectedCells.length; i++) {
                                    var k = selectedCells[i]
                                    if (cellDefs[k]) cellsArr.push(cellDefs[k])
                                }
                                // Pad to 8 if needed with defaults
                                if (cellsArr.length < 8) {
                                    var paddingKeys = ["analytics", "settings"]
                                    var padIdx = 0
                                    while (cellsArr.length < 8 && padIdx < paddingKeys.length) {
                                        var pk = paddingKeys[padIdx]
                                        var def = BeeConfig.trCell(pk)
                                        if (def) cellsArr.push(def)
                                        else cellsArr.push({ icon: "📦", title: "Module", subtitle: "", detail: "", action: "none", highlighted: false })
                                        padIdx++
                                    }
                                }
                                if (cellsArr.length > 0) {
                                    BeeConfig._cells.clear()
                                    for (var j = 0; j < cellsArr.length; j++) {
                                        var c = cellsArr[j]
                                        BeeConfig._cells.append({
                                            icon: c.icon || "📦",
                                            title: c.title || "Module",
                                            subtitle: c.subtitle || "",
                                            detail: c.detail || "",
                                            action: c.action || "none",
                                            highlighted: c.highlighted || false,
                                            customizable: true,
                                            color: c.color || ""
                                        })
                                    }
                                    BeeConfig.cellsRevision++
                                }

                                // Save everything
                                BeeConfig.saveConfig()

                                // Mark as welcomed
                                Qt.createQmlObject(
                                    'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "mkdir -p ~/.config/beehive && touch ~/.config/beehive/.bee_welcomed"] }',
                                    welcomeRoot, "markWelcome"
                                )

                                // Dismiss with confirmation animation
                                confirmAnim.start()
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Confirmation Animation ────────────────────────────
    ParallelAnimation {
        id: confirmAnim
        NumberAnimation { target: card; property: "scale";   to: 1.05; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "opacity"; to: 0;    duration: 400; easing.type: Easing.InCubic }
        onFinished: welcomeRoot.dismissed()
    }
}