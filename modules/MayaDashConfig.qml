import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDashConfig.qml — Dashboard Configuration Panel 🐝⚙️
// Sidebar with 4 sections: Alvéoles · Presets · Profils · Motion
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: dashConfig
    width: 720
    height: 580
    radius: 20
    visible: false
    color: BeeTheme.mode === "HoneyDark"
        ? Qt.rgba(0.06, 0.05, 0.08, 1.0)
        : Qt.rgba(0.96, 0.94, 0.90, 1.0)
    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
    border.width: 1

    // ─── Entry / Exit animation ───────────────────────────
    property real panelScale: visible ? 1.0 : 0.92
    property real panelOpacity: visible ? 1.0 : 0.0
    Behavior on panelScale   { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on panelOpacity { NumberAnimation { duration: 200 } }
    scale: panelScale
    opacity: panelOpacity

    // ─── State ──────────────────────────────────────────────
    property int currentSection: 0  // 0=Alvéoles 1=Presets 2=Profils 3=Motion
    property string _fr: BeeConfig.uiLang === "fr" ? "1" : ""

    // ─── Cell Editor State ───────────────────────────────────
    property int    selectedIndex:  -1
    property bool   editCustomizable: true
    property bool   _cellDeletable: true
    property string editIcon:       ""
    property string editTitle:      ""
    property string editSubtitle:    ""
    property string editDetail:     ""
    property string editAction:     ""
    property bool   editHighlighted: false
    property bool   _loading: false

    // ─── Translation helper ─────────────────────────────────
    function tr(key) {
        var translations = {
            "section_cells":     _fr ? "Alvéoles" : "Cells",
            "section_presets":   _fr ? "Préréglages" : "Presets",
            "section_profiles":  _fr ? "Profils" : "Profiles",
            "section_motion":    _fr ? "Mouvement" : "Motion",
            "select_cell_prompt": _fr ? "Sélectionnez une alvéole" : "Select a cell",
            "field_label_icon":     _fr ? "Icône" : "Icon",
            "field_label_title":    _fr ? "Titre" : "Title",
            "field_label_subtitle": _fr ? "Sous-titre" : "Subtitle",
            "field_label_detail":  _fr ? "Détail" : "Detail",
            "field_label_action":  _fr ? "Action" : "Action",
            "field_placeholder_icon": "🌐 📅 🎵",
            "field_placeholder_title": _fr ? "Mon Module" : "My Module",
            "field_placeholder_subtitle": _fr ? "Description" : "Description",
            "field_placeholder_detail_hint": _fr ? "Détail affiché sous le titre" : "Detail shown under the title",
            "highlighted_checkbox": _fr ? "Mis en évidence" : "Highlighted",
            "highlighted_tooltip": _fr ? "Brillance dorée autour de la cellule" : "Golden glow around the cell",
            "save_button":        _fr ? "💾 Sauvegarder" : "💾 Save",
            "add_cell":           _fr ? "➕ Ajouter" : "➕ Add",
            "delete_cell":        _fr ? "🗑️ Supprimer" : "🗑️ Delete",
            "motion_enabled":     _fr ? "Effet parallaxe" : "Parallax effect",
            "motion_desc":        _fr ? "Inclinaison 3D selon la souris" : "3D tilt following mouse position",
            "title_config":       _fr ? "Configuration du tableau de bord" : "Dashboard Configuration",
            "preset_default":     _fr ? "Défaut" : "Default",
            "preset_minimal":     _fr ? "Minimal" : "Minimal",
            "preset_productivity": _fr ? "Productivité" : "Productivity",
            "preset_entertainment": _fr ? "Divertissement" : "Entertainment",
            "apply_preset":       _fr ? "Appliquer" : "Apply",
            "profile_default":    _fr ? "Par défaut" : "Default",
            "profile_desc":       _fr ? "Profils de configuration utilisateur" : "User configuration profiles"
        }
        return translations[key] || key
    }

    // ─── Load cell ──────────────────────────────────────────
    function loadCell(index) {
        if (index < 0 || index >= BeeConfig.cells.count) return
        selectedIndex = index
        _loading = true
        var c = BeeConfig.cells.get(index)
        editIcon       = c.icon       || ""
        editTitle       = c.title      || ""
        editSubtitle    = c.subtitle   || ""
        editDetail      = c.detail    || ""
        editAction      = c.action     || ""
        editHighlighted  = c.highlighted || false
        editCustomizable = c.customizable !== false
        _cellDeletable  = c.customizable !== false
        _loading = false
    }

    // ─── Apply edits ─────────────────────────────────────────
    function applyEdits() {
        if (selectedIndex < 0 || selectedIndex >= BeeConfig.cells.count) return
        BeeConfig.cells.set(selectedIndex, {
            icon:         editIcon,
            title:        editTitle,
            subtitle:     editSubtitle,
            detail:       editDetail,
            action:       editAction,
            highlighted:  editHighlighted,
            customizable: editCustomizable,
            color:        BeeConfig.cells.get(selectedIndex).color || null
        })
        BeeConfig.cellsRevision++
        BeeConfig.saveConfig()
    }

    // ─── Close button ───────────────────────────────────────
    Rectangle {
        anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 10 }
        width: 34; height: 34; radius: 17; z: 100
        color: closeHov.containsMouse
            ? Qt.rgba(1.0, 0.3, 0.3, 0.25)
            : (BeeTheme.mode === "HoneyDark" ? Qt.rgba(0.06, 0.05, 0.08, 1.0) : Qt.rgba(0.96, 0.94, 0.90, 1.0))
        border.color: closeHov.containsMouse ? Qt.rgba(1.0, 0.3, 0.3, 0.6) : BeeTheme.accent
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Text { text: "✕"; anchors.centerIn: parent; color: closeHov.containsMouse ? "#ff5555" : BeeTheme.accent; font.bold: true; font.pixelSize: 14 }
        MouseArea { id: closeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dashConfig.visible = false } }
    }

    // ─── Sidebar + Content ──────────────────────────────────
    RowLayout {
        anchors.fill: parent; spacing: 0
        anchors.margins: 1

        // ─── Sidebar ───
        Rectangle {
            id: sidebar
            Layout.fillHeight: true
            width: 140
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: BeeTheme.separator }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                spacing: 0

                // Logo
                Text { text: "⚙️"; font.pixelSize: 28; Layout.alignment: Qt.AlignHCenter; bottomPadding: 2 }
                Text { text: dashConfig.tr("title_config").split(" ").slice(0, 2).join(" "); color: BeeTheme.accent; font.bold: true; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter; bottomPadding: 12 }

                // Section buttons
                Repeater {
                    model: [
                        { icon: "🍯", label: dashConfig.tr("section_cells"),     idx: 0 },
                        { icon: "🎨", label: dashConfig.tr("section_presets"),   idx: 1 },
                        { icon: "👤", label: dashConfig.tr("section_profiles"),  idx: 2 },
                        { icon: "🌀", label: dashConfig.tr("section_motion"),    idx: 3 }
                    ]
                    delegate: Rectangle {
                        width: sidebar.width - 16; height: 44; radius: 10
                        Layout.alignment: Qt.AlignHCenter
                        color: dashConfig.currentSection === modelData.idx
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                            : (sectionHover.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            Text {
                                text: modelData.icon; font.pixelSize: 18
                                opacity: dashConfig.currentSection === modelData.idx ? 1.0 : 0.6
                            }
                            Text {
                                text: modelData.label
                                color: dashConfig.currentSection === modelData.idx ? BeeTheme.accent : BeeTheme.textPrimary
                                font.pixelSize: 12; font.bold: dashConfig.currentSection === modelData.idx
                                elide: Text.ElideRight; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        MouseArea {
                            id: sectionHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { dashConfig.currentSection = modelData.idx; BeeSound.playEvent("ui.cell.click") }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ─── Main Content ───
        Loader {
            id: contentLoader
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            source: {
                switch (dashConfig.currentSection) {
                    case 0: return "MayaDashConfigCells.qml"
                    case 1: return "MayaDashConfigPresets.qml"
                    case 2: return "MayaDashConfigProfiles.qml"
                    case 3: return "MayaDashConfigMotion.qml"
                    default: return "MayaDashConfigCells.qml"
                }
            }
        }
    }

    // ─── Sound ───────────────────────────────────────────────
    onVisibleChanged: {
        if (visible) BeeSound.playEvent("dash.open")
        else BeeSound.playEvent("dash.close")
    }
}