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

    // ─── Catégorie active ────────────────────────────────────────
    property int activeCategory: 0   // 0=Alvéoles 1=Fonds d'écran 2=Historique

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
                Text { text: "✓"; anchors.centerIn: parent; color: "#111"; font { pixelSize: 10; bold: true } }
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

    // ─── Open/Close ──────────────────────────────────────────────
    Component.onCompleted: { backdropIn.start(); openAnim.start() }

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

        // Bouton fermeture (Top Right)
        Rectangle {
            id: closeRect
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
                                    text: "BeeStudio"
                                    color: BeeTheme.accent
                                    font { bold: true; pixelSize: 18; letterSpacing: 1.2 }
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 600 } }
                                }
                            }
                            Text {
                                text: "Control Center  v2.1"
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
                        text: "CATEGORIES"
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.32)
                        font { pixelSize: 8; bold: true; letterSpacing: 2.2 }
                        Layout.leftMargin: 20
                    }

                    Item { height: 8 }

                    // ── Catégories ────────────────────────────
                    ListModel {
                        id: categoryModel
                        ListElement { catIcon: "🍯"; catLabel: "Cells";      catSub: "Dashboard cells" }
                        ListElement { catIcon: "🖼";  catLabel: "Wallpapers"; catSub: "Library \"Bibliothèque & rotation\" rotation" }
                        ListElement { catIcon: "🔔"; catLabel: "Historique";     catSub: "Journal des notifications" }
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
                                        text: catLabel
                                        color: isActive ? BeeTheme.accent : BeeTheme.textPrimary
                                        font { pixelSize: 13; bold: isActive }
                                        Layout.fillWidth: true; elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        text: catSub
                                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.36)
                                        font.pixelSize: 9; Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onEntered: parent.hovered = true
                                onExited:  parent.hovered = false
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
                                    text: "BeeStudio v2.1 🍯"
                                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.22)
                                    font { pixelSize: 9; letterSpacing: 0.5 }
                                }
                                Text {
                                    visible: beeStudio._saveDirty
                                    text: "● unsaved"
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
                                        text: "Cells"
                                        color: BeeTheme.accent
                                        font { bold: true; pixelSize: 17; letterSpacing: 0.8 }
                                        Behavior on color { ColorAnimation { duration: 600 } }
                                    }
                                    Text {
                                        text: "Dashboard cell editor"
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
                                                text: "CELLS"
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
                                                                text: "🔒 protected"; font.pixelSize: 8
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
                                                text: "Select a cell"
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
                                                            text: beeStudio.editCustomizable ? "✦  Modifiable" : "🔒  Lecture seule"
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

                                                FieldLabel { labelText: "ICON" }
                                                BeeField { id: iconField; placeholderText: "Emoji (ex: 🐝)"; onTextEdited: { if (!beeStudio._loading) beeStudio.editIcon = text } }

                                                FieldLabel { labelText: "TITRE" }
                                                BeeField { id: titleField; placeholderText: "Cell name"; onTextEdited: { if (!beeStudio._loading) beeStudio.editTitle = text } }

                                                FieldLabel { labelText: "SOUS-TITRE" }
                                                BeeField { id: subtitleField; placeholderText: "Category or status"; onTextEdited: { if (!beeStudio._loading) beeStudio.editSubtitle = text } }

                                                FieldLabel { labelText: "DETAIL" }
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
                                                            text: "Texte secondaire (\\n pour nouvelle ligne)"
                                                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                                                            font.pixelSize: 11; anchors.fill: parent
                                                        }
                                                    }
                                                }

                                                FieldLabel { labelText: "ACTION" }
                                                BeeField { id: actionField; placeholderText: "none | app:nom | toggle:settings"; onTextEdited: { if (!beeStudio._loading) beeStudio.editAction = text } }

                                                FieldLabel { labelText: "WALLPAPER 🍯 (NECTAR SYNC)" }
                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 8
                                                    WallCard { width: 110; height: 80; src: "../assets/wallpaper.png";       label: "Mysterious";  mode: "HoneyDark" }
                                                    WallCard { width: 110; height: 80; src: "../assets/wallpaper_dark_bee.png"; label: "Dark Bee"; mode: "HoneyDark" }
                                                    WallCard { width: 110; height: 80; src: "../assets/wallpaper_light_bee.png"; label: "Light Bee"; mode: "HoneyLight" }
                                                    WallCard { width: 110; height: 80; src: "../assets/wallpaper_light.png"; label: "Soft Light"; mode: "HoneyLight" }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 10
                                                    ColumnLayout {
                                                        spacing: 1; Layout.fillWidth: true
                                                        Text {
                                                            text: "Mise en valeur"; color: BeeTheme.textPrimary
                                                            font { pixelSize: 12; bold: true }
                                                            Behavior on color { ColorAnimation { duration: 600 } }
                                                        }
                                                        Text { text: "Highlighted border and title"; color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4); font.pixelSize: 9 }
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
                                                        text: beeStudio.editCustomizable ? "✦  Apply" : "🔒  Protected"
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
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 130; height: 30; radius: 15
                                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.40); border.width: 1
                                    Text { text: "💾  Sauvegarder"; color: BeeTheme.accent; font { pixelSize: 11; bold: true } anchors.centerIn: parent; Behavior on color { ColorAnimation { duration: 600 } } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { BeeConfig.saveConfig(); beeStudio._saveDirty = false } }
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
                    visible: beeStudio.activeCategory === 1

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
                                    Text { text: "Wallpapers"; color: BeeTheme.accent; font { bold: true; pixelSize: 17; letterSpacing: 0.8 } Behavior on color { ColorAnimation { duration: 600 } } }
                                    Text { text: "Cliquez sur une image pour l'appliquer"; color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40); font.pixelSize: 10 }
                                }
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 0.1; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) } GradientStop { position: 0.9; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.20) } GradientStop { position: 1.0; color: "transparent" } } }

                        // ── Barre dossier ─────────────────────
                        Item {
                            Layout.fillWidth: true; height: 44
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
                                            text: "~/Pictures/Wallpapers"
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
                                            text: "BEE-HIVE ORIGINALS 🍯"
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
                                            text: "MY LIBRARY 🖼"
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
                    visible: beeStudio.activeCategory === 2

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
                                    Text { text: "Historique"; color: BeeTheme.accent; font { bold: true; pixelSize: 17; letterSpacing: 0.8 } Behavior on color { ColorAnimation { duration: 600 } } }
                                    Text { text: "Journal des notifications"; color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40); font.pixelSize: 10 }
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
                                    text: BeeBarState.notificationHistory.length > 0
                                        ? BeeBarState.notificationHistory.length + " notification" + (BeeBarState.notificationHistory.length > 1 ? "s" : "")
                                        : "Aucune notification"
                                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.45)
                                    font { pixelSize: 10; bold: true; letterSpacing: 1.5 }
                                }

                                // État vide
                                Item {
                                    visible: BeeBarState.notificationHistory.length === 0
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
                                        Text { text: "Aucune notification"; color: BeeTheme.accent; font { bold: true; pixelSize: 14; letterSpacing: 0.6 } Layout.alignment: Qt.AlignHCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                                        Text { text: "Notifications will appear\nhere over time."; color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.4); font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                                    }
                                }

                                // Liste
                                ListView {
                                    visible: BeeBarState.notificationHistory.length > 0
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    clip: true; spacing: 8
                                    model: BeeBarState.notificationHistory

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
                                    visible: BeeBarState.notificationHistory.length > 0
                                    height: 30; radius: 15; width: clearHistLbl.implicitWidth + 24
                                    color: Qt.rgba(1.0, 0.3, 0.3, 0.12)
                                    border.color: Qt.rgba(1.0, 0.3, 0.3, 0.40); border.width: 1
                                    Text { id: clearHistLbl; anchors.centerIn: parent; text: "✕  Tout effacer"; color: Qt.rgba(1.0, 0.45, 0.45, 0.95); font { pixelSize: 11; bold: true } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: BeeBarState.clearNotificationHistory() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
