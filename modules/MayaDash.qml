import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "."

// ═══════════════════════════════════════════════════════════════
// MayaDash.qml - Tableau de bord Maya (Bee-Hive OS) 🐝
// v0.7 : BeeNetwork - Network monitor & speed test (detail:network action)
// v0.6 : BeeVibe - Visualiseur audio intégré aux alvéoles (Phase 3)
//        Subtle equalizer bars, reactive to system audio
// v0.5 : BeeMotion - Effet de parallaxe 3D
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
    // Calendar now in own PanelWindow, no dynamic z needed
    z: 0

    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    Behavior on dashScale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // ─── Sons : ouverture / fermeture MayaDash ────────────────
    // onDashShownChanged: BeeSound.playEvent(dashShown ? "dash.open" : "dash.close", {}) (géré par shell.qml)

    // ─── Signaux externes ─────────────────────────────────────
    signal openSettings()
    signal openStudio()
    signal openNotes()
    signal openCalendar()
    signal openSysmon()
    signal cellsNeedRefresh()  // Emitted after drag & drop swap

    // ─── Drag & Drop state ──────────────────────────────────────
    property int dragFromIndex: -1    // Cell being dragged
    property int dragOverIndex: -1    // Cell currently under the drop target
    property bool dragActive: false   // Whether a drag is in progress

    // ─── BeeNetwork instance ────────────────────────────────
    property bool networkDetailVisible: false

    BeeNetwork {
        id: beeNet
    }

    // ─── BeeFocus (singleton - accessed via BeeFocus.xxx) ──
    property bool focusDetailVisible: false

    // ─── BeeMonitor instance ────────────────────────────────
    property bool monitorDetailVisible: false

    // ─── BeeCalendar: opened via BeeHiveShell.calendarVisible ────

    BeeMonitor {
        id: beeMon
    }

    // ─── Cell data cache (avoids binding loop) ────────────
    // resolveCellData() returns a NEW object every time, which causes
    // a QML binding loop (var comparison is by reference). Instead,
    // we update cellData imperatively only when cellsRevision changes,
    // and reuse the same object reference if data hasn't changed.
    property var _cellCache: ({})
    function resolveCellData(slot) {
        if (BeeConfig.cells.count > slot) {
            var item = BeeConfig.cells.get(slot)
            return {
                icon:         item.icon         || "",
                title:        item.title        || "",
                subtitle:     item.subtitle     || "",
                detail:       item.detail      || "",
                action:       item.action      || "none",
                highlighted:  item.highlighted || false,
                customizable: item.customizable !== false,
                color:        item.color       || ""
            }
        }
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
    function _updateCellCache() {
        var newCache = {}
        for (var i = 0; i < 8; i++) {
            newCache[i] = resolveCellData(i)
        }
        _cellCache = newCache
    }

    // Refresh cache when cellsRevision changes (drag & drop, config edits)
    Connections {
        target: BeeConfig
        function onCellsRevisionChanged() { mayaDash._updateCellCache(); mayaDash._refreshAllCells() }
    }

    // Refresh all HexCell instances after cache update
    function _refreshAllCells() {
        for (var i = 0; i < hexGrid.cellRefs.length; i++) {
            if (hexGrid.cellRefs[i]) hexGrid.cellRefs[i]._refreshCellData()
        }
    }

    Component.onCompleted: {
        _updateCellCache()
        // Start system monitor backend so dynamic details (CPU/GPU temps) show immediately
        beeMon.startBackend()
    }

    // ─── Dispatcher d'actions ─────────────────────────────────
    function handleCellAction(action) {
        if (!action || action === "none") return

        // toggle:settings → Ouvre The Hive (System tab)
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

            // App alias mapping: old generic names → CachyOS real binaries
            var appAliases = {
                "calendar":   "gnome-calendar",
                "email":      "thunderbird",
                "mixer":      "pavucontrol",
                "browser":    "zen-browser",
                "design":     "gimp",
                "reader":     "okular"
            }
            if (appAliases[cmd]) {
                console.warn("[Bee-Hive] app:" + cmd + " est un alias déprécié, mappé vers app:" + appAliases[cmd])
                cmd = appAliases[cmd]
            }

            var launchCmd = cmd.replace(/"/g, '\\"')
            var launchQml = 'import Quickshell.Io; Process {\n'
                + '  running: true\n'
                + '  command: ["bash", "-c", "' + launchCmd + ' & disown"]\n'
                + '  onExited: function(code, status) {\n'
                + '    if (code !== 0) {\n'
                + '      console.warn("[Bee-Hive] Lancement échoué (exit " + code + "): ' + launchCmd + '")\n'
                + '      BeeBarState.dispatchNotification("Bee-Hive OS", "Lancement échoué : ' + launchCmd + '", "⚠️")\n'
                + '    }\n'
                + '  }\n'
                + '}'
            Qt.createQmlObject(launchQml, mayaDash, "cellLaunch")
            console.log("[Bee-Hive] Lancement app: " + cmd)
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
            mayaDash.monitorDetailVisible = false
            mayaDash.focusDetailVisible = false
            mayaDash.networkDetailVisible = !mayaDash.networkDetailVisible
            beeNet.startBackend()  // Lazy start backend on first open
            BeeSound.playEvent(mayaDash.networkDetailVisible ? "dash.open" : "dash.close")
            return
        }

        // detail:monitor → BeeMonitor detail panel
        if (action === "detail:monitor") {
            mayaDash.networkDetailVisible = false
            mayaDash.focusDetailVisible = false
            mayaDash.monitorDetailVisible = !mayaDash.monitorDetailVisible
            beeMon.startBackend()  // Lazy start backend on first open
            BeeSound.playEvent(mayaDash.monitorDetailVisible ? "dash.open" : "dash.close")
            return
        }

        // detail:notes → BeeNotes panel
        if (action === "detail:notes") {
            mayaDash.networkDetailVisible = false
            mayaDash.monitorDetailVisible = false
            mayaDash.focusDetailVisible = false
            mayaDash.openNotes()
            BeeSound.playEvent("dash.open")
            return
        }

        // detail:calendar → BeeCalendar panel (own PanelWindow via BeeHiveShell)
        if (action === "detail:calendar") {
            mayaDash.networkDetailVisible = false
            mayaDash.monitorDetailVisible = false
            mayaDash.focusDetailVisible = false
            mayaDash.openCalendar()
            BeeSound.playEvent("dash.open")
            return
        }

        // detail:focus → BeeFocus detail panel
        if (action === "detail:focus") {
            mayaDash.networkDetailVisible = false
            mayaDash.monitorDetailVisible = false
            mayaDash.focusDetailVisible = !mayaDash.focusDetailVisible
            BeeSound.playEvent(mayaDash.focusDetailVisible ? "dash.open" : "dash.close")
            return
        }

        // detail:sysmon → BeeSystemMonitor panel (own PanelWindow via BeeHiveShell)
        if (action === "detail:sysmon") {
            mayaDash.networkDetailVisible = false
            mayaDash.monitorDetailVisible = false
            mayaDash.focusDetailVisible = false
            mayaDash.openSysmon()
            BeeSound.playEvent("dash.open")
            return
        }

        console.warn("MayaDash: Action non reconnue →", action)
    }

    // ═══════════════════════════════════════════════════════════
    // BEEMOTION - Parallaxe 3D
    // ═══════════════════════════════════════════════════════════

    // ─── BeeVibe ───────────────────────────────────────────────
    property bool beeVibeEnabled: false

    // ─── MayaDashConfig panel ──────────────────────────────────
    property bool configVisible: false

    BeeVibe {
        id: beeVibe
        active: mayaDash.beeVibeEnabled
    }

    // Activer/désactiver l'effet (câblé depuis The Hive)
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

        // Particules hexagonales flottantes - couche profonde (parallaxe amplifiée)
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
        // cellData is set imperatively from the cached _cellCache,
        // avoiding the binding loop caused by resolveCellData()
        // returning a new JS object on every evaluation.
        property var    cellData: null
        function _refreshCellData() {
            var cached = mayaDash._cellCache[cellIndex]
            if (cached !== undefined) cellData = cached
        }
        Component.onCompleted: _refreshCellData()

        // ─── Resolved data (declarative bindings, no imperative onXxx) ───
        // Using bindings instead of onCellDataChanged avoids the binding loop.
        property bool   isNetCell:  cellData && (cellData.action === "detail:network" || cellData.icon === "🌐")
        property string icon:          cellData ? (isNetCell ? beeNet.networkIcon : (cellData.icon || "🐝")) : "🐝"
        property string title:         cellData ? cellData.title         : "Module"
        property string subtitle:      cellData ? (isNetCell ? (beeNet.latency !== "- ms" ? beeNet.latency : (cellData.subtitle || "")) : (cellData.subtitle || "")) : ""
        property string detail:        cellData ? cellData.detail        : ""
        property bool   isHighlighted: cellData ? cellData.highlighted   : false
        property real   glowIntensity: isHighlighted ? 0.8 : 0.3
        Behavior on glowIntensity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Détection de la cellule Calendar pour afficher le compteur live
            property bool isCalendarCell: cellData && (cellData.icon === "📅" || cellData.title === "Calendar" || cellData.title === "Calendrier")

            // isNetCell is declared above at component level

            // Détection de la cellule Monitor pour afficher les températures live
            property bool isMonitorCell: cellData && (cellData.action === "detail:monitor" || cellData.icon === "🖥️")

            // Détection de la cellule Focus pour afficher le timer Pomodoro
            property bool isFocusCell: cellData && (cellData.action === "detail:focus" || cellData.icon === "🍅" || cellData.icon === "⚡" || cellData.icon === "🔥" || cellData.icon === "🎯" || cellData.icon === "☕")

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
                if (hexCell.isNetCell) {
                    return beeNet.downloadRate + " / " + beeNet.uploadRate;
                }
                if (hexCell.isMonitorCell) {
                    var gpuLabel = beeMon.gpuIsIgpu ? "iGPU" : "GPU";
                    return beeMon.cpuTemp.toFixed(0) + "°C / " + gpuLabel + " " + beeMon.gpuTemp.toFixed(0) + "°C";
                }
                if (hexCell.isFocusCell) {
                    return BeeFocus.timeDisplay + (BeeFocus.isRunning ? (BeeFocus.isBreakPhase ? " ☕" : " 🍅") : "");
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
                    if (hexCell.isNetCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
                }
                function onUploadRateChanged() {
                    if (hexCell.isNetCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
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

            // Réagir aux changements de stats système
            Connections {
                target: beeMon
                function onCpuTempChanged() {
                    if (hexCell.isMonitorCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
                }
                function onGpuTempChanged() {
                    if (hexCell.isMonitorCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
                }
            }

            // Réagir aux changements du timer BeeFocus
            Connections {
                target: BeeFocus
                function onTimeDisplayChanged() {
                    if (hexCell.isFocusCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
                    if (hexCell.isFocusCell) hexCell.icon = BeeFocus.currentIcon;
                }
                function onCurrentIconChanged() {
                    if (hexCell.isFocusCell) hexCell.icon = BeeFocus.currentIcon;
                }
                function onIsRunningChanged() {
                    if (hexCell.isFocusCell) hexCell.dynamicDetail = hexCell.dynamicDetail;
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

                // Glassmorphism fill - propriétés réactives interpolées
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
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 0.5
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
                text: (hexCell.isCalendarCell || hexCell.isNetCell || hexCell.isMonitorCell) ? hexCell.dynamicDetail : hexCell.detail
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
                        mayaDash.cellsNeedRefresh()
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
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        transform: Scale {
            id: hexScale
            origin.x: hexCell.width / 2; origin.y: hexCell.height / 2
            Behavior on xScale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.4 } }
            Behavior on yScale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.4 } }
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
    // LAYOUT - Grille en nid d'abeille (2 + 3 + 3)
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

        // ─── Title + Config button ────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Text {
                text: BeeConfig.dashTitle
                color: BeeTheme.accent
                font.pixelSize: 22; font.bold: true; font.letterSpacing: 2
                Behavior on color { ColorAnimation { duration: 800 } }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.7; duration: 3000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 3000; easing.type: Easing.InOutSine }
                }
            }

            // ⚙️ Config button
            Rectangle {
                width: 32; height: 32; radius: 16
                color: configBtnHover.containsMouse
                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25)
                    : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                border.color: configBtnHover.containsMouse
                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.6)
                    : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "⚙️"; font.pixelSize: 16
                    opacity: configBtnHover.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    id: configBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mayaDash.configVisible = !mayaDash.configVisible
                        BeeSound.playEvent(mayaDash.configVisible ? "dash.open" : "dash.close")
                    }
                }
            }
        }

        Item { width: 1; height: 50 }

        // ─── Rangée 1 : 2 alvéoles (indices 0-1) ─────────────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 0; Component.onCompleted: hexGrid.cellRefs[0] = this }
            HexCell { cellIndex: 1; Component.onCompleted: hexGrid.cellRefs[1] = this }
        }

        // ─── Rangée 2 : 3 alvéoles décalées (indices 2-4) ────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 2; Component.onCompleted: hexGrid.cellRefs[2] = this }
            HexCell { cellIndex: 3; Component.onCompleted: hexGrid.cellRefs[3] = this }
            HexCell { cellIndex: 4; Component.onCompleted: hexGrid.cellRefs[4] = this }
        }

        // ─── Rangée 3 : 3 alvéoles (indices 5-7) ─────────────
        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter
            HexCell { cellIndex: 5; Component.onCompleted: hexGrid.cellRefs[5] = this }
            HexCell { cellIndex: 6; Component.onCompleted: hexGrid.cellRefs[6] = this }
            HexCell { cellIndex: 7; Component.onCompleted: hexGrid.cellRefs[7] = this }
        }
    }

    // ─── MayaDashConfig overlay ────────────────────────────────
    Rectangle {
        id: dashConfigOverlay
        z: 200
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        visible: mayaDash.configVisible
        opacity: mayaDash.configVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                mayaDash.configVisible = false
                BeeSound.playEvent("dash.close")
            }
        }

        MayaDashConfig {
            id: dashConfigPanel
            anchors.centerIn: parent
            visible: mayaDash.configVisible
            onVisibleChanged: {
                if (!visible) mayaDash.configVisible = false
            }
        }

        // ✕ Close button — top-right corner of the config panel
        Rectangle {
            id: configFloatingBtn
            z: 300
            width: 34; height: 34; radius: 17
            anchors.top: dashConfigPanel.top
            anchors.right: dashConfigPanel.right
            anchors.topMargin: -14
            anchors.rightMargin: -14
            color: configFloatingBtnHover.containsMouse
                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.45)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
            border.color: configFloatingBtnHover.containsMouse
                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.9)
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
            border.width: 1.5
            opacity: mayaDash.configVisible ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Text {
                anchors.centerIn: parent
                text: "\u2715"; font.pixelSize: 16; font.bold: true
                color: BeeTheme.accent
            }

            MouseArea {
                id: configFloatingBtnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    mayaDash.configVisible = false
                    BeeSound.playEvent("dash.close")
                }
            }
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
        text: "Bee-Hive OS v1.3.7 · NectarSync2 · BeeAlarm · BeeFocus 🐝"
        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.15)
        font.pixelSize: 10; font.letterSpacing: 1
        anchors.bottom: parent.bottom; anchors.bottomMargin: 15
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // ═══════════════════════════════════════════════════════════
    // BeeCalendar - now in own PanelWindow (BeeHiveShell.qml)

    // ═══════════════════════════════════════════════════════════
    // BeeMonitor - Détail système (overlay panel)
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        id: monitorOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        visible: mayaDash.monitorDetailVisible
        opacity: mayaDash.monitorDetailVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                mayaDash.monitorDetailVisible = false
                BeeSound.playEvent("dash.close")
            }
        }

        Rectangle {
            width: 480
            height: 800
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
                anchors.bottomMargin: 24
                spacing: 14

                // ─── Header ──
                Row {
                    spacing: 10
                    Text {
                        text: "🖥️"
                        font.pixelSize: 28
                    }
                    Column {
                        spacing: 2
                        Text {
                            text: beeMon.tr("title")
                            color: BeeTheme.textPrimary
                            font.bold: true; font.pixelSize: 18
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: beeMon.uptime + " · CachyOS"
                            color: BeeTheme.textSecondary
                            font.pixelSize: 11
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // ─── Temperature + Usage Cards ──
                Row {
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    // CPU Card
                    Rectangle {
                        width: 140; height: 90
                        radius: 10
                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                        border.color: Qt.rgba(beeMon.cpuTempColor.r, beeMon.cpuTempColor.g, beeMon.cpuTempColor.b, 0.4)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 600 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: beeMon.tr("cpu")
                                color: BeeTheme.textSecondary
                                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: beeMon.cpuTemp.toFixed(0) + "°C"
                                color: beeMon.cpuTempColor
                                font.pixelSize: 28; font.bold: true; font.family: "monospace"
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                text: beeMon.cpuPct.toFixed(0) + "%"
                                color: beeMon.cpuTempColor
                                font.pixelSize: 12; font.family: "monospace"
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }

                    // GPU Card
                    Rectangle {
                        width: 140; height: 90
                        radius: 10
                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                        border.color: Qt.rgba(beeMon.gpuTempColor.r, beeMon.gpuTempColor.g, beeMon.gpuTempColor.b, 0.4)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 600 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: beeMon.gpuIsIgpu ? beeMon.tr("igpu") : beeMon.tr("gpu")
                                color: BeeTheme.textSecondary
                                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: beeMon.gpuTemp.toFixed(0) + "°C"
                                color: beeMon.gpuTempColor
                                font.pixelSize: 28; font.bold: true; font.family: "monospace"
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }

                    // RAM Card
                    Rectangle {
                        width: 140; height: 90
                        radius: 10
                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 600 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: beeMon.tr("ram")
                                color: BeeTheme.textSecondary
                                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: beeMon.ramPct.toFixed(0) + "%"
                                color: BeeTheme.accent
                                font.pixelSize: 28; font.bold: true; font.family: "monospace"
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: beeMon.ramUsed + " / " + beeMon.ramTotal
                                color: BeeTheme.textSecondary
                                font.pixelSize: 9; font.family: "monospace"
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                        }
                    }
                }

                // ─── RAM Bar ──
                Rectangle {
                    width: parent.width - 40
                    height: 22
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 4
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                    Behavior on color { ColorAnimation { duration: 600 } }

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: parent.width * (beeMon.ramPct / 100)
                        radius: 4
                        color: BeeTheme.accent
                        opacity: 0.6
                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: beeMon.tr("ram") + "  " + beeMon.ramUsed + " / " + beeMon.ramTotal
                        color: BeeTheme.textPrimary
                        font.pixelSize: 9; font.bold: true
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }
                }

                // ─── Swap + Uptime Row ──
                Row {
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    // Swap
                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 22
                        radius: 4
                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                        Behavior on color { ColorAnimation { duration: 600 } }

                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: parent.width * (beeMon.swapPct / 100)
                            radius: 4
                            color: beeMon.swapPct > 50 ? Qt.rgba(1.0, 0.45, 0.1, 0.7) : BeeTheme.accent
                            opacity: 0.5
                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: beeMon.tr("swap") + "  " + beeMon.swapUsed + " / " + beeMon.swapTotal
                            color: BeeTheme.textPrimary
                            font.pixelSize: 9; font.bold: true
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }

                    // Uptime
                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 22
                        radius: 4
                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                        Behavior on color { ColorAnimation { duration: 600 } }

                        Text {
                            anchors.centerIn: parent
                            text: "⏱ " + beeMon.uptime
                            color: BeeTheme.textPrimary
                            font.pixelSize: 9; font.bold: true; font.family: "monospace"
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // ─── Fans ──
                Rectangle {
                    width: parent.width - 40
                    height: 36
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 8
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                    Behavior on color { ColorAnimation { duration: 600 } }
                    visible: true

                    Text {
                        anchors.centerIn: parent
                        text: beeMon.fans.length > 0
                            ? "🌀 " + beeMon.fans.map(function(f) { return f.label + ": " + f.rpm + " RPM" }).join("  ·  ")
                            : "🌀 " + beeMon.tr("no_fans")
                        color: BeeTheme.textSecondary
                        font.pixelSize: 10
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }
                }

                // ─── Process Memory (VmRSS) ──
                Rectangle {
                    width: parent.width - 40
                    height: 120
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                    Behavior on color { ColorAnimation { duration: 600 } }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Row {
                            spacing: 8
                            width: parent.width
                            Text {
                                text: "🐝 " + beeMon.tr("process_memory")
                                color: BeeTheme.textPrimary
                                font.pixelSize: 11; font.bold: true
                                Behavior on color { ColorAnimation { duration: 600 } }
                            }
                            Text {
                                text: beeMon.processRss.toFixed(1) + " " + beeMon.tr("rss_mb")
                                color: beeMon.rssAlert ? Qt.rgba(1.0, 0.75, 0.2, 1.0) : BeeTheme.accent
                                font.pixelSize: 11; font.bold: true; font.family: "monospace"
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                text: beeMon.rssAlert ? beeMon.tr("rss_alert") : ""
                                color: Qt.rgba(1.0, 0.75, 0.2, 1.0)
                                font.pixelSize: 9; font.bold: true
                                visible: beeMon.rssAlert
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                        Text {
                            text: beeMon.tr("rss_graph_label")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 8; font.letterSpacing: 1
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }

                        // RSS History Graph (Canvas)
                        Canvas {
                            id: rssGraph
                            width: parent.width
                            height: 70
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var hist = beeMon.rssHistory
                                if (hist.length < 2) {
                                    ctx.fillStyle = Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                                    ctx.font = "10px monospace"
                                    ctx.textAlign = "center"
                                    ctx.fillText("...", width / 2, height / 2)
                                    return
                                }

                                // Find max for scaling (min 100 MB for graph)
                                var maxRss = 100
                                for (var i = 0; i < hist.length; i++) {
                                    if (hist[i] > maxRss) maxRss = hist[i]
                                }
                                maxRss = maxRss * 1.15  // 15% headroom

                                var w = width
                                var h = height
                                var step = w / 59  // 60 points max
                                var alertY = h - (200 / maxRss) * h

                                // Alert threshold line (200 MB)
                                ctx.strokeStyle = Qt.rgba(1.0, 0.75, 0.2, 0.4)
                                ctx.lineWidth = 1
                                ctx.setLineDash([4, 4])
                                ctx.beginPath()
                                ctx.moveTo(0, alertY)
                                ctx.lineTo(w, alertY)
                                ctx.stroke()
                                ctx.setLineDash([])

                                // Label for threshold
                                ctx.fillStyle = Qt.rgba(1.0, 0.75, 0.2, 0.6)
                                ctx.font = "8px monospace"
                                ctx.textAlign = "right"
                                ctx.fillText("200 MB", w - 2, alertY - 3)

                                // Fill area under curve
                                ctx.beginPath()
                                ctx.moveTo(0, h)
                                for (var j = 0; j < hist.length; j++) {
                                    var x = j * step
                                    var y = h - (hist[j] / maxRss) * h
                                    ctx.lineTo(x, y)
                                }
                                ctx.lineTo((hist.length - 1) * step, h)
                                ctx.closePath()

                                var grad = ctx.createLinearGradient(0, 0, 0, h)
                                var accentR = BeeTheme.accent.r
                                var accentG = BeeTheme.accent.g
                                var accentB = BeeTheme.accent.b
                                grad.addColorStop(0, Qt.rgba(accentR, accentG, accentB, 0.4))
                                grad.addColorStop(1, Qt.rgba(accentR, accentG, accentB, 0.05))
                                ctx.fillStyle = grad
                                ctx.fill()

                                // Line
                                ctx.beginPath()
                                for (var k = 0; k < hist.length; k++) {
                                    var px = k * step
                                    var py = h - (hist[k] / maxRss) * h
                                    if (k === 0) ctx.moveTo(px, py)
                                    else ctx.lineTo(px, py)
                                }
                                ctx.strokeStyle = BeeTheme.accent.toString()
                                ctx.lineWidth = 2
                                ctx.stroke()

                                // Current value dot
                                if (hist.length > 0) {
                                    var lastX = (hist.length - 1) * step
                                    var lastY = h - (hist[hist.length - 1] / maxRss) * h
                                    ctx.beginPath()
                                    ctx.arc(lastX, lastY, 4, 0, Math.PI * 2)
                                    ctx.fillStyle = beeMon.rssAlert ? Qt.rgba(1.0, 0.75, 0.2, 1.0).toString() : BeeTheme.accent.toString()
                                    ctx.fill()
                                }
                            }

                            // Repaint when history changes
                            Connections {
                                target: beeMon
                                function onRssHistoryChanged() { rssGraph.requestPaint() }
                                function onRssAlertChanged() { rssGraph.requestPaint() }
                            }
                        }
                    }
                }

                // ─── Top Processes ──
                Rectangle {
                    width: parent.width - 40
                    height: 210
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10
                    color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.3)
                    Behavior on color { ColorAnimation { duration: 600 } }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Text {
                            text: beeMon.tr("processes")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }

                        // Header
                        Row {
                            spacing: 8
                            width: parent.width
                            Text {
                                text: "NAME"
                                color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                                font.pixelSize: 8
                                font.bold: true
                                font.letterSpacing: 1
                                width: parent.width * 0.50
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "CPU%"
                                color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                                font.pixelSize: 8
                                font.bold: true
                                font.letterSpacing: 1
                                width: parent.width * 0.18
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                text: "MEM%"
                                color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                                font.pixelSize: 8
                                font.bold: true
                                font.letterSpacing: 1
                                width: parent.width * 0.18
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        // Process list
                        Repeater {
                            model: Math.min(beeMon.topProcesses.length, 5)
                            delegate: Row {
                                spacing: 8
                                width: parent.width
                                property var proc: beeMon.topProcesses[index] || {}
                                Text {
                                    text: (proc.name || "-")
                                    color: BeeTheme.textPrimary
                                    font.pixelSize: 10; font.family: "monospace"
                                    width: parent.width * 0.50
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 600 } }
                                }
                                Text {
                                    text: (proc.cpu !== undefined ? proc.cpu.toFixed(1) : "-")
                                    color: proc.cpu > 10 ? Qt.rgba(1.0, 0.65, 0.2, 1.0) : BeeTheme.textPrimary
                                    font.pixelSize: 10; font.family: "monospace"; font.bold: proc.cpu > 10
                                    width: parent.width * 0.18
                                    horizontalAlignment: Text.AlignRight
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                                Text {
                                    text: (proc.mem !== undefined ? proc.mem.toFixed(1) : "-")
                                    color: proc.mem > 10 ? Qt.rgba(1.0, 0.45, 0.1, 1.0) : BeeTheme.textSecondary
                                    font.pixelSize: 10; font.family: "monospace"
                                    width: parent.width * 0.18
                                    horizontalAlignment: Text.AlignRight
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // BeeNetwork - Détail réseau (overlay panel)
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
            width: 480
            height: 620
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
                anchors.bottomMargin: 24
                spacing: 16

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
                            font.bold: true; font.pixelSize: 18
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
                            font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
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

                // ─── Speed Test Results (shown after completion) ──
                Rectangle {
                    width: parent.width - 40
                    height: 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                    border.width: 1
                    visible: beeNet.speedTestCompleted
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on border.color { ColorAnimation { duration: 300 } }
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    opacity: beeNet.speedTestCompleted ? 1.0 : 0.0

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Text {
                            text: beeNet.tr("results")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }

                        Row {
                            spacing: 20
                            anchors.horizontalCenter: parent.horizontalCenter

                            Column {
                                spacing: 2
                                Text { text: "\u2193"; color: BeeTheme.accent; font.pixelSize: 14; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                                Text { text: (beeNet._stDlResult === "-" || beeNet._stDlResult === "") ? beeNet.tr("not_available") : beeNet._stDlResult; color: BeeTheme.textPrimary; font.pixelSize: 16; font.bold: true; font.family: "monospace"; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                            }
                            Column {
                                spacing: 2
                                Text { text: "\u2191"; color: BeeTheme.textSecondary; font.pixelSize: 14; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                                Text { text: (beeNet._stUlResult === "-" || beeNet._stUlResult === "") ? beeNet.tr("not_available") : beeNet._stUlResult; color: BeeTheme.textPrimary; font.pixelSize: 16; font.bold: true; font.family: "monospace"; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                            }
                            Column {
                                spacing: 2
                                Text { text: "\u23f1"; color: BeeTheme.textSecondary; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                                Text { text: (beeNet._stPingResult === "-" || beeNet._stPingResult === "") ? beeNet.tr("not_available") : beeNet._stPingResult; color: BeeTheme.textPrimary; font.pixelSize: 16; font.bold: true; font.family: "monospace"; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 600 } } }
                            }
                        }
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
                            font.bold: true; font.pixelSize: 13
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

                // ─── Speed Test History (2-line entries) ──
                Column {
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    visible: beeNet.speedTestHistory.length > 0

                    Text {
                        text: beeNet.tr("history")
                        color: BeeTheme.textSecondary
                        font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }

                    Repeater {
                        model: beeNet.speedTestHistory.length
                        delegate: Rectangle {
                            width: parent.width
                            height: 38
                            radius: 6
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                            Behavior on color { ColorAnimation { duration: 600 } }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 2

                                Row {
                                    spacing: 14
                                    Text { text: "\u2193 " + beeNet.speedTestHistory[index].download; color: BeeTheme.accent; font.pixelSize: 11; font.bold: true; font.family: "monospace"; Behavior on color { ColorAnimation { duration: 600 } } }
                                    Text { text: "\u2191 " + beeNet.speedTestHistory[index].upload; color: BeeTheme.textSecondary; font.pixelSize: 11; font.bold: true; font.family: "monospace"; Behavior on color { ColorAnimation { duration: 600 } } }
                                }

                                Row {
                                    spacing: 14
                                    Text { text: "\u23f1 " + beeNet.speedTestHistory[index].ping; color: BeeTheme.textSecondary; font.pixelSize: 9; font.family: "monospace"; Behavior on color { ColorAnimation { duration: 600 } } }
                                    Text { text: beeNet.speedTestHistory[index].timestamp; color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5); font.pixelSize: 9; Behavior on color { ColorAnimation { duration: 600 } } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // BeeFocus - Pomodoro & Health Timer (overlay panel)
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        id: focusOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        visible: mayaDash.focusDetailVisible
        opacity: mayaDash.focusDetailVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                mayaDash.focusDetailVisible = false
                BeeSound.playEvent("dash.close")
            }
        }

        Rectangle {
            width: 440
            height: 680
            anchors.centerIn: parent
            color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.95)
            radius: 20
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
                anchors.margins: 24
                anchors.bottomMargin: 28
                spacing: 16

                // ─── Header ──
                Row {
                    spacing: 10
                    Text {
                        text: BeeFocus.currentIcon
                        font.pixelSize: 28
                    }
                    Column {
                        spacing: 2
                        Text {
                            text: BeeFocus.tr("title")
                            color: BeeTheme.textPrimary
                            font.bold: true; font.pixelSize: 20
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: BeeFocus.isBreakPhase ? BeeFocus.tr("break_label") : BeeFocus.modes[BeeFocus.currentMode].name
                            color: BeeTheme.textSecondary
                            font.pixelSize: 11
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                    Item { Layout.fillWidth: true; width: 120 }

                    // Close button
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: closeFocus.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.2) : "transparent"
                        border.color: closeFocus.containsMouse ? "#ff5555" : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: 1
                        Text { text: "✕"; anchors.centerIn: parent; color: closeFocus.containsMouse ? "#ff5555" : BeeTheme.textSecondary; font.pixelSize: 14 }
                        MouseArea {
                            id: closeFocus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                mayaDash.focusDetailVisible = false
                                BeeSound.playEvent("dash.close")
                            }
                        }
                    }
                }

                // ─── Progress Circle ──
                Item {
                    width: 200
                    height: 200
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Background circle
                    Rectangle {
                        anchors.centerIn: parent
                        width: 180; height: 180; radius: 90
                        color: "transparent"
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                        border.width: 6
                    }

                    // Progress arc (using Canvas)
                    Canvas {
                        id: focusCanvas
                        anchors.centerIn: parent
                        width: 180; height: 180

                        property real prog: BeeFocus.progress

                        onProgChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.clearRect(0, 0, width, height)

                            var centerX = width / 2
                            var centerY = height / 2
                            var radius = Math.max(1, (Math.min(width, height) - 12) / 2)
                            var startAngle = -Math.PI / 2
                            var endAngle = startAngle + (2 * Math.PI * prog)

                            // Progress arc
                            ctx.beginPath()
                            ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                            ctx.strokeStyle = BeeFocus.isBreakPhase ? "#27AE60" : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 1.0).toString()
                            ctx.lineWidth = 6
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }

                    // Timer display in center
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: BeeFocus.timeDisplay
                            color: BeeTheme.textPrimary
                            font.bold: true; font.pixelSize: 42; font.family: "monospace"
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        Text {
                            text: BeeFocus.isBreakPhase ? BeeFocus.tr("break_label") : BeeFocus.tr("work")
                            color: BeeFocus.isBreakPhase ? "#27AE60" : BeeTheme.accent
                            font.pixelSize: 12; font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                    }
                }

                // ─── Mode Selector ──
                Row {
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: [
                            { idx: 0, icon: "🍅", label: BeeFocus.tr("pomodoro") },
                            { idx: 1, icon: "⚡", label: BeeFocus.tr("short") },
                            { idx: 2, icon: "🔥", label: BeeFocus.tr("long") },
                            { idx: 3, icon: "🎯", label: BeeFocus.tr("custom") }
                        ]
                        Rectangle {
                            width: 95; height: 36; radius: 10
                            color: BeeFocus.currentMode === modelData.idx ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2) : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.15)
                            border.color: BeeFocus.currentMode === modelData.idx ? BeeTheme.accent : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Text { text: modelData.icon; font.pixelSize: 14 }
                                Text {
                                    text: modelData.label
                                    color: BeeFocus.currentMode === modelData.idx ? BeeTheme.accent : BeeTheme.textSecondary
                                    font.pixelSize: 11; font.bold: BeeFocus.currentMode === modelData.idx
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: BeeFocus.setMode(modelData.idx)
                            }
                        }
                    }
                }

                // ─── Controls ──
                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Play / Pause
                    Rectangle {
                        width: 56; height: 56; radius: 28
                        color: BeeFocus.isRunning ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3) : BeeTheme.accent
                        border.color: BeeTheme.accent; border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: BeeFocus.isRunning ? "⏸" : (BeeFocus.isPaused ? "▶" : "▶")
                            color: BeeFocus.isRunning ? BeeTheme.accent : "#000000"
                            font.pixelSize: 24; font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (BeeFocus.isRunning) {
                                    BeeFocus.pauseTimer()
                                } else {
                                    BeeFocus.startTimer()
                                }
                            }
                        }
                    }

                    // Reset
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: resetFocus.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15) : "transparent"
                        border.color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: 1
                        Text { text: "↺"; anchors.centerIn: parent; color: BeeTheme.textSecondary; font.pixelSize: 18 }
                        MouseArea {
                            id: resetFocus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: BeeFocus.resetTimer()
                        }
                    }

                    // Skip
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: skipFocus.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15) : "transparent"
                        border.color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.3)
                        border.width: 1
                        Text { text: "⏭"; anchors.centerIn: parent; color: BeeTheme.textSecondary; font.pixelSize: 18 }
                        MouseArea {
                            id: skipFocus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: BeeFocus.skipPhase()
                        }
                    }
                }

                // ─── Stats ──
                Row {
                    spacing: 30
                    anchors.horizontalCenter: parent.horizontalCenter

                    Column {
                        spacing: 2
                        Text {
                            text: BeeFocus.sessionsCompleted.toString()
                            color: BeeTheme.accent
                            font.bold: true; font.pixelSize: 22; font.family: "monospace"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: BeeFocus.tr("sessions")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Column {
                        spacing: 2
                        Text {
                            text: BeeFocus.totalFocusMinutes.toString()
                            color: BeeTheme.accent
                            font.bold: true; font.pixelSize: 22; font.family: "monospace"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: BeeFocus.tr("focus_minutes")
                            color: BeeTheme.textSecondary
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // ─── Separator ──
                Rectangle {
                    width: parent.width - 40; height: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                }

                // ─── Health Reminders ──
                Text {
                    text: BeeFocus.tr("health_reminders")
                    color: BeeTheme.accent
                    font.bold: true; font.pixelSize: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Hydration toggle
                    Rectangle {
                        width: 110; height: 70; radius: 12
                        color: BeeFocus.hydrationEnabled ? Qt.rgba(0.16, 0.5, 0.73, 0.2) : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeFocus.hydrationEnabled ? "#2980B9" : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.centerIn: parent; spacing: 3
                            Text { text: "💧"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                            Text {
                                text: BeeFocus.hydrationEnabled
                                    ? Math.floor(BeeFocus.hydrationSeconds / 60) + ":" + (BeeFocus.hydrationSeconds % 60 < 10 ? "0" : "") + (BeeFocus.hydrationSeconds % 60).toString()
                                    : "-"
                                color: BeeFocus.hydrationEnabled ? "#2980B9" : BeeTheme.textSecondary
                                font.pixelSize: 13; font.family: "monospace"; font.bold: true
                            }
                            Text {
                                text: BeeFocus.tr("hydration")
                                color: BeeTheme.textSecondary
                                font.pixelSize: 9
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: BeeFocus.hydrationEnabled = !BeeFocus.hydrationEnabled
                        }
                    }

                    // Posture toggle
                    Rectangle {
                        width: 110; height: 70; radius: 12
                        color: BeeFocus.postureEnabled ? Qt.rgba(0.18, 0.55, 0.34, 0.2) : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeFocus.postureEnabled ? "#27AE60" : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.centerIn: parent; spacing: 3
                            Text { text: "🧍"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                            Text {
                                text: BeeFocus.postureEnabled
                                    ? Math.floor(BeeFocus.postureSeconds / 60) + ":" + (BeeFocus.postureSeconds % 60 < 10 ? "0" : "") + (BeeFocus.postureSeconds % 60).toString()
                                    : "-"
                                color: BeeFocus.postureEnabled ? "#27AE60" : BeeTheme.textSecondary
                                font.pixelSize: 13; font.family: "monospace"; font.bold: true
                            }
                            Text {
                                text: BeeFocus.tr("posture")
                                color: BeeTheme.textSecondary
                                font.pixelSize: 9
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: BeeFocus.postureEnabled = !BeeFocus.postureEnabled
                        }
                    }

                    // Eyes toggle
                    Rectangle {
                        width: 110; height: 70; radius: 12
                        color: BeeFocus.eyesEnabled ? Qt.rgba(0.6, 0.35, 0.73, 0.2) : Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.1)
                        border.color: BeeFocus.eyesEnabled ? "#9B59B6" : Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors.centerIn: parent; spacing: 3
                            Text { text: "👁️"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter }
                            Text {
                                text: BeeFocus.eyesEnabled
                                    ? Math.floor(BeeFocus.eyesSeconds / 60) + ":" + (BeeFocus.eyesSeconds % 60 < 10 ? "0" : "") + (BeeFocus.eyesSeconds % 60).toString()
                                    : "-"
                                color: BeeFocus.eyesEnabled ? "#9B59B6" : BeeTheme.textSecondary
                                font.pixelSize: 13; font.family: "monospace"; font.bold: true
                            }
                            Text {
                                text: BeeFocus.tr("eyes")
                                color: BeeTheme.textSecondary
                                font.pixelSize: 9
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: BeeFocus.eyesEnabled = !BeeFocus.eyesEnabled
                        }
                    }
                }

                // ─── Custom Mode Settings (visible only in Custom mode) ──
                Column {
                    width: parent.width - 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    visible: BeeFocus.currentMode === 3
                    height: BeeFocus.currentMode === 3 ? implicitHeight : 0
                    Behavior on height { NumberAnimation { duration: 200 } }

                    Rectangle {
                        width: parent.width; height: 1
                        color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.2)
                    }

                    Text {
                        text: BeeFocus.tr("timer_settings")
                        color: BeeTheme.accent
                        font.bold: true; font.pixelSize: 13
                    }

                    // Work duration
                    Row {
                        spacing: 10
                        Text {
                            text: BeeFocus.tr("work_duration") + ":"
                            color: BeeTheme.textSecondary; font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 50; height: 30; radius: 8
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                            border.width: 1
                            TextInput {
                                id: customWorkInput
                                anchors.centerIn: parent
                                text: BeeFocus.customWork.toString()
                                color: BeeTheme.textPrimary; font.pixelSize: 13; font.family: "monospace"
                                validator: IntValidator { bottom: 1; top: 120 }
                                onEditingFinished: {
                                    BeeFocus.customWork = parseInt(text) || 25
                                    BeeFocus.setMode(3)
                                }
                            }
                        }
                        Text { text: BeeFocus.tr("minutes"); color: BeeTheme.textSecondary; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    }

                    // Break duration
                    Row {
                        spacing: 10
                        Text {
                            text: BeeFocus.tr("break_duration") + ":"
                            color: BeeTheme.textSecondary; font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 50; height: 30; radius: 8
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                            border.width: 1
                            TextInput {
                                id: customBreakInput
                                anchors.centerIn: parent
                                text: BeeFocus.customBreak.toString()
                                color: BeeTheme.textPrimary; font.pixelSize: 13; font.family: "monospace"
                                validator: IntValidator { bottom: 1; top: 60 }
                                onEditingFinished: {
                                    BeeFocus.customBreak = parseInt(text) || 5
                                    BeeFocus.setMode(3)
                                }
                            }
                        }
                        Text { text: BeeFocus.tr("minutes"); color: BeeTheme.textSecondary; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    }

                    // Long break duration
                    Row {
                        spacing: 10
                        Text {
                            text: BeeFocus.tr("long_break_duration") + ":"
                            color: BeeTheme.textSecondary; font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 50; height: 30; radius: 8
                            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.2)
                            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                            border.width: 1
                            TextInput {
                                id: customLongBreakInput
                                anchors.centerIn: parent
                                text: BeeFocus.customLongBreak.toString()
                                color: BeeTheme.textPrimary; font.pixelSize: 13; font.family: "monospace"
                                validator: IntValidator { bottom: 1; top: 60 }
                                onEditingFinished: {
                                    BeeFocus.customLongBreak = parseInt(text) || 15
                                    BeeFocus.setMode(3)
                                }
                            }
                        }
                        Text { text: BeeFocus.tr("minutes"); color: BeeTheme.textSecondary; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                Item { height: 8 }
            }
        }
    }

}
