import QtQuick
import QtQuick.Controls
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeSearch.qml — Lanceur BeeAura ultra-performant 🐝🔍
// Sprint v0.8.1 — Phase 3 Advanced
// • Fuzzy search avec scoring (prefix > substring > subsequence)
// • Scan des .desktop système via Python (sans dépendance externe)
// • Design BeeAura : Glow actif pulsé, Glassmorphism, animations
// • Clavier complet : ↑↓ Tab, ↵, Esc + navigation wrap-around
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeSearch

    // ─── API publique ──────────────────────────────────────────
    property bool shown: false
    signal openSettings()
    signal openStudio()
    signal launchRequested(string cmd)   // transmet la commande à shell.qml pour lancement différé

    function toggle() {
        shown = !shown
        if (shown) { searchInput.text = ""; searchInput.forceActiveFocus() }
    }
    function show() { shown = true;  searchInput.text = ""; searchInput.forceActiveFocus() }
    function hide() { 
        searchInput.focus = false  // Libère le focus texte avant de fermer
        shown = false 
    }

    // ─── État interne ──────────────────────────────────────────
    property int  selectedIndex: 0

    // scanning et pool délégués au singleton BeeApps
    readonly property bool scanning: BeeApps.scanning
    readonly property var  _appPool: BeeApps.pool

    // ─── Favoris (max 4) ──────────────────────────────────────
    property var pinnedCmds: BeeApps.pinnedCmds

    function isPinned(cmd) {
        for (var i = 0; i < pinnedCmds.length; i++)
            if (pinnedCmds[i] === cmd) return true
        return false
    }

    function togglePin(cmd) {
        if (isPinned(cmd)) {
            BeeApps.unpin(cmd)
        } else {
            if (pinnedCmds.length >= 4) return  // max 4
            BeeApps.pin(cmd)
        }
        filterApps(searchInput.text)
    }

    // Rafraîchir la liste quand BeeApps termine son scan
    Connections {
        target: BeeApps
        function onScanningChanged() {
            if (!BeeApps.scanning) filterApps(searchInput.text)
        }
        function onPoolChanged() {
            filterApps(searchInput.text)
        }
        function onPinnedCmdsChanged() {
            beeSearch.pinnedCmds = BeeApps.pinnedCmds
            filterApps(searchInput.text)
        }
    }

    // ─── Fuzzy search avec scoring ────────────────────────────
    // Hiérarchie : exact (1000) > prefix (900) > substring (700) > subsequence
    // Bonus : début de mot (+15), caractères consécutifs (+8/streak)
    // Pénalité : longueur du texte (préfère les noms courts)
    function _fuzzyScore(query, text) {
        if (!query || !text) return -1
        var q = query.toLowerCase()
        var t = text.toLowerCase()

        if (t === q)            return 1000
        if (t.startsWith(q))   return 900 - t.length

        var idx = t.indexOf(q)
        if (idx !== -1)         return 700 - idx * 4 - t.length

        // Correspondance en sous-séquence avec bonus
        var score = 0, qi = 0, prev = -1, streak = 0
        for (var ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                score += 10
                if (prev === ti - 1) { streak++; score += streak * 8 }
                else streak = 0
                if (ti === 0 || t[ti-1] === ' ' || t[ti-1] === '-') score += 15
                prev = ti
                qi++
            }
        }
        if (qi < q.length) return -1   // pas de correspondance complète
        return score - Math.floor(t.length / 2)
    }

    function filterApps(query) {
        var q = (query || "").trim()
        var pinned = []
        var scored = []

        for (var i = 0; i < _appPool.length; i++) {
            var app = _appPool[i]
            var pinned_ = isPinned(app.cmd)

            if (!q) {
                // Sans recherche : afficher tout (épinglés en tête, puis alpha)
                if (pinned_) pinned.push({ app: app, score: 9999 })
                else         scored.push({ app: app, score: 0 })
            } else {
                // Avec recherche : scoring fuzzy
                var ns   = _fuzzyScore(q, app.name)
                var cs   = _fuzzyScore(q, app.cat)
                var best = (cs >= 0) ? Math.max(ns, cs - 60) : ns
                if (best >= 0) {
                    if (pinned_) pinned.push({ app: app, score: best + 9999 })
                    else         scored.push({ app: app, score: best })
                }
            }
        }

        // Tri des épinglés par score (important si recherche active)
        pinned.sort(function(a, b) { return b.score - a.score })
        
        // Tri des non-épinglés : par score si recherche, sinon alphabétique
        if (q) {
            scored.sort(function(a, b) { return b.score - a.score })
        } else {
            scored.sort(function(a, b) { return a.app.name.localeCompare(b.app.name) })
        }

        // Épinglés en tête, puis le reste
        var all = pinned.concat(scored)

        resultsModel.clear()
        for (var j = 0; j < all.length; j++) {
            var e = all[j]
            resultsModel.append({
                appIcon:   e.app.icon,
                appName:   e.app.name,
                appCat:    e.app.cat,
                appCmd:    e.app.cmd,
                appPinned: isPinned(e.app.cmd)
            })
        }
        selectedIndex = resultsModel.count > 0 ? 0 : -1
    }

    // ─── Lancement d'application ───────────────────────────────
    property Process launchProc: Process {
        id: _launchProc
        running: false
        command: ["bash", "-c", "true"]
    }



    function launchApp(cmd) {
        if (!cmd) return

        // Actions spéciales
        if (cmd === "__settings__") { console.log("BeeSearch: openSettings émis"); beeSearch.openSettings(); beeSearch.hide(); return }
        if (cmd === "__studio__")   { beeSearch.openStudio();   beeSearch.hide(); return }

        // Émettre la commande vers shell.qml qui gère le lancement
        // après destruction du Loader (timer dans shell.qml, hors du Loader)
        beeSearch.launchRequested(cmd)
    }

    ListModel { id: resultsModel }

    // ─── Animation overlay ────────────────────────────────────
    visible: true
    enabled: shown  // ← Désactive tous les MouseArea quand fermé
    opacity: shown ? 1.0 : 0.0
    scale:   shown ? 1.0 : 0.92

    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutBack  } }

    // ─── Backdrop sombre — visible UNIQUEMENT quand menu ouvert ─
    Rectangle {
        anchors.fill: parent
        color: BeeTheme.backdropBg
        visible: beeSearch.shown
        MouseArea { anchors.fill: parent; onClicked: beeSearch.hide() }
    }

    // ─── Panneau principal ────────────────────────────────────
    Rectangle {
        id: searchPanel
        width: 560
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:       parent.top
        anchors.topMargin: parent.height * 0.15
        height: _mainCol.implicitHeight + 20
        radius: 22
        color: Qt.rgba(BeeTheme.glassBg.r, BeeTheme.glassBg.g, BeeTheme.glassBg.b, 0.94)
        border.color: searchInput.activeFocus
            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.65)
            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.22)
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 250 } }

        // Bouton fermeture (Top Right)
        Rectangle {
            id: closeRect
            anchors { right: parent.right; top: parent.top; margins: 10 }
            z: 100
            width: 28; height: 28; radius: 14
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
                font { pixelSize: 12; bold: true }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: closeHov; anchors.fill: parent
                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: beeSearch.hide()
            }
        }

        // Outer glow pulsé (actif quand le champ a le focus)
        Rectangle {
            anchors { fill: parent; margins: -10 }
            radius: parent.radius + 10
            color: "transparent"
            border.width: 10
            border.color: Qt.rgba(
                BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b,
                searchInput.activeFocus ? (0.05 + 0.06 * BeeTheme._glowPhase) : 0.0
            )
            Behavior on border.color { ColorAnimation { duration: 350 } }
        }

        // Ligne de glow supérieure — s'intensifie au focus
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 30 }
            height: 1; radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.35; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, searchInput.activeFocus ? 0.85 : 0.4) }
                GradientStop { position: 0.65; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, searchInput.activeFocus ? 0.85 : 0.4) }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }

        Column {
            id: _mainCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            spacing: 0

            // ─── Zone de saisie ───────────────────────────────
            Item {
                width: parent.width
                height: 70

                Text {
                    id: _searchIcon
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter; verticalCenterOffset: 8 }
                    text: beeSearch.scanning ? "⏳" : "🔍"
                    font.pixelSize: 20
                    opacity: 0.85
                }

                TextInput {
                    id: searchInput
                    anchors { left: _searchIcon.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter; verticalCenterOffset: 8 }
                    height: 42
                    color: BeeTheme.textPrimary
                    selectionColor: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
                    font.pixelSize: 19
                    font.weight: Font.Light
                    clip: true
                    focus: beeSearch.shown

                    // Placeholder dynamique
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: beeSearch.scanning
                            ? ((BeeConfig.tr.search && BeeConfig.tr.search.loading)   || "Chargement des applications…")
                            : ((BeeConfig.tr.search && BeeConfig.tr.search.placeholder) || "Rechercher une application…")
                        color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.42)
                        font.pixelSize: 18
                        font.weight: Font.Light
                        visible: searchInput.text.length === 0
                    }

                    onTextChanged: beeSearch.filterApps(searchInput.text)

                    Keys.onEscapePressed: (event) => beeSearch.hide()
                    Keys.onReturnPressed: (event) => {
                        if (beeSearch.selectedIndex >= 0 && beeSearch.selectedIndex < resultsModel.count)
                            beeSearch.launchApp(resultsModel.get(beeSearch.selectedIndex).appCmd)
                    }
                    Keys.onUpPressed: (event) => {
                        beeSearch.selectedIndex = beeSearch.selectedIndex > 0
                            ? beeSearch.selectedIndex - 1
                            : resultsModel.count - 1
                    }
                    Keys.onDownPressed: (event) => {
                        beeSearch.selectedIndex = beeSearch.selectedIndex < resultsModel.count - 1
                            ? beeSearch.selectedIndex + 1
                            : 0
                    }
                    Keys.onTabPressed: (event) => {
                        beeSearch.selectedIndex = (beeSearch.selectedIndex + 1) % Math.max(1, resultsModel.count)
                        event.accepted = true
                    }
                }
            }

            // Séparateur accent
            Rectangle {
                width: parent.width; height: 1
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                visible: resultsModel.count > 0
            }

            // ─── Résultats (Scrollable) ───────────────────────
            ListView {
                id: resultsList
                width: parent.width
                height: Math.min(resultsModel.count, 8) * 54
                model: resultsModel
                currentIndex: beeSearch.selectedIndex
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    width: 4; policy: resultsModel.count > 8 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    contentItem: Rectangle { radius: 2; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3) }
                }

                delegate: Item {
                    id: _row
                    width: resultsList.width
                    height: 54

                    property bool isSelected: index === beeSearch.selectedIndex
                    property bool hovered:    false
                    property bool pinned:     appPinned

                    // Fond sélection / hover
                    Rectangle {
                        anchors { fill: parent; leftMargin: 2; rightMargin: 6; topMargin: 1; bottomMargin: 1 }
                        radius: 13
                        color: _row.isSelected
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.16)
                            : _row.hovered
                                ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 110 } }

                        // Barre d'accent gauche (sélection active)
                        Rectangle {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            width: 3; height: 28; radius: 2
                            color: BeeTheme.accent
                            opacity: _row.isSelected ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered:  { _row.hovered = true; beeSearch.selectedIndex = index }
                        onExited:     _row.hovered = false
                        onClicked: beeSearch.launchApp(appCmd)
                    }

                    // Icône émoji
                    Text {
                        id: _appIcon
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        text: appIcon
                        font.pixelSize: 22
                    }

                    // Nom + catégorie
                    Column {
                        anchors { left: _appIcon.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        Text {
                            text: appName
                            color: BeeTheme.textPrimary
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: appCat
                            color: BeeTheme.textSecondary
                            font.pixelSize: 11
                            opacity: 0.65
                        }
                    }

                    // ─── Bouton Pin 📌 (apparaît au hover) ───────────────
                    Rectangle {
                        id: _pinBtn
                        z: 2
                        anchors { right: parent.right; rightMargin: 60; verticalCenter: parent.verticalCenter }
                        width: 28; height: 28; radius: 8
                        color: _row.pinned
                            ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.22)
                            : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, _row.pinned ? 0.5 : 0.2)
                        border.width: 1
                        opacity: (_row.hovered || _row.pinned) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "📌"
                            font.pixelSize: 13
                            opacity: _row.pinned ? 1.0 : 0.55
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                mouse.accepted = true
                                beeSearch.togglePin(appCmd)
                            }
                        }
                    }

                    // Badge ↵ (visible uniquement sur l'item sélectionné)
                    Rectangle {
                        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        width: 36; height: 20; radius: 6
                        color:  Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.30)
                        border.width: 1
                        opacity: _row.isSelected ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "↵"; color: BeeTheme.accent; font.pixelSize: 13 }
                    }
                }

                // Assure que l'item sélectionné est toujours visible lors de la navigation clavier
                onCurrentIndexChanged: resultsList.positionViewAtIndex(currentIndex, ListView.Contain)
            }

            // ─── État vide ────────────────────────────────────
            Item {
                width: parent.width; height: 56
                visible: resultsModel.count === 0 && searchInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: ((BeeConfig.tr.search && BeeConfig.tr.search.no_results) || "Aucun résultat pour")
                          + " «" + searchInput.text + "»"
                    color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.5)
                    font.pixelSize: 13
                }
            }

            Item { width: 1; height: 12 }
        }

        // Hint clavier (bas droite du panneau)
        Text {
            anchors { bottom: parent.bottom; right: parent.right; margins: 9 }
            text: (BeeConfig.tr.search && BeeConfig.tr.search.hint) || "↑↓/Tab naviguer  ↵ lancer  Esc fermer"
            color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.30)
            font.pixelSize: 10
        }
    }

    // ─── Init ─────────────────────────────────────────────────
    Component.onCompleted: {
        filterApps("")
    }

    onShownChanged: {
        if (shown) filterApps(searchInput.text)
    }
}
