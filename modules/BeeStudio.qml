import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Qt.labs.folderlistmodel

// ═══════════════════════════════════════════════════════════════
// BeeStudio.qml — Control Center BeeAura (Bee-Hive OS) 🐝🎨
// v2.0 : Control Center — overlay centré, navigation latérale
//        Alvéoles · Fonds d'écran · Historique
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeStudio
    anchors.fill: parent

    // ─── Mode embarqué (dans BeeControl) — masque la sidebar ────
    property bool embedded: false

    // ─── Catégorie active ────────────────────────────────────────
    property int activeCategory: 0   // 0=Dashboard 1=Alvéoles 2=Fonds d'écran 3=Historique 4=Presets

    // ─── Dossier fonds d'écran ───────────────────────────────────
    property string wallpaperFolder: "/home/marc/Pictures/Wallpapers"

    // ─── Selection / editing state (Cells) ────────────────────────
    property int    selectedIndex:    -1
    property bool   editCustomizable: true
    property string editIcon:         ""
    property string editTitle:        ""
    property string editSubtitle:     ""
    property string editDetail:       ""
    property string editAction:       ""
    property bool   editHighlighted:  false
    property bool   _loading:         false
    property bool   _saveDirty:       false
    property string autoThemeHint:    ""

    // ─── Presets state ─────────────────────────────────────────────
    property string presetNewName:   ""
    property string presetNewIcon:   "🍯"
    property int    presetToDelete:  -1

    // ─── Composant WallCard (Unified Wallpaper) ─────────────────
    component WallCard: Item {
        property string src: ""
        property string label: ""
        property string mode: ""
        width: 156; height: 106

        property bool active: {
            if (!src) return false;
            let resolved = src.startsWith("..") ? Qt.resolvedUrl(src).toString() : "file://" + src;
            return resolved === BeeTheme.wallpaperOverride || BeeTheme.wallpaper === src;
        }

        Rectangle {
            anchors { fill: parent; margins: 4 }
            radius: 10; clip: true
            color: BeeTheme.secondary
            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, active ? 1.0 : 0.18)
            border.width: active ? 2 : 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Image {
                anchors.fill: parent; anchors.margins: 1
                source: parent.parent.src.startsWith("..") ? parent.parent.src : "file://" + parent.parent.src
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true
                opacity: parent.parent.active ? 1.0 : 0.8
            }

            // Badge sélectionné
            Rectangle {
                visible: parent.parent.active
                anchors { right: parent.right; top: parent.top; margins: 6 }
                width: 20; height: 20; radius: 10
                color: BeeTheme.accent
                Text { text: "✓"; anchors.centerIn: parent; color: BeeTheme.textPrimary; font { pixelSize: 10; bold: true } }
            }

            // Overlay hover
            Rectangle {
                id: wallHover; anchors.fill: parent; color: "transparent"; radius: parent.radius
                property bool hov: false
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: wallHover.hov = true
                    onExited:  wallHover.hov = false
                    onClicked: {
                        BeeTheme.wallpaperOverride = parent.parent.parent.src
                        if (BeeTheme.nectarSync && parent.parent.parent.mode !== "")
                            BeeTheme.setMode(parent.parent.parent.mode)
                        var name = parent.parent.parent.label || parent.parent.parent.src.split("/").pop()
                        BeeBarState.logAction("Design", "Wallpaper : " + name, "🖼")
                        BeeConfig.applyAutoThemeFromWallpaper(parent.parent.parent.src, false)
                    }
                }
                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 28; radius: parent.radius
                    color: Qt.rgba(0, 0, 0, wallHover.hov ? 0.55 : 0)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; margins: 8 }
                        text: wallHover.parent.label || ""
                        color: "white"; font.pixelSize: 9
                        elide: Text.ElideMiddle
                        opacity: wallHover.hov ? 0.90 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }

    // ─── Traductions ───────────────────────────────────────────────
    function tr(key) {
        if (!BeeConfig.tr || !BeeConfig.tr.studio) return ""
        return BeeConfig.tr.studio[key] || ""
    }

    // ─── Chargement cellule ──────────────────────────────────────
    function loadCell(index) {
        if (index < 0 || index >= BeeConfig.cells.count) return
        _loading = true
        var c            = BeeConfig.cells.get(index)
        selectedIndex    = index
        editCustomizable = c.customizable !== false
        editIcon         = c.icon        || ""
        editTitle        = c.title       || ""
        editSubtitle     = c.subtitle    || ""
        editDetail       = c.detail      || ""
        editAction       = c.action      || "none"
        editHighlighted  = c.highlighted || false
        iconField.text     = editIcon
        titleField.text    = editTitle
        subtitleField.text = editSubtitle
        detailInput.text   = editDetail
        actionField.text   = editAction
        _loading = false
    }

    function applyEdits() {
        if (selectedIndex < 0 || !editCustomizable) return
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
        _saveDirty = true
    }

    function refreshAutoThemeHint() {
        if (BeeConfig.autoThemeStatus === "ok")
            autoThemeHint = "Theme auto applique."
        else if (BeeConfig.autoThemeStatus === "running")
            autoThemeHint = "Generation du theme en cours..."
        else if (BeeConfig.autoThemeStatus === "error")
            autoThemeHint = "Erreur generation auto-theme."
        else if (BeeConfig.autoThemeStatus === "warn")
            autoThemeHint = "Overlay genere, palette invalide."
        else if (BeeConfig.autoThemeStatus === "busy")
            autoThemeHint = "Generation deja en cours."
        else if (BeeConfig.autoThemeStatus === "dedup")
            autoThemeHint = "Wallpaper deja traite."
        else if (BeeConfig.autoThemeStatus === "disabled")
            autoThemeHint = "Nectar Sync desactive."
        else if (BeeConfig.autoThemeStatus === "invalid")
            autoThemeHint = "Wallpaper invalide."
        else
            autoThemeHint = ""
    }

    function applyThemeFromCurrentWallpaper(force) {
        var source = BeeTheme.wallpaperOverride !== "" ? BeeTheme.wallpaperOverride : BeeTheme.wallpaper
        BeeConfig.applyAutoThemeFromWallpaper(source, force === true)
        refreshAutoThemeHint()
    }

    // ─── Open/Close ──────────────────────────────────────────────
    Component.onCompleted: {
        backdropIn.start()
        openAnim.start()
        refreshAutoThemeHint()
    }

    Connections {
        target: BeeConfig
        function onAutoThemeStatusChanged() {
            refreshAutoThemeHint()
        }
    }

    function requestClose() { backdropOut.start(); closeAnim.start() }

    // ════════════════════════════════════════════════════════════
    // BACKDROP
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: BeeTheme.mode === "HoneyDark"
            ? Qt.rgba(0.01, 0.01, 0.03, 0.78)
            : Qt.rgba(0.10, 0.08, 0.05, 0.55)
        opacity: 0
        Behavior on color { ColorAnimation { duration: 600 } }

        NumberAnimation { id: backdropIn;  target: backdrop; property: "opacity"; to: 1.0; duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { id: backdropOut; target: backdrop; property: "opacity"; to: 0.0; duration: 220; easing.type: Easing.InCubic }

        MouseArea {
            anchors.fill: parent
            onClicked: beeStudio.requestClose()
        }
    }

    // ════════════════════════════════════════════════════════════
    // PANEL PRINCIPAL (centré)
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: studioPanel
        anchors.centerIn: parent
        width:  Math.min(parent.width  * 0.90, 1020)
        height: Math.min(parent.height * 0.86, 700)
        radius: 20
        color: BeeTheme.mode === "HoneyDark"
            ? Qt.rgba(0.05, 0.05, 0.07, 0.97)
            : Qt.rgba(0.97, 0.95, 0.90, 0.97)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
        border.width: 1.5
        clip: true
        opacity: 0
        scale: 0.90

        Behavior on color        { ColorAnimation { duration: 600 } }
        Behavior on border.color { ColorAnimation { duration: 600 } }

        // Background Sidebar intégré pour éviter la coupure de la ligne
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 210
            color: BeeTheme.mode === "HoneyDark"
                ? Qt.rgba(0.035, 0.035, 0.050, 0.5)
                : Qt.rgba(0.92, 0.89, 0.83, 0.5)
            Behavior on color { ColorAnimation { duration: 600 } }
        }

        ParallelAnimation {
            id: openAnim
            NumberAnimation { target: studioPanel; property: "opacity"; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: studioPanel; property: "scale";   to: 1.0; duration: 340; easing.type: Easing.OutBack }
        }
        ParallelAnimation {
            id: closeAnim
            NumberAnimation { target: studioPanel; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: studioPanel; property: "scale";   to: 0.90; duration: 220; easing.type: Easing.InCubic }
            onFinished: beeStudio.visible = false
        }

        // Subtle aura glow on border
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
            shadowBlur: 0.8; shadowVerticalOffset: 0; shadowHorizontalOffset: 0
        }

        // Bouton fermeture (Top Right) — masqué en mode embedded
        Rectangle {
            id: closeRect
            visible: !beeStudio.embedded
            anchors { right: parent.right; top: parent.top; margins: 12 }
            z: 100
            width: 32; height: 32; radius: 16
            color: closeHov.containsMouse
                ? Qt.rgba(1.0, 0.3, 0.3, 0.2)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
            border.color: closeHov.containsMouse
                ? Qt.rgba(1.0, 0.3, 0.3, 0.5)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "✕"; anchors.centerIn: parent
                color: closeHov.containsMouse ? "#ff5555" : BeeTheme.accent
                font { pixelSize: 14; bold: true }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: closeHov; anchors.fill: parent
                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: beeStudio.requestClose()
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ════════════════════════════════════════════════
            // SIDEBAR GAUCHE
            // ════════════════════════════════════════════════
            Item {
                id: sidebar
                Layout.preferredWidth: 210
                Layout.fillHeight: true
                visible: !beeStudio.embedded

                // Séparateur droit
                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 1
                    opacity: 0.5
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.15; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18) }
                        GradientStop { position: 0.85; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ── Logo ──────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        height: 76

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 3

                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6
                                Text { text: "🐝"; font.pixelSize: 20 }
                                Text {
                                    text: tr("title")
                                    color: BeeTheme.accent
                                    font { bold: true; pixelSize: 18; letterSpacing: 1.2 }
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 600 } }
                                }
                            }
                            Text {
                                text: tr("subtitle") + "  v2.1"
                                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.30)
                                font { pixelSize: 9; letterSpacing: 0.8 }
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Séparateur
                    Rectangle {
                        Layout.fillWidth: true; height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0;  color: "transparent" }
                            GradientStop { position: 0.25; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.28) }
                            GradientStop { position: 0.75; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.28) }
                            GradientStop { position: 1.0;  color: "transparent" }
                        }
                    }

                    Item { height: 16 }

                    // ── Label section ────────────────────────
                    Text {
                        text: tr("categories_label")
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.32)
                        font { pixelSize: 8; bold: true; letterSpacing: 2.2 }
                        Layout.leftMargin: 20
                    }

                    Item { height: 8 }

                    // ── Catégories ────────────────────────────
                    ListModel {
                        id: categoryModel
                        ListElement { catIcon: "📱"; catKey: "category_dashboard"; catSub: "dashboard_desc" }
                        ListElement { catIcon: "🍯"; catKey: "category_cells"; catSub: "cells_desc" }
                        ListElement { catIcon: "🖼";  catKey: "category_wallpapers"; catSub: "wallpapers_desc" }
                        ListElement { catIcon: "🔔"; catKey: "category_history"; catSub: "history_desc" }
                        ListElement { catIcon: "🎯"; catKey: "category_presets"; catSub: "presets_desc" }
                    }

                    Repeater {
                        model: categoryModel

                        delegate: Item {
                            Layout.fillWidth: true
                            height: 64

                            property bool hovered: false
                            property bool isActive: beeStudio.activeCategory === index

                            // Fond
                            Rectangle {
                                anchors.fill: parent
                                color: isActive
                                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.14)
                                    : hovered
                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.07)
                                        : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // Accent bar gauche
                            Rectangle {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                width: 3; radius: 1
                                color: BeeTheme.accent
                                opacity: isActive ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 18; rightMargin: 14 }
                                spacing: 12

                                Text {
                                    text: catIcon
                                    font.pixelSize: 20
                                    opacity: isActive ? 1.0 : 0.60
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text {
                                        text: tr(catKey)
                                        color: isActive ? BeeTheme.accent : BeeTheme.textPrimary
                                        font { pixelSize: 13; bold: isActive }
                                        Layout.fillWidth: true; elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 600 } }
                                    }
                                    Text {
                                        text: tr(catSub)
                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.36)
                                        font.pixelSize: 9; Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                onClicked: beeStudio.activeCategory = index
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // ── Séparateur footer ─────────────────────
                    Rectangle {
                        Layout.fillWidth: true; height: 1
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                    }

                    // ── Footer sidebar ────────────────────────
                    Item {
                        Layout.fillWidth: true; height: 54

                        RowLayout {
                            anchors { fill: parent; leftMargin: 18; rightMargin: 14 }
                            spacing: 8

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: (BeeConfig.tr.common && BeeConfig.tr.common.bee_studio_title) || (BeeConfig.tr.common && BeeConfig.tr.common.bee_studio_title) || "BeeStudio v2.1 🍯"
                                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.22)
                                    font { pixelSize: 9; letterSpacing: 0.5 }
                                }
                                Text {
                                    visible: beeStudio._saveDirty
                                    text: (BeeConfig.tr.common && BeeConfig.tr.common.unsaved) || (BeeConfig.tr.common && BeeConfig.tr.common.unsaved) || "● unsaved"
                                    color: Qt.rgba(1.0, 0.75, 0.2, 0.70)
                                    font { pixelSize: 8; italic: true }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

            // ════════════════════════════════════════════════
            // ZONE CONTENU DROITE
            // ════════════════════════════════════════════════
            Item {
                id: contentArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ──────────────────────────────────────────────
                // PANNEAU 0 : ALVÉOLES 🍯
                // ──────────────────────────────────────────────
                Item {
                    id: panelAlveoles
                    anchors.fill: parent
                    visible: beeStudio.activeCategory === 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 0
                        spacing: 0

                        // ── Header catégorie ──────────────────
                        Item {
                            Layout.fillWidth: true; height: 60

                            RowLayout {
                                anchors { fill: parent; leftMargin: 22; rightMargin: 20 }
                                spacing: 12

                                Text { text: "🍯"; font.pixelSize: 24 }
                                ColumnLayout {
                                    spacing: 1
                                    Text {
                                        text: (BeeConfig.tr.common && BeeConfig.tr.common.cells) || (BeeConfig.tr.common && BeeConfig.tr.common.cells) || "Cells"
                                        color: BeeTheme.accent
                                        font { bold: true; pixelSize: 17; letterSpacing: 0.8 }
                                        Behavior on color { ColorAnimation { duration: 600 } }
                                    }
                                    Text {
                                        text: (BeeConfig.tr.common && BeeConfig.tr.common.dashboard_cell_editor) || (BeeConfig.tr.common && BeeConfig.tr.common.dashboard_cell_editor) || "Dashboard cell editor"
                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                                        font.pixelSize: 10
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }

                        // Séparateur
                        Rectangle {
                            height: 1; Layout.fillWidth: true
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.1; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) }
                                GradientStop { position: 0.9; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // ── Corps : Éditeur / Historique ──────
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true

                            // ── Éditeur de cellules ───────────
                            Item {
                                id: cellEditor
                                anchors.fill: parent

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 14

                                    // Liste alvéoles
                                    Rectangle {
                                        Layout.preferredWidth: 168; Layout.fillHeight: true
                                        radius: 12
                                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.04)
                                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.fill: parent; anchors.margins: 12; spacing: 7

                                            Text {
                                                text: tr("section_cells")
                                                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                                                font { pixelSize: 9; bold: true; letterSpacing: 2 }
                                            }

                                            ListView {
                                                Layout.fillWidth: true; Layout.fillHeight: true
                                                clip: true; model: BeeConfig.cells; spacing: 4

                                                delegate: Rectangle {
                                                    width: parent ? parent.width : 0
                                                    height: 46; radius: 9
                                                    color: beeStudio.selectedIndex === index
                                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                                                    border.color: beeStudio.selectedIndex === index
                                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.50)
                                                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                                                    border.width: 1
                                                    Behavior on color       { ColorAnimation { duration: 150 } }
                                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                                    RowLayout {
                                                        anchors.fill: parent; anchors.margins: 9; spacing: 8
                                                        Text {
                                                            text: (beeStudio.selectedIndex === index)
                                                                ? (beeStudio.editIcon || "🐝") : (model.icon || "🐝")
                                                            font.pixelSize: 18
                                                        }
                                                        ColumnLayout {
                                                            Layout.fillWidth: true; spacing: 1
                                                            Text {
                                                                text: (beeStudio.selectedIndex === index)
                                                                    ? (beeStudio.editTitle || "—") : (model.title || "—")
                                                                color: beeStudio.selectedIndex === index ? BeeTheme.accent : BeeTheme.textPrimary
                                                                font { pixelSize: 11; bold: true }
                                                                Layout.fillWidth: true; elide: Text.ElideRight
                                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                            }
                                                            Text {
                                                                visible: model.customizable === false
                                                                text: (BeeConfig.tr.common && BeeConfig.tr.common.protected) || (BeeConfig.tr.common && BeeConfig.tr.common.protected) || "🔒 protected"; font.pixelSize: 8
                                                                color: Qt.rgba(1.0, 0.65, 0.2, 0.65)
                                                            }
                                                        }
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                        onClicked: beeStudio.loadCell(index)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Formulaire édition
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        radius: 12
                                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.03)
                                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                                        border.width: 1

                                        // Placeholder
                                        ColumnLayout {
                                            visible: beeStudio.selectedIndex < 0
                                            anchors.centerIn: parent; spacing: 14
                                            Text {
                                                text: "🍯"; font.pixelSize: 44
                                                Layout.alignment: Qt.AlignHCenter
                                                SequentialAnimation on opacity {
                                                    loops: Animation.Infinite
                                                    NumberAnimation { to: 0.4; duration: 2500; easing.type: Easing.InOutSine }
                                                    NumberAnimation { to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
                                                }
                                            }
                                            Text {
                                                text: tr("select_cell_prompt")
                                                color: BeeTheme.accent; font { bold: true; pixelSize: 14; letterSpacing: 0.6 }
                                                Layout.alignment: Qt.AlignHCenter
                                                Behavior on color { ColorAnimation { duration: 600 } }
                                            }
                                        }

                                        // Formulaire
                                        Flickable {
                                            visible: beeStudio.selectedIndex >= 0
                                            anchors.fill: parent; anchors.margins: 16
                                            contentHeight: editForm.implicitHeight; clip: true

                                            ColumnLayout {
                                                id: editForm
                                                width: parent.width; spacing: 10

                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 10
                                                    Text { text: beeStudio.editIcon || "🐝"; font.pixelSize: 32 }
                                                    ColumnLayout {
                                                        spacing: 2; Layout.fillWidth: true
                                                        Text {
                                                            text: beeStudio.editTitle || "Cell"
                                                            color: BeeTheme.accent; font { bold: true; pixelSize: 15 }
                                                            elide: Text.ElideRight; Layout.fillWidth: true
                                                            Behavior on color { ColorAnimation { duration: 300 } }
                                                        }
                                                        Text {
                                                            text: beeStudio.editCustomizable ? tr("editable_label_modifiable") : tr("editable_label_readonly")
                                                            color: beeStudio.editCustomizable
                                                                ? Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4)
                                                                : Qt.rgba(1.0, 0.65, 0.2, 0.75)
                                                            font.pixelSize: 10
                                                        }
                                                    }
                                                }
                                                Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15) }

                                                component FieldLabel: Text {
                                                    property string labelText: ""
                                                    text: labelText
                                                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
                                                    font { pixelSize: 9; bold: true; letterSpacing: 1.5 }
                                                }
                                                component BeeField: TextField {
                                                    Layout.fillWidth: true; height: 36
                                                    enabled: beeStudio.editCustomizable
                                                    leftPadding: 10; rightPadding: 10
                                                    color: BeeTheme.textPrimary
                                                    placeholderTextColor: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                                                    font.pixelSize: 12
                                                    background: Rectangle {
                                                        radius: 7
                                                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, parent.enabled ? 0.07 : 0.03)
                                                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, parent.activeFocus ? 0.5 : (parent.enabled ? 0.15 : 0.07))
                                                        border.width: 1
                                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                                        Behavior on color        { ColorAnimation { duration: 150 } }
                                                    }
                                                }

                                                FieldLabel { labelText: tr("field_label_icon") }
                                                BeeField { id: iconField; placeholderText: tr("field_placeholder_icon"); onTextEdited: { if (!beeStudio._loading) beeStudio.editIcon = text } }

                                                FieldLabel { labelText: tr("field_label_title") }
                                                BeeField { id: titleField; placeholderText: tr("field_placeholder_title"); onTextEdited: { if (!beeStudio._loading) beeStudio.editTitle = text } }

                                                FieldLabel { labelText: tr("field_label_subtitle") }
                                                BeeField { id: subtitleField; placeholderText: tr("field_placeholder_subtitle"); onTextEdited: { if (!beeStudio._loading) beeStudio.editSubtitle = text } }

                                                FieldLabel { labelText: tr("field_label_detail") }
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 64; radius: 7
                                                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, beeStudio.editCustomizable ? 0.07 : 0.03)
                                                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, detailInput.activeFocus ? 0.5 : (beeStudio.editCustomizable ? 0.15 : 0.07))
                                                    border.width: 1
                                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                                    TextEdit {
                                                        id: detailInput; anchors.fill: parent; anchors.margins: 9
                                                        enabled: beeStudio.editCustomizable; color: BeeTheme.textPrimary
                                                        font.pixelSize: 11; wrapMode: TextEdit.Wrap
                                                        onTextChanged: { if (!beeStudio._loading) beeStudio.editDetail = text }
                                                        Text {
                                                            visible: parent.text === ""
                                                            text: tr("field_placeholder_detail_hint")
                                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                                                            font.pixelSize: 11; anchors.fill: parent
                                                        }
                                                    }
                                                }

                                                FieldLabel { labelText: tr("field_label_action") }
                                                BeeField { id: actionField; placeholderText: "none | app:nom | toggle:settings"; onTextEdited: { if (!beeStudio._loading) beeStudio.editAction = text } }

                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 10
                                                    ColumnLayout {
                                                        spacing: 1; Layout.fillWidth: true
                                                        Text {
                                                            text: tr("highlighted_checkbox"); color: BeeTheme.textPrimary
                                                            font { pixelSize: 12; bold: true }
                                                            Behavior on color { ColorAnimation { duration: 600 } }
                                                        }
                                                        Text { text: tr("highlighted_tooltip"); color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4); font.pixelSize: 9 }
                                                    }
                                                    Switch {
                                                        checked: beeStudio.editHighlighted; enabled: beeStudio.editCustomizable
                                                        onCheckedChanged: { if (!beeStudio._loading) beeStudio.editHighlighted = checked }
                                                    }
                                                }

                                                // Bouton Appliquer
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 38; radius: 10
                                                    enabled: beeStudio.editCustomizable
                                                    color: enabled
                                                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.16)
                                                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                                                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, enabled ? 0.4 : 0.1)
                                                    border.width: 1
                                                    Behavior on color       { ColorAnimation { duration: 150 } }
                                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                                    Text {
                                                        text: beeStudio.editCustomizable ? tr("save_button") : tr("protected")
                                                        color: beeStudio.editCustomizable ? BeeTheme.accent : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.25)
                                                        font { pixelSize: 12; bold: true }
                                                        anchors.centerIn: parent
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: beeStudio.editCustomizable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                        enabled: beeStudio.editCustomizable
                                                        onClicked: beeStudio.applyEdits()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                        }

                        // ── Footer Éditeur ────────────────────
                        Item {
                            Layout.fillWidth: true; height: 52

                            Rectangle { anchors.top: parent.top; height: 1; anchors.left: parent.left; anchors.right: parent.right; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10) }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 20; rightMargin: 16 }
                                spacing: 10
                                
                                // Add new cell button
                                Rectangle {
                                    width: 100; height: 30; radius: 15
                                    color: Qt.rgba(0.2, 0.7, 0.3, 0.15)
                                    border.color: Qt.rgba(0.2, 0.7, 0.3, 0.40); border.width: 1
                                    Text { text: "➕ Add"; color: "#4CAF50"; font { pixelSize: 11; bold: true } anchors.centerIn: parent }
                                    MouseArea { 
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // Add a new empty cell
                                            BeeConfig.cells.append({
                                                icon: "🐝",
                                                title: "New Cell",
                                                subtitle: "Click to edit",
                                                detail: "",
                                                action: "none",
                                                highlighted: false,
                                                customizable: true,
                                                color: ""
                                            })
                                            BeeConfig.saveConfig()
                                            BeeBarState.logAction("My Hive", "Nouvelle alvéole ajoutée", "➕")
                                        }
                                    }
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                // Delete button (only when a cell is selected and is customizable)
                                Rectangle {
                                    width: 100; height: 30; radius: 15
                                    color: beeStudio.selectedIndex >= 0 && beeStudio.editCustomizable ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : Qt.rgba(0.5, 0.5, 0.5, 0.1)
                                    border.color: beeStudio.selectedIndex >= 0 && beeStudio.editCustomizable ? "#ff4444" : "#888888"
                                    border.width: 1
                                    opacity: beeStudio.selectedIndex >= 0 && beeStudio.editCustomizable ? 1 : 0.5
                                    Text { 
                                        text: "🗑️ Delete"; 
                                        color: beeStudio.selectedIndex >= 0 && beeStudio.editCustomizable ? "#ff4444" : "#888888"; 
                                        font { pixelSize: 11; bold: true } 
                                        anchors.centerIn: parent 
                                    }
                                    MouseArea { 
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        enabled: beeStudio.selectedIndex >= 0 && beeStudio.editCustomizable
                                        onClicked: {
                                            if (beeStudio.selectedIndex >= 0 && beeStudio.editCustomizable) {
                                                BeeConfig.cells.remove(beeStudio.selectedIndex)
                                                beeStudio.selectedIndex = -1
                                                BeeConfig.saveConfig()
                                                BeeBarState.logAction("My Hive", "Alvéole supprimée", "🗑️")
                                            }
                                        }
                                    }
                                }
                                
                                // Save button
                                Rectangle {
                                    width: 130; height: 30; radius: 15
                                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.40); border.width: 1
                                    Text { text: tr("save_button"); color: BeeTheme.accent; font { pixelSize: 11; bold: true } anchors.centerIn: parent; Behavior on color { ColorAnimation { duration: 600 } } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { BeeConfig.saveConfig(); beeStudio._saveDirty = false; BeeBarState.logAction("My Hive", "Alvéoles sauvegardées", "🍯") } }
                                }
                            }
                        }
                    }
                }

                // ──────────────────────────────────────────────
                // PANNEAU 1 : FONDS D'ÉCRAN 🖼
                // ──────────────────────────────────────────────
                Item {
                    id: panelWallpapers
                    anchors.fill: parent
                    visible: beeStudio.activeCategory === 1 || beeStudio.activeCategory === 2

                    // Modèle de dossier
                    FolderListModel {
                        id: wallpaperModel
                        folder: beeStudio.wallpaperFolder.length > 0
                            ? Qt.resolvedUrl("file://" + beeStudio.wallpaperFolder)
                            : "file:///nonexistent"
                        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }

                    ColumnLayout {
                        anchors.fill: parent; spacing: 0

                        // ── Header ────────────────────────────
                        Item {
                            Layout.fillWidth: true; height: 60
                            RowLayout {
                                anchors { fill: parent; leftMargin: 22; rightMargin: 20 } spacing: 12
                                Text { text: "🖼"; font.pixelSize: 24 }
                                ColumnLayout {
                                    spacing: 1
                                    Text { text: tr("wallpapers_header"); color: BeeTheme.accent; font { bold: true; pixelSize: 17; letterSpacing: 0.8 } Behavior on color { ColorAnimation { duration: 600 } } }
                                    Text { text: tr("subtitle_wallpapers_hover"); color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40); font.pixelSize: 10 }
                                }

                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 0.1; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) } GradientStop { position: 0.9; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) } GradientStop { position: 1.0; color: "transparent" } } }

                        // ── Barre dossier ─────────────────────
                        Item {
                            Layout.fillWidth: true; height: 62
                            RowLayout {
                                anchors { fill: parent; leftMargin: 16; rightMargin: 16 } spacing: 10
                                Text { text: "📁"; font.pixelSize: 14 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: 8
                                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18); border.width: 1
                                    TextInput {
                                        id: folderInput
                                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                        verticalAlignment: Text.AlignVCenter
                                        text: beeStudio.wallpaperFolder
                                        color: BeeTheme.textPrimary
                                        font.pixelSize: 11
                                        selectByMouse: true
                                        onEditingFinished: beeStudio.wallpaperFolder = text
                                        Text {
                                            visible: parent.text.length === 0
                                            anchors { fill: parent }
                                            verticalAlignment: Text.AlignVCenter
                                            text: (BeeConfig.tr.common && BeeConfig.tr.common.wallpapers_folder) || "~/Pictures/Wallpapers"
                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.30)
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                                Text {
                                    visible: wallpaperModel.count > 0
                                    text: wallpaperModel.count + " image" + (wallpaperModel.count !== 1 ? "s" : "")
                                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                                    font.pixelSize: 9
                                }
                            }
                            Text {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 44; rightMargin: 16; bottomMargin: 2 }
                                text: beeStudio.autoThemeHint
                                color: BeeConfig.autoThemeStatus === "error"
                                    ? Qt.rgba(1.0, 0.45, 0.45, 0.9)
                                    : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.55)
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                visible: beeStudio.autoThemeHint.length > 0
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08) }

                        // ── Grille de fonds d'écran ───────────
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true

                            Flickable {
                                anchors.fill: parent
                                contentHeight: wallContainer.implicitHeight + 40
                                clip: true
                                ScrollBar.vertical: ScrollBar {
                                    width: 4; policy: ScrollBar.AsNeeded
                                    contentItem: Rectangle { radius: 2; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2) }
                                }

                                ColumnLayout {
                                    id: wallContainer
                                    width: parent.width - 40
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top; anchors.topMargin: 20
                                    spacing: 28

                                    // --- ORIGINAUX ---
                                    ColumnLayout {
                                        spacing: 12; Layout.fillWidth: true
                                        Text {
                                            text: (BeeConfig.tr.common && BeeConfig.tr.common.beehive_originals) || "BEE-HIVE ORIGINALS 🍯"
                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.45)
                                            font { pixelSize: 10; bold: true; letterSpacing: 1.5 }
                                        }
                                        Flow {
                                            Layout.fillWidth: true; spacing: 10
                                            WallCard { src: "../assets/wallpaper.png";       label: "Mysterious";  mode: "HoneyDark" }
                                            WallCard { src: "../assets/wallpaper_dark_bee.png"; label: "Dark Bee"; mode: "HoneyDark" }
                                            WallCard { src: "../assets/wallpaper_light_bee.png"; label: "Light Bee"; mode: "HoneyLight" }
                                            WallCard { src: "../assets/wallpaper_light.png"; label: "Soft Light"; mode: "HoneyLight" }
                                        }
                                    }

                                    // --- BIBLIOTHÈQUE ---
                                    ColumnLayout {
                                        spacing: 12; Layout.fillWidth: true
                                        Text {
                                            text: (BeeConfig.tr.common && BeeConfig.tr.common.my_library) || "MY LIBRARY 🖼"
                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.45)
                                            font { pixelSize: 10; bold: true; letterSpacing: 1.5 }
                                        }

                                        // État vide bibliothèque
                                        Text {
                                            visible: wallpaperModel.count === 0
                                            text: "No other wallpapers found in " + beeStudio.wallpaperFolder
                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.25)
                                            font.pixelSize: 11; font.italic: true
                                            Layout.leftMargin: 10
                                        }

                                        Flow {
                                            Layout.fillWidth: true; spacing: 10
                                            Repeater {
                                                model: wallpaperModel
                                                delegate: WallCard {
                                                    src: filePath
                                                    label: fileName
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ──────────────────────────────────────────────
                // PANNEAU 2 : HISTORIQUE 🔔
                // ──────────────────────────────────────────────
                Item {
                    id: panelHistorique
                    anchors.fill: parent
                    visible: beeStudio.activeCategory === 3

                    ColumnLayout {
                        anchors.fill: parent; spacing: 0

                        // ── Header ────────────────────────────
                        Item {
                            Layout.fillWidth: true; height: 60
                            RowLayout {
                                anchors { fill: parent; leftMargin: 22; rightMargin: 20 } spacing: 12
                                Text { text: "🔔"; font.pixelSize: 24 }
                                ColumnLayout {
                                    spacing: 1
                                    Text { text: tr("history_header"); color: BeeTheme.accent; font { bold: true; pixelSize: 17; letterSpacing: 0.8 } Behavior on color { ColorAnimation { duration: 600 } } }
                                    Text { text: tr("history_desc"); color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40); font.pixelSize: 10 }
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 0.1; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) } GradientStop { position: 0.9; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) } GradientStop { position: 1.0; color: "transparent" } } }

                        // ── Corps ─────────────────────────────
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 12

                                Text {
                                    text: BeeBarState.historyModel.length > 0
                                        ? BeeBarState.historyModel.length + " notification" + (BeeBarState.historyModel.length > 1 ? "s" : "")
                                        : "Aucune notification"
                                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.45)
                                    font { pixelSize: 10; bold: true; letterSpacing: 1.5 }
                                }

                                // État vide
                                Item {
                                    visible: BeeBarState.historyModel.length === 0
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 14
                                        Text {
                                            text: "🔔"; font.pixelSize: 40; Layout.alignment: Qt.AlignHCenter
                                            SequentialAnimation on opacity {
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.3; duration: 2000; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 0.8; duration: 2000; easing.type: Easing.InOutSine }
                                            }
                                        }
                                        Text { text: tr("empty_history"); color: BeeTheme.accent; font { bold: true; pixelSize: 14; letterSpacing: 0.6 } Layout.alignment: Qt.AlignHCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                                        Text { text: tr("empty_history_desc"); color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4); font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                                    }
                                }

                                // Liste
                                ListView {
                                    visible: BeeBarState.historyModel.length > 0
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    clip: true; spacing: 8
                                    model: BeeBarState.historyModel

                                    delegate: Rectangle {
                                        width: ListView.view ? ListView.view.width : 0
                                        height: 72; radius: 12; clip: true
                                        color: BeeTheme.glassBg
                                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15); border.width: 1
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            shadowEnabled: true
                                            shadowColor: Qt.rgba(0, 0, 0, BeeTheme.mode === "HoneyDark" ? 0.3 : 0.08)
                                            shadowBlur: 0.4; shadowVerticalOffset: 2
                                        }
                                        Rectangle {
                                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                            width: 3; radius: 2; color: BeeTheme.accent; opacity: 0.7
                                        }
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 10; anchors.topMargin: 10; anchors.bottomMargin: 10; spacing: 10
                                            Rectangle {
                                                width: 36; height: 36; radius: 18
                                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                                                Text { 
                                                    visible: modelData && modelData.icon && modelData.icon.length <= 4
                                                    text: (modelData && modelData.icon) || ""
                                                    font.pixelSize: 18; anchors.centerIn: parent 
                                                }
                                                Image { 
                                                    visible: modelData && modelData.icon && modelData.icon.length > 4
                                                    anchors.fill: parent; anchors.margins: 7
                                                    source: (modelData && modelData.icon) ? (modelData.icon.startsWith("/") ? "file://" + modelData.icon : "image://icon/" + modelData.icon) : ""
                                                    fillMode: Image.PreserveAspectFit; asynchronous: true 
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                RowLayout {
                                                    Text { 
                                                        text: (modelData && modelData.title) || ""
                                                        color: BeeTheme.textPrimary; font { bold: true; pixelSize: 12 } 
                                                        Layout.fillWidth: true; elide: Text.ElideRight 
                                                    }
                                                    Text { 
                                                        text: (modelData && modelData.timestamp) || ""
                                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40); font.pixelSize: 9 
                                                    }
                                                }
                                                Text { 
                                                    text: (modelData && modelData.body) || ""
                                                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.65); font.pixelSize: 11; 
                                                    Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 1 
                                                }
                                            }
                                            Text {
                                                id: delBtn; text: "✕"
                                                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.25); font.pixelSize: 12
                                                MouseArea {
                                                    anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                    onEntered: delBtn.color = Qt.rgba(1.0, 0.4, 0.4, 0.8)
                                                    onExited:  delBtn.color = Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.25)
                                                    onClicked: BeeBarState.removeNotification(index)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Footer Historique ─────────────────
                        Item {
                            Layout.fillWidth: true; height: 52

                            Rectangle { anchors.top: parent.top; height: 1; anchors.left: parent.left; anchors.right: parent.right; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10) }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 20; rightMargin: 16 }
                                spacing: 10
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    visible: BeeBarState.historyModel.length > 0
                                    height: 30; radius: 15; width: clearHistLbl.implicitWidth + 24
                                    color: Qt.rgba(1.0, 0.3, 0.3, 0.12)
                                    border.color: Qt.rgba(1.0, 0.3, 0.3, 0.40); border.width: 1
                                    Text { id: clearHistLbl; anchors.centerIn: parent; text: tr("clear_history_button"); color: Qt.rgba(1.0, 0.45, 0.45, 0.95); font { pixelSize: 11; bold: true } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: BeeBarState.clearNotificationHistory() }
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════
                // PANNEAU 3 : PRÉSETS 🎯  (Alvéoles Presets)
                // ═══════════════════════════════════════════════════════
                Item {
                    id: panelPresets
                    anchors.fill: parent
                    visible: beeStudio.activeCategory === 4

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 0
                        spacing: 0

                        // ── Header ──────────────────────────
                        Item {
                            Layout.fillWidth: true; height: 60
                            RowLayout {
                                anchors { fill: parent; leftMargin: 22; rightMargin: 20 } spacing: 12
                                Text { text: "🎯"; font.pixelSize: 24 }
                                ColumnLayout {
                                    spacing: 1
                                    Text {
                                        text: BeePresets.tr("title")
                                        color: BeeTheme.accent
                                        font { bold: true; pixelSize: 17; letterSpacing: 0.8 }
                                        Behavior on color { ColorAnimation { duration: 600 } }
                                    }
                                    Text {
                                        text: BeePresets.tr("current_grid")
                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                                        font.pixelSize: 10
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }

                        Rectangle {
                            height: 1; Layout.fillWidth: true
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.1; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) }
                                GradientStop { position: 0.9; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // ── Preset cards ──────────────────────
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true

                            Flickable {
                                anchors.fill: parent
                                contentHeight: presetsContent.implicitHeight + 40
                                clip: true
                                ScrollBar.vertical: ScrollBar {
                                    width: 4; policy: ScrollBar.AsNeeded
                                    contentItem: Rectangle { radius: 2; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2) }
                                }

                                ColumnLayout {
                                    id: presetsContent
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                                    spacing: 16

                                    // ── Saved presets ──
                                    Text {
                                        text: (BeeConfig.tr && BeeConfig.tr.presets) ? BeeConfig.tr.presets.saved_presets || "Saved Presets" : "Saved Presets"
                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                                        font { pixelSize: 10; bold: true; letterSpacing: 1.5 }
                                    }

                                    // Preset grid
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 14

                                        Repeater {
                                            model: BeePresets.presets

                                            delegate: Rectangle {
                                                width: 180; height: 200
                                                radius: 14
                                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                                border.width: 1
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                                property bool hovered: false
                                                property bool isDefault: (modelData.name === "Travail" || modelData.name === "Gaming" || modelData.name === "Weekend")

                                                Rectangle {
                                                    id: presetHoverOverlay
                                                    anchors.fill: parent
                                                    radius: parent.radius
                                                    color: parent.hovered ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10) : "transparent"
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }

                                                ColumnLayout {
                                                    anchors { fill: parent; margins: 14; topMargin: 16 }
                                                    spacing: 6

                                                    // Preset icon + name
                                                    RowLayout {
                                                        spacing: 8
                                                        Text {
                                                            text: modelData.icon || "🍯"
                                                            font.pixelSize: 24
                                                        }
                                                        Text {
                                                            text: modelData.name
                                                            color: BeeTheme.accent
                                                            font { bold: true; pixelSize: 14 }
                                                            Behavior on color { ColorAnimation { duration: 600 } }
                                                        }
                                                        Item { Layout.fillWidth: true }
                                                        // Delete button (not for defaults)
                                                        Text {
                                                            visible: !parent.parent.parent.isDefault
                                                            text: "✕"
                                                            font.pixelSize: 10
                                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.30)
                                                            MouseArea {
                                                                anchors.fill: parent; anchors.margins: -6
                                                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                                onEntered: parent.color = Qt.rgba(1.0, 0.4, 0.4, 0.8)
                                                                onExited: parent.color = Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.30)
                                                                onClicked: BeePresets.deletePreset(modelData.name)
                                                            }
                                                        }
                                                    }

                                                    // Mini cell preview (4x2 grid)
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 90
                                                        radius: 8
                                                        color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.4)

                                                        Grid {
                                                            anchors { fill: parent; margins: 6 }
                                                            columns: 4
                                                            spacing: 3

                                                            Repeater {
                                                                model: modelData.cells.slice(0, 8)

                                                                delegate: Rectangle {
                                                                    width: 36; height: 36
                                                                    radius: 6
                                                                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                                                                    Text {
                                                                        text: modelData.icon || "📦"
                                                                        font.pixelSize: 14
                                                                        anchors.centerIn: parent
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // Cell count
                                                    Text {
                                                        text: modelData.cells.length + " alvéoles"
                                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.35)
                                                        font.pixelSize: 9
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                    onEntered: parent.hovered = true
                                                    onExited: parent.hovered = false
                                                    onClicked: BeePresets.applyPreset(modelData.name)
                                                }
                                            }
                                        }
                                    }

                                    // ── Save current as preset ──
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                                    }

                                    Text {
                                        text: (BeeConfig.tr && BeeConfig.tr.presets) ? BeeConfig.tr.presets.save_current || "Save Current Layout" : "Save Current Layout"
                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                                        font { pixelSize: 10; bold: true; letterSpacing: 1.5 }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        TextField {
                                            id: presetNameField
                                            Layout.fillWidth: true
                                            height: 36
                                            placeholderText: BeePresets.tr("default_name")
                                            color: BeeTheme.textPrimary
                                            font.pixelSize: 12
                                            leftPadding: 10; rightPadding: 10
                                            background: Rectangle {
                                                radius: 7
                                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.07)
                                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, presetNameField.activeFocus ? 0.5 : 0.15)
                                                border.width: 1
                                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                            }
                                            onTextChanged: beeStudio.presetNewName = text
                                        }

                                        // Icon picker (simple emoji selector)
                                        Rectangle {
                                            width: 36; height: 36; radius: 7
                                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.07)
                                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                            border.width: 1

                                            Text {
                                                id: presetIconDisplay
                                                text: beeStudio.presetNewIcon
                                                font.pixelSize: 18
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: presetIconMenu.open()
                                            }

                                            Popup {
                                                id: presetIconMenu
                                                x: parent.width + 4
                                                y: -(contentHeight / 2)
                                                width: 200; padding: 10
                                                modal: false; focus: true
                                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                                background: Rectangle {
                                                    color: BeeTheme.mode === "HoneyDark" ? Qt.rgba(0.08, 0.08, 0.12, 0.97) : Qt.rgba(0.97, 0.95, 0.90, 0.97)
                                                    radius: 12
                                                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                                                    border.width: 1
                                                }
                                                contentItem: Flow {
                                                    spacing: 6
                                                    Repeater {
                                                        model: ["💼", "🎮", "🌿", "🍯", "🏠", "☕", "🎵", "📷", "✈️", "🏋️", "📚", "💻", "🎬", "🛒", "🔧", "🎯"]
                                                        delegate: Text {
                                                            text: modelData
                                                            font.pixelSize: 20
                                                            MouseArea {
                                                                anchors.fill: parent; anchors.margins: -4
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: { beeStudio.presetNewIcon = modelData; presetIconMenu.close() }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 120; height: 36; radius: 10
                                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.16)
                                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.40)
                                            border.width: 1
                                            Text {
                                                text: BeePresets.tr("save")
                                                color: BeeTheme.accent
                                                font { pixelSize: 12; bold: true }
                                                anchors.centerIn: parent
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var name = presetNameField.text.trim()
                                                    if (name.length > 0) {
                                                        BeePresets.saveCurrentAsPreset(name, beeStudio.presetNewIcon)
                                                        presetNameField.text = ""
                                                        beeStudio.presetNewIcon = "🍯"
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ── Module Library ──
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                                    }

                                    Text {
                                        text: BeePresets.tr("module_library")
                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                                        font { pixelSize: 10; bold: true; letterSpacing: 1.5 }
                                    }

                                    // Module library grid
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Repeater {
                                            model: BeePresets.moduleLibrary

                                            delegate: Rectangle {
                                                width: 100; height: 56
                                                radius: 8
                                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
                                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                                                border.width: 1

                                                property bool libHovered: false

                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 2
                                                    Text {
                                                        text: modelData.icon
                                                        font.pixelSize: 18
                                                        Layout.alignment: Qt.AlignHCenter
                                                    }
                                                    Text {
                                                        text: modelData.title
                                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, parent.parent.libHovered ? 0.9 : 0.5)
                                                        font.pixelSize: 9
                                                        Layout.alignment: Qt.AlignHCenter
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onEntered: parent.libHovered = true
                                                    onExited: parent.libHovered = false
                                                    onClicked: {
                                                        // Add this module to the first empty slot
                                                        if (BeeConfig.cells.count < 8) {
                                                            BeeConfig.cells.append({
                                                                icon: modelData.icon,
                                                                title: modelData.title,
                                                                subtitle: modelData.subtitle,
                                                                detail: modelData.detail,
                                                                action: modelData.action,
                                                                highlighted: modelData.highlighted,
                                                                customizable: modelData.customizable !== false,
                                                                color: ""
                                                            })
                                                            BeeConfig.cellsRevision++
                                                            BeeConfig.saveConfig()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item { height: 20 }  // bottom padding
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
