import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDash.qml — Tableau de bord Maya (Bee-Hive OS) 🐝
// v0.6 : BeeVibe — Visualiseur audio intégré aux alvéoles (Phase 3)
//        Subtle equalizer bars, reactive to system audio
// v0.5 : BeeMotion — Effet de parallaxe 3D
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: mayaDash
    anchors.fill: parent
    color: "transparent"

    // ─── Visibilité animée (fade + scale) ─────────────────────
    property bool dashShown: false
    visible: true
    enabled: dashShown
    opacity: dashShown ? 1.0 : 0.0
    property real dashScale: dashShown ? 1.0 : 0.96

    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    Behavior on dashScale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // ─── Sons : ouverture / fermeture MayaDash ────────────────
    // onDashShownChanged: BeeSound.playEvent(dashShown ? "dash.open" : "dash.close", {}) (géré par shell.qml)

    // ─── Signaux externes ─────────────────────────────────────
    signal openSettings()
    signal openStudio()
    
    // BeeNotes dialog
    property bool notesDialogVisible: false
    
    function openNotesDialog() {
        notesDialogVisible = true
        BeeSound.playEvent("dash.open", {})
    }
    
    function closeNotesDialog() {
        notesDialogVisible = false
        BeeSound.playEvent("dash.close", {})
    }

    function resolveCellData(slot) {
        var _rev = BeeConfig.cellsRevision
        if (BeeConfig.cells.count > slot) return BeeConfig.cells.get(slot)

        var registered = BeeModuleRegistry.mayaDashCellAt(slot)
        if (!registered || registered.enabled === false) return null

        return {
            icon: registered.icon || "🐝",
            title: registered.title || ("Module " + slot),
            subtitle: registered.subtitle || "",
            detail: registered.detail || "",
            action: registered.action || "none",
            highlighted: registered.highlighted === true,
            customizable: false
        }
    }

    // ─── Dispatcher d'actions ─────────────────────────────────
    function handleCellAction(action) {
        if (!action || action === "none") return
        
        // toggle:settings → Ouvre BeeSettings
        if (action === "toggle:settings") {
            mayaDash.openSettings()
            return
        }
        
        // toggle:studio → Ouvre BeeStudio
        if (action === "toggle:studio") {
            mayaDash.openStudio()
            return
        }
        
        // app:<command> → Lance une application
        if (action.startsWith("app:")) {
            var cmd = action.substring(4).trim()
            if (!cmd) return
            
            // Special case: app:notes opens BeeNotes dialog
            if (cmd === "notes") {
                openNotesDialog()
                return
            }
            
            Qt.createQmlObject(
                'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "' + cmd.replace(/"/g, '\\"') + ' & disown"] }',
                mayaDash, "cellLaunch"
            )
            return
        }
        
        // url:<url> → Ouvre une URL dans le navigateur
        if (action.startsWith("url:")) {
            var url = action.substring(4).trim()
            if (!url) return
            Qt.createQmlObject(
                'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "xdg-open \'' + url + '\' ; sleep 0.5 && hyprctl dispatch focuswindow class:zen"] }',
                mayaDash, "cellUrl"
            )
            return
        }
        
        console.warn("MayaDash: Action non reconnue →", action)
    }

    // ═══════════════════════════════════════════════════════════
    // BEEMOTION — Parallaxe 3D
    // ═══════════════════════════════════════════════════════════

    // ─── BeeVibe ───────────────────────────────────────────────
    property bool beeVibeEnabled: false

    BeeVibe {
        id: beeVibe
        active: mayaDash.beeVibeEnabled
    }

    // Activer/désactiver l'effet (câblé depuis BeeSettings)
    property bool beeMotionEnabled: true

    // ─── Fond avec backdrop flou sombre ───────────────────────
    Rectangle {
        anchors.fill: parent
        color: BeeTheme.backdropBg

        Behavior on color { ColorAnimation { duration: 800 } }

        // ─── BeeMotion 2.0 integration (depth-layered parallax) ──────
        BeeMotion2D {
            id: mayaMotion
            anchors.fill: parent
            motionEnabled: mayaDash.beeMotionEnabled
            dashShown: mayaDash.dashShown
        }

        // Particules hexagonales flottantes — couche profonde (parallaxe amplifiée)
        // Désactivé car remplacé par BeeMotion2D
        // Repeater { ... }

    // ═══════════════════════════════════════════════════════════
    // COMPOSANT HEXAGONE (réutilisable, thème-aware)
    // ═══════════════════════════════════════════════════════════
    component HexCell: Item {
        id: hexCell
        width: 220; height: 250

        // ─── Data from BeeConfig ───────────────────────────────
        property int    cellIndex:     0
        // BeeConfig.cellsRevision est évalué en premier (opérateur virgule) pour
        // créer une dépendance réactive — ListModel.get() seul ne suffit pas.
        property var    cellData:      mayaDash.resolveCellData(cellIndex)

        property string icon:          cellData ? cellData.icon          : "🐝"
        property string title:         cellData ? cellData.title         : "Module"
        property string subtitle:      cellData ? cellData.subtitle      : ""
        property string detail:        cellData ? cellData.detail        : ""
        property bool   isHighlighted: cellData ? cellData.highlighted   : false
        property real   glowIntensity: isHighlighted ? 0.8 : 0.3

            // Détection de la cellule Calendar pour afficher le compteur live
            property bool isCalendarCell: cellData && (cellData.icon === "📅" || cellData.title === "Calendar" || cellData.title === "Calendrier")
            
            // Texte de détail dynamique pour la cellule Calendar
            property string dynamicDetail: {
                if (hexCell.isCalendarCell) {
                    var count = BeeConfig.liveSyncCount;
                    var lang = BeeConfig.uiLang || "en";
                    if (count > 0) {
                        if (lang === "fr") {
                            return count + (count > 1 ? " événements" : " événement");
                        } else {
                            return count + (count > 1 ? " upcoming events" : " upcoming event");
                        }
                    } else {
                        if (BeeConfig.tr && BeeConfig.tr.cells && BeeConfig.tr.cells.no_events) {
                            return BeeConfig.tr.cells.no_events;
                        }
                        return (lang === "fr") ? "Aucun événement à venir" : "No upcoming events";
                    }
                }
                return cellData ? cellData.detail : "";
            }

            // Réagir aux changements de liveSyncCount pour mise à jour immédiate
            Connections {
                target: BeeConfig
                function onLiveSyncCountChanged() {
                    // Force la réévaluation de dynamicDetail
                    hexCell.dynamicDetail = hexCell.dynamicDetail;
                }
            }

        // ─── BeeVibe: audio value for this cell ────────────────
        property real vibeValue: beeVibe.barValues.length > cellIndex
                                 ? beeVibe.barValues[cellIndex] : 0.0

        // ─── Optimized repaint logic ────────────────────────────
        // Désactive les repaints automatiques pendant les transitions de thème
        // et utilise un Timer pour regrouper les changements
        property bool _inTransition: false

        onIsHighlightedChanged: {
            if (!_inTransition) hexCanvas.requestPaint()
        }

        // ─── Repaint Canvas quand le thème change (via timer pour éviter la surcharge) ─
        Connections {
            target: BeeTheme
            function onModeChanged() {
                hexCanvas.requestPaint()
            }
            function on_ProgressChanged() {
                // Lors d'une transition, on n'utilise pas le throttle
                // car le Canvas est déjà inefficace pendant la transition
                hexCanvas.requestPaint()
            }
        }

        // ─── Hexagone Shape (Canvas) ──────────────────────────
        Canvas {
            id: hexCanvas
            anchors.fill: parent
            antialiasing: true
            renderStrategy: Canvas.Immediate  // Qt 6 optimisation

            onPaint: {
                var ctx = getContext("2d")
                if (!ctx) return

                var cx = width / 2
                var cy = height / 2
                var r  = Math.min(width, height) / 2 - 4

                // Tracé hexagone (flat-top)
                ctx.beginPath()
                for (var i = 0; i < 6; i++) {
                    var angle = (Math.PI / 3) * i - Math.PI / 6
                    var px = cx + r * Math.cos(angle)
                    var py = cy + r * Math.sin(angle)
                    if (i === 0) ctx.moveTo(px, py)
                    else         ctx.lineTo(px, py)
                }
                ctx.closePath()

                // Glassmorphism fill — translucide et élégant dans les deux modes
                if (hexCell.isHighlighted) {
                    ctx.fillStyle = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 
                        BeeTheme.mode === "HoneyDark" ? 0.12 : 0.22)
                } else {
                    ctx.fillStyle = BeeTheme.mode === "HoneyDark"
                        ? "rgba(18, 18, 20, 0.88)"         // Gris anthracite foncé opaque
                        : "rgba(255, 255, 255, 0.55)"      // Blanc nacré translucide (glassmorphism)
                }
                ctx.fill()

                // Bordure principale
                ctx.strokeStyle = hexCell.isHighlighted
                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.7)
                    : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b,
                        BeeTheme.mode === "HoneyDark" ? 0.5 : 0.35)
                ctx.lineWidth = hexCell.isHighlighted ? 2 : 1.5
                ctx.stroke()

                // Bordure intérieure (glassmorphism layer)
                ctx.beginPath()
                var rInner = r - 3
                for (var j = 0; j < 6; j++) {
                    var a2  = (Math.PI / 3) * j - Math.PI / 6
                    var px2 = cx + rInner * Math.cos(a2)
                    var py2 = cy + rInner * Math.sin(a2)
                    if (j === 0) ctx.moveTo(px2, py2)
                    else         ctx.lineTo(px2, py2)
                }
                ctx.closePath()
                // Bordure intérieure : reflet lumineux adaptatif
                ctx.strokeStyle = BeeTheme.mode === "HoneyDark" 
                    ? "rgba(255, 215, 0, 0.15)"     // Reflet doré léger (Dark)
                    : "rgba(255, 200, 80, 0.25)"    // Reflet miel chaud (Light)
                ctx.lineWidth = 1.5
                ctx.stroke()
            }
        }

        // ─── Lueur (glow) ─────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.6; height: parent.height * 0.6
            radius: width / 2; color: "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: parent.width; height: parent.height
                radius: width / 2
                color: BeeTheme.accent
                opacity: hexCell.glowIntensity * 0.08
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        // ─── Contenu textuel ──────────────────────────────────
        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width * 0.65

            Text {
                text: hexCell.icon
                font.pixelSize: 42
                anchors.horizontalCenter: parent.horizontalCenter
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0; to: -3; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: -3; to: 0; duration: 2000; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: hexCell.title
                color: hexCell.isHighlighted 
                    ? BeeTheme.accent
                    : BeeTheme.textPrimary
                font { bold: true; pixelSize: 14; letterSpacing: 0.5 }
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on color { ColorAnimation { duration: 600 } }
            }

            Text {
                text: hexCell.subtitle
                color: hexCell.isHighlighted 
                    ? BeeTheme.accent
                    : BeeTheme.textSecondary
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                Behavior on color { ColorAnimation { duration: 600 } }
            }

            Text {
                text: hexCell.isCalendarCell ? hexCell.dynamicDetail : hexCell.detail
                color: hexCell.isHighlighted
                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.7)
                    : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
            }
        }

        // ─── BeeVibe: equalizer bars at cell bottom ────────────
        // 5 barres rectangulaires, hauteur animée selon vibeValue
        // Chaque barre a un facteur de phase fixe pour un rendu
        // "spectre" sans calcul FFT supplémentaire côté QML.
        Item {
            id: _vibeEq
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            width: 35   // 5 × 3px + 4 × 5px = 35px
            height: 34
            opacity: mayaDash.beeVibeEnabled ? 0.62 : 0.0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutSine } }

            Repeater {
                model: 5
                Item {
                    // Facteurs de hauteur max par barre (0=centre, ailes plus basses)
                    property real _phaseFactor: [0.65, 0.90, 1.00, 0.90, 0.65][index]
                    property real _barH: 2 + hexCell.vibeValue * 30 * _phaseFactor
                    Behavior on _barH { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    x: index * 8            // espacement 8px entre barres
                    anchors.bottom: parent.bottom
                    width: 3
                    height: _barH

                    Rectangle {
                        anchors.fill: parent
                        radius: 1.5
                        color: BeeTheme.accent
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }
                }
            }
        }

        // ─── Hover interactif + Click dispatcher ──────────────
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered:  { hexScale.xScale = 1.04; hexScale.yScale = 1.04; hexCell.glowIntensity = 0.9 }
            onExited:  { hexScale.xScale = 1.0;  hexScale.yScale = 1.0;  hexCell.glowIntensity = hexCell.isHighlighted ? 0.8 : 0.3 }
            onClicked: {
                BeeSound.playEvent("ui.cell.click", {})
                mayaDash.handleCellAction(cellData ? cellData.action : "none")
            }
        }

        transform: Scale {
            id: hexScale
            origin.x: hexCell.width / 2; origin.y: hexCell.height / 2
            Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
    }

    // ═══════════════════════════════════════════════════════════
    // LAYOUT — Grille en nid d'abeille (2 + 3 + 3)
    // BeeMotion : inclinaison 3D selon la position de la souris
    // ═══════════════════════════════════════════════════════════
    Column {
        id: hexGrid
        anchors.centerIn: parent
        spacing: -30

        // On applique le scale global ici car Rectangle n'a pas de propriété scale
        scale: mayaDash.dashScale

        // ─── Titre du dashboard ───────────────────────────────
        Text {
            text: BeeConfig.dashTitle
            color: BeeTheme.accent
            font { pixelSize: 22; bold: true; letterSpacing: 2 }
            anchors.horizontalCenter: parent.horizontalCenter
            Behavior on color { ColorAnimation { duration: 800 } }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.7; duration: 3000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 3000; easing.type: Easing.InOutSine }
            }
        }

        Item { width: 1; height: 50 }

        // ─── Rangée 1 : 2 alvéoles (indices 0–1) ─────────────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 0 }
            HexCell { cellIndex: 1 }
        }

        // ─── Rangée 2 : 3 alvéoles décalées (indices 2–4) ────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 2 }
            HexCell { cellIndex: 3 }
            HexCell { cellIndex: 4 }
        }

        // ─── Rangée 3 : 3 alvéoles (indices 5–7) ─────────────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 5 }
            HexCell { cellIndex: 6 }
            HexCell { cellIndex: 7 }
        }
    }

    // ─── Ligne décorative en bas ──────────────────────────────
    Rectangle {
        width: parent.width * 0.4; height: 1
        anchors.bottom: parent.bottom; anchors.bottomMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ─── Label version ────────────────────────────────────────
    Text {
        text: "Bee-Hive OS v0.9.0 · BeeMotion2D · BeeVibe 🐝"
        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.15)
        font { pixelSize: 10; letterSpacing: 1 }
        anchors.bottom: parent.bottom; anchors.bottomMargin: 15
        anchors.horizontalCenter: parent.horizontalCenter
    }
    
    // ─── BeeNotes Dialog Overlay (Shield) ────────────────────
    Item {
        id: notesOverlay
        anchors.fill: parent
        visible: notesDialogVisible
        z: 99

        // Fond qui ferme le dialog quand on clique DEHORS du Rectangle
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Vérifie si le clic est en dehors du dialog
                    var dialogPos = notesDialog.mapToItem(notesOverlay, 0, 0)
                    var inDialog = mouse.x >= dialogPos.x && mouse.x <= dialogPos.x + notesDialog.width &&
                                   mouse.y >= dialogPos.y && mouse.y <= dialogPos.y + notesDialog.height
                    if (!inDialog) {
                        closeNotesDialog()
                    }
                }
            }
        }
    }

    // ─── BeeNotes Dialog ──────────────────────────────────────
    Rectangle {
        id: notesDialog
        width: 360
        height: 480
        anchors.centerIn: parent
        radius: 16
        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.95)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
        border.width: 1
        visible: notesDialogVisible
        opacity: notesDialogVisible ? 0.95 : 0
        scale: notesDialogVisible ? 1 : 0.9
        z: 100
        
        layer.enabled: true
        
        // Pas besoin de MouseArea ici - l'overlay vérifie si on clique hors du dialog
        
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        
        // Header
        Rectangle {
            width: parent.width
            height: 50
            color: "transparent"
            
            Text {
                text: "📝 Quick Notes"
                font { bold: true; pixelSize: 18 }
                color: BeeTheme.textPrimary
                anchors.centerIn: parent
            }
            
            // Close button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Qt.rgba(1, 0.3, 0.3, 0.1)
                border.color: "#ff4444"
                border.width: 1
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 16
                
                Text {
                    text: "×"
                    font { bold: true; pixelSize: 20 }
                    color: "#ff4444"
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: closeNotesDialog()
                }
            }
        }
        
        // BeeNotes component
        BeeNotes {
            anchors.top: parent.top
            anchors.topMargin: 60
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
