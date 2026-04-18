import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDash.qml — Tableau de bord Maya (Bee-Hive OS) 🐝
// v0.7 : BeeNetwork — Network monitor & speed test (detail:network action)
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
    // visible=true while animating out, then false to block mouse events through wallpaper
    visible: dashShown || opacity > 0.01
    opacity: dashShown ? 1.0 : 0.0
    property real dashScale: dashShown ? 1.0 : 0.96
    property bool interactive: dashShown  // replaces enabled to avoid QML override warning

    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    Behavior on dashScale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // ─── Sons : ouverture / fermeture MayaDash ────────────────
    // onDashShownChanged: BeeSound.playEvent(dashShown ? "dash.open" : "dash.close", {}) (géré par shell.qml)

    // ─── Signaux externes ─────────────────────────────────────
    signal openSettings()
    signal openStudio()
    signal openNotes()

    // ─── Drag & Drop state ──────────────────────────────────────
    property int dragFromIndex: -1    // Cell being dragged
    property int dragOverIndex: -1    // Cell currently under the drop target
    property bool dragActive: false   // Whether a drag is in progress

    // ─── BeeNetwork instance ────────────────────────────────
    property bool networkDetailVisible: false

    BeeNetwork {
        id: beeNet
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
            
            // Special case: app:notes opens BeeNotes panel
            if (cmd === "notes") {
                mayaDash.openNotes()
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

        // detail:network → BeeNetwork detail panel
        if (action === "detail:network") {
            mayaDash.networkDetailVisible = !mayaDash.networkDetailVisible
            BeeSound.playEvent(mayaDash.networkDetailVisible ? "dash.open" : "dash.close")
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

        property string icon:          isNetworkCell ? beeNet.networkIcon : (cellData ? cellData.icon : "🐝")
        property string title:         cellData ? cellData.title         : "Module"
        property string subtitle:      isNetworkCell ? (beeNet.latency !== "— ms" ? beeNet.latency : (cellData ? cellData.subtitle : "")) : (cellData ? cellData.subtitle : "")
        property string detail:        cellData ? cellData.detail        : ""
        property bool   isHighlighted: cellData ? cellData.highlighted   : false
        property real   glowIntensity: isHighlighted ? 0.8 : 0.3

            // Détection de la cellule Calendar pour afficher le compteur live
            property bool isCalendarCell: cellData && (cellData.icon === "📅" || cellData.title === "Calendar" || cellData.title === "Calendrier")

            // Détection de la cellule Network pour afficher les stats live
            property bool isNetworkCell: cellData && (cellData.action === "detail:network" || cellData.icon === "🌐")

            // Texte de détail dynamique pour les cellules Calendar et Network
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
                if (hexCell.isNetworkCell) {
                    return beeNet.downloadRate + " / " + beeNet.uploadRate;
                }
                return cellData ? cellData.detail : "";
            }

            // Réagir aux changements de liveSyncCount et network stats pour mise à jour immédiate
            Connections {
                target: BeeConfig
                function onLiveSyncCountChanged() {
                    hexCell.dynamicDetail = hexCell.dynamicDetail;
                }
            }

            // Réagir aux changements de stats réseau
            Connections {
                target: beeNet
                function onDownloadRateChanged() {
                    if (hexCell.isNetworkCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
                }
                function onUploadRateChanged() {
                    if (hexCell.isNetworkCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
                }
                function onLatencyChanged() {
                    // Force subtitle re-evaluation for network cell
                    hexCell.subtitle = hexCell.subtitle;
                }
                function onNetworkIconChanged() {
                    // Force icon re-evaluation for network cell
                    hexCell.icon = hexCell.icon;
                }
            }

        // ─── BeeVibe: audio value for this cell ────────────────
        property real vibeValue: beeVibe.barValues.length > cellIndex
                                 ? beeVibe.barValues[cellIndex] : 0.0

        // ─── Propriétés réactives pour le Canvas ──────────────────
        // Utilisent BeeTheme._progress (0=Dark, 1=Light) pour interpoler
        // correctement pendant la transition animée Dark↔Light.
        //
        // IMPORTANT: Les cellules highlighted utilisent un fill DIFFÉRENT
        // en Light (blanc nacré translucide + bordure accent) car l'accent
        // couleur avec alpha donne du jaune moutarde sur fond clair.
        property color _cellFillColor: {
            var p = BeeTheme._progress
            if (hexCell.isHighlighted) {
                // Dark: accent très translucide (0.12)
                // Light: blanc nacré translucide (même base que normal, un peu plus opaque)
                Qt.rgba(
                    BeeTheme.accent.r * (1 - p) + (0.97 * p),
                    BeeTheme.accent.g * (1 - p) + (0.95 * p),
                    BeeTheme.accent.b * (1 - p) + (0.88 * p),
                    0.12 * (1 - p) + 0.65 * p
                )
            } else {
                // Dark: gris anthracite (0.07, 0.07, 0.08, 0.88)
                // Light: blanc nacré (1.0, 1.0, 1.0, 0.55)
                Qt.rgba(
                    0.07 + (1.0 - 0.07) * p,
                    0.07 + (1.0 - 0.07) * p,
                    0.08 + (1.0 - 0.08) * p,
                    0.88 + (0.55 - 0.88) * p
                )
            }
        }
        property color _cellBorderColor: hexCell.isHighlighted
            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.7)
            : Qt.rgba(BeeTheme.glassBorder.r, BeeTheme.glassBorder.g, BeeTheme.glassBorder.b,
                0.5 + (0.35 - 0.5) * BeeTheme._progress)
        property color _innerBorderColor: Qt.rgba(
            1.0,
            0.84 + (0.78 - 0.84) * BeeTheme._progress,
            0.0  + (0.31 - 0.0) * BeeTheme._progress,
            0.15 + (0.25 - 0.15) * BeeTheme._progress)
        property real _cellBorderWidth: hexCell.isHighlighted ? 2 : 1.5

        onIsHighlightedChanged: hexCanvas.requestPaint()
        on_CellFillColorChanged: hexCanvas.requestPaint()
        on_CellBorderColorChanged: hexCanvas.requestPaint()
        on_InnerBorderColorChanged: hexCanvas.requestPaint()
        on_CellBorderWidthChanged: hexCanvas.requestPaint()

        // Repaint pendant la transition animée du thème
        Connections {
            target: BeeTheme
            function on_ProgressChanged() {
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

                // VIDER le Canvas avant de redessiner (sinon l'ancien fill persiste)
                ctx.clearRect(0, 0, width, height)

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

                // Glassmorphism fill — propriétés réactives interpolées
                ctx.fillStyle = hexCell._cellFillColor.toString()
                ctx.fill()

                // Bordure principale
                ctx.strokeStyle = hexCell._cellBorderColor.toString()
                ctx.lineWidth = hexCell._cellBorderWidth
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
                ctx.strokeStyle = hexCell._innerBorderColor.toString()
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
                    ? Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b,
                        BeeTheme._progress < 0.5 ? 1.0 : 1.0)  // toujours lisible
                    : BeeTheme.textPrimary
                font { bold: true; pixelSize: 14; letterSpacing: 0.5 }
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on color { ColorAnimation { duration: 600 } }
            }

            Text {
                text: hexCell.subtitle
                color: hexCell.isHighlighted
                    ? BeeTheme.textSecondary
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
                    ? Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
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

        // ─── Drop zone highlight ─────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "transparent"
            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, mayaDash.dragActive && mayaDash.dragOverIndex === cellIndex ? 0.9 : 0.0)
            border.width: 3
            visible: mayaDash.dragActive && mayaDash.dragOverIndex === cellIndex
            Behavior on border.color { ColorAnimation { duration: 200 } }

            SequentialAnimation on border.width {
                loops: Animation.Infinite
                running: mayaDash.dragActive && mayaDash.dragOverIndex === cellIndex
                NumberAnimation { to: 4; duration: 400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 2; duration: 400; easing.type: Easing.InOutSine }
            }
        }

        // ─── Hover interactif + Click + Long-press Drag ──────
        MouseArea {
            id: hexMouseArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: mayaDash.dashShown
            cursorShape: mayaDash.dragActive ? (mayaDash.dragFromIndex === cellIndex ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor

            property int longPressTimer: 0
            property bool longPressed: false
            property point pressPos

            onPressed: (mouse) => {
                pressPos = Qt.point(mouse.x, mouse.y)
                longPressed = false
                longPressTimer = 0
                _longPressLoop.start()
            }
            onReleased: (mouse) => {
                _longPressLoop.stop()
                if (mayaDash.dragActive) {
                    if (mayaDash.dragOverIndex >= 0 && mayaDash.dragOverIndex !== mayaDash.dragFromIndex) {
                        // Complete the swap
                        BeePresets.swapCells(mayaDash.dragFromIndex, mayaDash.dragOverIndex)
                    }
                    // Cancel drag regardless (drop on self = cancel, valid drop = complete)
                    mayaDash.dragActive = false
                    mayaDash.dragFromIndex = -1
                    mayaDash.dragOverIndex = -1
                } else if (!longPressed) {
                    // Normal click
                    BeeSound.playEvent("ui.cell.click", {})
                    mayaDash.handleCellAction(cellData ? cellData.action : "none")
                }
                hexScale.xScale = 1.0
                hexScale.yScale = 1.0
                hexCell.glowIntensity = hexCell.isHighlighted ? 0.8 : 0.3
            }
            onCanceled: {
                _longPressLoop.stop()
                mayaDash.dragActive = false
                mayaDash.dragFromIndex = -1
                mayaDash.dragOverIndex = -1
            }

            onPositionChanged: (mouse) => {
                if (mayaDash.dragActive && mayaDash.dragFromIndex === cellIndex) {
                    // Determine which cell we're over based on mouse position relative to the grid
                    var globalPos = mapToItem(mayaDash, mouse.x, mouse.y)
                    var targetIdx = mayaDash.cellIndexAt(globalPos.x, globalPos.y)
                    mayaDash.dragOverIndex = (targetIdx >= 0 && targetIdx !== cellIndex) ? targetIdx : -1
                }
            }

            onEntered: {
                if (!mayaDash.dragActive) {
                    hexScale.xScale = 1.04
                    hexScale.yScale = 1.04
                    hexCell.glowIntensity = 0.9
                }
            }
            onExited: {
                if (!mayaDash.dragActive) {
                    hexScale.xScale = 1.0
                    hexScale.yScale = 1.0
                    hexCell.glowIntensity = hexCell.isHighlighted ? 0.8 : 0.3
                }
            }

            // Long-press detection via Timer
            Timer {
                id: _longPressLoop
                interval: 100
                repeat: true
                onTriggered: {
                    hexMouseArea.longPressTimer += 100
                    if (hexMouseArea.longPressTimer >= 500 && !hexMouseArea.longPressed) {
                        hexMouseArea.longPressed = true
                        // Activate drag mode
                        mayaDash.dragActive = true
                        mayaDash.dragFromIndex = cellIndex
                        mayaDash.dragOverIndex = -1
                        hexScale.xScale = 1.10
                        hexScale.yScale = 1.10
                        hexCell.glowIntensity = 1.0
                        BeeSound.playEvent("ui.cell.click", {})
                    }
                }
            }
        }

        // ─── Drag mode visual feedback ────────────────────────
        opacity: mayaDash.dragActive && mayaDash.dragFromIndex >= 0 && mayaDash.dragFromIndex !== cellIndex
            ? (mayaDash.dragOverIndex === cellIndex ? 0.7 : 0.45)
            : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        transform: Scale {
            id: hexScale
            origin.x: hexCell.width / 2; origin.y: hexCell.height / 2
            Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
    }

    // ─── Hit-test helper for drag & drop ────────────────────────
    function cellIndexAt(globalX, globalY) {
        // Map global coordinates to each HexCell and find which one contains the point
        for (var i = 0; i < 8; i++) {
            var cell = hexGrid.findCell(i)
            if (!cell) continue
            var cellPos = cell.mapFromItem(mayaDash, globalX, globalY)
            if (cellPos.x >= 0 && cellPos.x <= cell.width && cellPos.y >= 0 && cellPos.y <= cell.height) {
                return i
            }
        }
        return -1
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

        // Cell references for drag & drop hit-testing
        property var cellRefs: [null, null, null, null, null, null, null, null]

        function findCell(idx) {
            if (idx >= 0 && idx < 8) return cellRefs[idx]
            return null
        }

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
            HexCell { cellIndex: 0; Component.onCompleted: hexGrid.cellRefs[0] = this }
            HexCell { cellIndex: 1; Component.onCompleted: hexGrid.cellRefs[1] = this }
        }

        // ─── Rangée 2 : 3 alvéoles décalées (indices 2–4) ────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 2; Component.onCompleted: hexGrid.cellRefs[2] = this }
            HexCell { cellIndex: 3; Component.onCompleted: hexGrid.cellRefs[3] = this }
            HexCell { cellIndex: 4; Component.onCompleted: hexGrid.cellRefs[4] = this }
        }

        // ─── Rangée 3 : 3 alvéoles (indices 5–7) ─────────────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 5; Component.onCompleted: hexGrid.cellRefs[5] = this }
            HexCell { cellIndex: 6; Component.onCompleted: hexGrid.cellRefs[6] = this }
            HexCell { cellIndex: 7; Component.onCompleted: hexGrid.cellRefs[7] = this }
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
        text: "Bee-Hive OS v0.9.0 · BeeMotion2D · BeeVibe · BeeNetwork · DragReorder 🐝"
        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.15)
        font { pixelSize: 10; letterSpacing: 1 }
        anchors.bottom: parent.bottom; anchors.bottomMargin: 15
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // ═══════════════════════════════════════════════════════════
    // BeeNetwork — Détail réseau (overlay panel)
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        id: networkOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        visible: mayaDash.networkDetailVisible
        opacity: mayaDash.networkDetailVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                mayaDash.networkDetailVisible = false
                BeeSound.playEvent("dash.close")
            }
        }

        Rectangle {
            width: 420
            height: 520
            anchors.centerIn: parent
            color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.95)
            radius: 16
            border.color: BeeTheme.glassBorder
            border.width: 1.5
            Behavior on color { ColorAnimation { duration: 600 } }
            Behavior on border.color { ColorAnimation { duration: 600 } }

            MouseArea {
                anchors.fill: parent
                onClicked: mouse.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // ─── Header ──
                Row {
                    spacing: 10
                    Text {
                        text: beeNet.networkIcon
                        font.pixelSize: 28
                    }
                    Column {
                        spacing: 2
                        Text {
                            text: beeNet.ssid
                            color: BeeTheme.textPrimary
                            font { bold: true; pixelSize: 18 }
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: beeNet.localIp + " \u00b7 " + beeNet.latency
                            color: BeeTheme.textSecondary
                            font.pixelSize: 11
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // ─── Throughput chart ──
                Rectangle {
                    width: parent.width - 40
                    height: 110
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 8
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                    Behavior on color { ColorAnimation { duration: 600 } }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Text {
                            text: beeNet.tr("chart_label")
                            color: BeeTheme.textSecondary
                            font { pixelSize: 10; bold: true; letterSpacing: 1 }
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }

                        Canvas {
                            id: netChartCanvas
                            width: parent.width
                            height: parent.height - 28
                            antialiasing: true
                            renderStrategy: Canvas.Immediate

                            property var dlData: beeNet.dlHistory
                            property var ulData: beeNet.ulHistory

                            onDlDataChanged: requestPaint()
                            onUlDataChanged: requestPaint()

                            Connections {
                                target: BeeTheme
                                function on_ProgressChanged() { netChartCanvas.requestPaint() }
                            }

                            onPaint: {
                                var ctx = getContext("2d")
                                if (!ctx) return
                                ctx.clearRect(0, 0, width, height)

                                var maxVal = 1024
                                for (var i = 0; i < dlData.length; i++) {
                                    if (dlData[i] > maxVal) maxVal = dlData[i]
                                    if (ulData[i] > maxVal) maxVal = ulData[i]
                                }
                                maxVal *= 1.2

                                var w = width
                                var h = height
                                var step = w / (beeNet.chartMaxPoints - 1)

                                if (dlData.length > 1) {
                                    ctx.beginPath()
                                    ctx.strokeStyle = BeeTheme.accent.toString()
                                    ctx.lineWidth = 2
                                    for (var d = 0; d < dlData.length; d++) {
                                        var x = d * step
                                        var y = h - (dlData[d] / maxVal) * h
                                        if (d === 0) ctx.moveTo(x, y)
                                        else ctx.lineTo(x, y)
                                    }
                                    ctx.stroke()
                                    ctx.lineTo((dlData.length - 1) * step, h)
                                    ctx.lineTo(0, h)
                                    ctx.closePath()
                                    ctx.fillStyle = Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1).toString()
                                    ctx.fill()
                                }

                                if (ulData.length > 1) {
                                    ctx.beginPath()
                                    ctx.strokeStyle = Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.7).toString()
                                    ctx.lineWidth = 1.5
                                    ctx.setLineDash([4, 3])
                                    for (var u = 0; u < ulData.length; u++) {
                                        var ux = u * step
                                        var uy = h - (ulData[u] / maxVal) * h
                                        if (u === 0) ctx.moveTo(ux, uy)
                                        else ctx.lineTo(ux, uy)
                                    }
                                    ctx.stroke()
                                    ctx.setLineDash([])
                                }
                            }
                        }

                        Row {
                            spacing: 15
                            Text {
                                text: "\u25cf " + beeNet.tr("download") + " " + beeNet.downloadRate
                                color: BeeTheme.accent
                                font.pixelSize: 9
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: "--- " + beeNet.tr("upload") + " " + beeNet.uploadRate
                                color: BeeTheme.textSecondary
                                font.pixelSize: 9
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                        }
                    }
                }

                // ─── Network details grid ──
                Grid {
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 6

                    Row {
                        spacing: 6
                        Text { text: beeNet.tr("local_ip"); color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true; Behavior on color { ColorAnimation { duration: 600 } } }
                        Text { text: beeNet.localIp; color: BeeTheme.textPrimary; font.pixelSize: 10; font.family: "monospace"; elide: Text.ElideRight; Behavior on color { ColorAnimation { duration: 600 } } }
                    }
                    Row {
                        spacing: 6
                        Text { text: beeNet.tr("public_ip"); color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true; Behavior on color { ColorAnimation { duration: 600 } } }
                        Text { text: beeNet.publicIp; color: BeeTheme.textPrimary; font.pixelSize: 10; font.family: "monospace"; elide: Text.ElideRight; Behavior on color { ColorAnimation { duration: 600 } } }
                    }
                    Row {
                        spacing: 6
                        Text { text: beeNet.tr("gateway"); color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true; Behavior on color { ColorAnimation { duration: 600 } } }
                        Text { text: beeNet.gateway; color: BeeTheme.textPrimary; font.pixelSize: 10; font.family: "monospace"; elide: Text.ElideRight; Behavior on color { ColorAnimation { duration: 600 } } }
                    }
                    Row {
                        spacing: 6
                        Text { text: beeNet.tr("dns"); color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true; Behavior on color { ColorAnimation { duration: 600 } } }
                        Text { text: beeNet.dns; color: BeeTheme.textPrimary; font.pixelSize: 10; font.family: "monospace"; elide: Text.ElideRight; Behavior on color { ColorAnimation { duration: 600 } } }
                    }
                    Row {
                        spacing: 6
                        Text { text: beeNet.tr("mac"); color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true; Behavior on color { ColorAnimation { duration: 600 } } }
                        Text { text: beeNet.macAddress; color: BeeTheme.textPrimary; font.pixelSize: 10; font.family: "monospace"; elide: Text.ElideRight; Behavior on color { ColorAnimation { duration: 600 } } }
                    }
                    Row {
                        spacing: 6
                        Text { text: beeNet.tr("latency"); color: BeeTheme.textSecondary; font.pixelSize: 10; font.bold: true; Behavior on color { ColorAnimation { duration: 600 } } }
                        Text { text: beeNet.latency; color: BeeTheme.textPrimary; font.pixelSize: 10; font.family: "monospace"; Behavior on color { ColorAnimation { duration: 600 } } }
                    }
                }

                // ─── Speed Test button ──
                Rectangle {
                    width: parent.width - 40
                    height: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10
                    color: netStMouse.containsMouse
                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                    border.color: BeeTheme.accent
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 600 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: beeNet.speedTestRunning ? "\u23f3" : "\u26a1"
                            font.pixelSize: 16
                        }
                        Text {
                            text: beeNet.speedTestRunning
                                ? beeNet.speedTestStatus
                                : beeNet.tr("speed_test")
                            color: BeeTheme.accent
                            font { bold: true; pixelSize: 13 }
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        height: 3
                        width: parent.width * beeNet.speedTestProgress
                        color: BeeTheme.accent
                        radius: 1
                        visible: beeNet.speedTestRunning || beeNet.speedTestProgress > 0
                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }

                    MouseArea {
                        id: netStMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: beeNet.runSpeedTest()
                    }
                }

                // ─── Speed Test History ──
                Column {
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    visible: beeNet.speedTestHistory.length > 0

                    Text {
                        text: beeNet.tr("history")
                        color: BeeTheme.textSecondary
                        font { pixelSize: 10; bold: true; letterSpacing: 1 }
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }

                    Repeater {
                        model: beeNet.speedTestHistory.length
                        delegate: Rectangle {
                            width: parent.width
                            height: 22
                            radius: 4
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                            Behavior on color { ColorAnimation { duration: 600 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 10
                                Text { text: "\u2193 " + beeNet.speedTestHistory[index].download; color: BeeTheme.accent; font.pixelSize: 10; font.family: "monospace"; Behavior on color { ColorAnimation { duration: 600 } } }
                                Text { text: "\u2191 " + beeNet.speedTestHistory[index].upload; color: BeeTheme.textSecondary; font.pixelSize: 10; font.family: "monospace"; Behavior on color { ColorAnimation { duration: 600 } } }
                                Text { text: beeNet.speedTestHistory[index].ping; color: BeeTheme.textSecondary; font.pixelSize: 10; font.family: "monospace"; Behavior on color { ColorAnimation { duration: 600 } } }
                                Text { text: beeNet.speedTestHistory[index].timestamp; color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5); font.pixelSize: 9; Behavior on color { ColorAnimation { duration: 600 } } }
                            }
                        }
                    }
                }
            }
        }
    }

}
