import QtQuick
import QtQuick.Controls
import QtCore
import "."

// ═══════════════════════════════════════════════════════════════
// BeeEvents.qml — Prochains événements du calendrier 🐝📅
// Sprint v0.7.2 — Filtrage strict : événements du jour uniquement
// Widget flottant : événements d'aujourd'hui (sync_events.py)
// Positionnement : bas-gauche, au-dessus de la barre Hyprland
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeEvents

    // ─── Visibilité pilotée par BeeConfig ─────────────────────
    visible: BeeConfig.eventsEnabled
    opacity: 0.0  // Géré exclusivement par les animations
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    width:  300
    height: eventsColumn.implicitHeight + 28

    // ─── Real data — Loaded from JSON ──────────────────────────
    ListModel {
        id: eventsModel
    }

    // ─── Footer hover state property ──────────────────
    property bool footerHovered: false

    readonly property int maxEvents: 6

    function loadEvents() {
        var fallbackDone = false;
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState !== XMLHttpRequest.DONE) return;

            // Fallback unique vers le fichier statique local — flag évite la boucle infinie
            var tryFallback = function() {
                if (fallbackDone) {
                    console.warn("BeeEvents: Fallback déjà tenté, abandon.");
                    eventsModel.clear();
                    return;
                }
                fallbackDone = true;
                // Fallback direct vers le chemin par défaut de BeeConfig au lieu du vieux events.json
                var fallbackPath = "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/beehive_os/data/events_live.json";
                console.log("BeeEvents: Fallback sur", fallbackPath);
                doc.open("GET", fallbackPath);
                doc.send();
            };

            if (doc.status !== 200 && doc.status !== 0) {
                console.log("BeeEvents: Échec chargement (status", doc.status, "), tentative fallback.");
                tryFallback();
                return;
            }

            var text = doc.responseText.trim();
            if (text === "") {
                tryFallback();
                return;
            }

            try {
                var data = JSON.parse(text);
                // Support format v2 (objet avec events[]) et v1 (tableau direct)
                var eventsArray = Array.isArray(data) ? data : (data.events || []);

                if (data._meta) {
                    BeeConfig.liveSyncMeta = data._meta;
                }

                // Filtre : Prochains événements (à partir de maintenant)
                var nowTs = new Date().getTime() / 1000;
                var upcoming = eventsArray.filter(function(e) {
                    if (!e.timestamp) return false;
                    return e.timestamp >= (nowTs - 3600); // Garder les événements commencés il y a moins d'une heure
                });
                eventsModel.clear();
                var limit = Math.min(upcoming.length, maxEvents);
                for (var i = 0; i < limit; i++) {
                    eventsModel.append({
                        evtIcon:   upcoming[i].icon  || "📅",
                        evtTitle:  upcoming[i].title || "Événement",
                        evtTime:   upcoming[i].time  || "",
                        evtSub:    upcoming[i].sub   || "",
                        evtUrgent: upcoming[i].urgent === true
                    });
                }
                // Mettre à jour le compteur pour la cellule dashboard
                BeeConfig.liveSyncCount = upcoming.length;
            } catch(e) {
                console.warn("BeeEvents: Erreur parsing JSON:", e);
                eventsModel.clear();
            }
        }
        // V2: lecture depuis le chemin live du daemon, fallback sur données statiques
        var path = BeeConfig.eventsLivePath || Qt.resolvedUrl("../data/events.json");
        doc.open("GET", path);
        doc.send();
    }

    // ─── Connexion IPC pour rafraîchissement instantané ───────
    Connections {
        target: BeeConfig
        function onEventsReloadRequested() {
            loadEvents();
        }
        // Déclenche la sync et le rechargement une fois la config disponible.
        function onConfigLoaded() {
            runSync();
            reloadAfterSync.restart();
        }
    }

    // ─── Fond glassmorphism ───────────────────────────────────
    Rectangle {
        id: glassBg
        anchors.fill: parent
        radius: 18
        color: BeeTheme.glassBg
        border.color: Qt.rgba(
            BeeTheme.accent.r,
            BeeTheme.accent.g,
            BeeTheme.accent.b,
            BeeTheme.mode === "HoneyDark" ? 0.28 : 0.45
        )
        border.width: 1

        // Glow subtil sur la bordure supérieure
        Rectangle {
            anchors.top:  parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin:  32
            anchors.rightMargin: 32
            height: 1
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.35; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.45) }
                GradientStop { position: 0.65; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.45) }
                GradientStop { position: 1.0;  color: "transparent" }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.4;  duration: 2800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 2800; easing.type: Easing.InOutSine }
            }
        }
    }

    // ─── Contenu ──────────────────────────────────────────────
    Column {
        id: eventsColumn
        anchors {
            left:   parent.left
            right:  parent.right
            top:    parent.top
            margins: 14
        }
        spacing: 0

        // En-tête
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "📅"
                font.pixelSize: 15
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: (BeeConfig.tr.events && BeeConfig.tr.events.upcoming) || "Upcoming events"
                color: BeeTheme.accent
                font.pixelSize: 12
                font.weight: Font.Medium
                font.letterSpacing: 0.8
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item { width: 1; height: 10 }

        // Séparateur
        Rectangle {
            width:  parent.width
            height: 1
            color:  Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
        }

        Item { width: 1; height: 4 }

        // Liste des prochains événements
        Repeater {
            model: eventsModel

            delegate: Item {
                width: parent.width
                height: 44

                // Icône
                Text {
                    id: evtIconLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.evtIcon
                    font.pixelSize: 18
                }

                // Titre + heure + sous-titre
                Column {
                    anchors.left: evtIconLabel.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: model.evtTitle
                        elide: Text.ElideRight
                        color: model.evtUrgent ? BeeTheme.accent : BeeTheme.textPrimary
                        font.pixelSize: 12
                        font.weight: model.evtUrgent ? Font.Bold : Font.Normal
                    }

                    Row {
                        spacing: 4
                        Text {
                            text: model.evtTime
                            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.85)
                            font.pixelSize: 10
                        }
                        Text {
                            visible: model.evtSub !== ""
                            text: "·  " + model.evtSub
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.50)
                            font.pixelSize: 10
                        }
                    }
                }

                // Séparateur entre événements (sauf le dernier)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 26
                    height: 1
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.10)
                    visible: index < eventsModel.count - 1
                }
            }
        }

        // Placeholder si vide
        Text {
            visible: eventsModel.count === 0
            width: parent.width
            height: 40
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            text: (BeeConfig.tr.events && BeeConfig.tr.events.no_events) || "No upcoming events 🍯"
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.45)
            font.pixelSize: 11
            font.italic: true
        }

        // Pied — lien discret
        Item { width: 1; height: 6 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (BeeConfig.tr.events && BeeConfig.tr.events.see_calendar) || "See calendar →"
            color: beeEvents.footerHovered
                ? BeeTheme.accent
                : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.45)
            font.pixelSize: 10
            Behavior on color { ColorAnimation { duration: 160 } }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: beeEvents.footerHovered = true
                onExited:  beeEvents.footerHovered = false
                onClicked: Qt.createQmlObject(
                    'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "xdg-open \'https://calendar.google.com\' ; sleep 0.5 && hyprctl dispatch focuswindow class:zen"] }',
                    beeEvents, "calOpen"
                )
            }
        }
        Item { width: 1; height: 2 }
    }

    // ─── Apparition initiale (scale + fade) ───────────────────
    scale: visible ? 1.0 : 0.92
    Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

    // ─── Sync : lance bee_sync.py pour tout synchroniser (Google + ICS) ──
    function runSync() {
        Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["python3", Qt.resolvedUrl("../scripts/bee_sync.py").toString().replace("file://", "")] }',
            beeEvents, "beeSync"
        )
    }

    // ─── Auto-refresh timer (every 15 minutes) ────────────────
    Timer {
        id: refreshTimer
        interval: 900000  // 15 minutes
        running: true
        repeat: true
        onTriggered: {
            runSync()
            Qt.callLater(loadEvents)
        }
    }

    // ─── Timer pour recharger après sync (délai 3s) ──────
    Timer {
        id: reloadAfterSync
        interval: 3000
        repeat: false
        onTriggered: loadEvents()
    }

    Component.onCompleted: {
        scale = 0.92
        // Charge immédiatement les données en cache (si présentes) pour un affichage instantané.
        // La sync ICS et le rechargement "propre" se font dans onConfigLoaded() après le XHR async.
        loadEvents()
        appearAnim.start()
    }

    SequentialAnimation {
        id: appearAnim
        PauseAnimation   { duration: 420 }
        ParallelAnimation {
            NumberAnimation { target: beeEvents; property: "opacity"; to: 1.0; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: beeEvents; property: "scale";   to: 1.0; duration: 500; easing.type: Easing.OutBack  }
        }
    }
}
