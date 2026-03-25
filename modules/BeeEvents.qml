import QtQuick
import QtQuick.Controls
import "."

// ═══════════════════════════════════════════════════════════════
// BeeEvents.qml — Prochains événements du calendrier 🐝📅
// Sprint v0.7.1 — Optimisation robustesse JSON + filtrage date
// Widget flottant : 3 prochains rendez-vous (sync_events.py)
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
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState === XMLHttpRequest.DONE) {
                // Si le statut est une erreur (ex: 404), on tente le fallback sur le fichier local statique
                if (doc.status !== 200 && doc.status !== 0) {
                    var staticPath = Qt.resolvedUrl("../data/events.json");
                    if (doc.responseURL !== staticPath) {
                        console.log("BeeEvents: Échec chargement path live, tentative fallback sur", staticPath);
                        doc.open("GET", staticPath);
                        doc.send();
                        return;
                    }
                }

                if (doc.status === 200 || doc.status === 0) {
                    try {
                        var text = doc.responseText.trim();
                        if (text === "") {
                            eventsModel.clear();
                            return;
                        }
                        var data = JSON.parse(text);
                        // ... rest of the logic ...
                        // Support format v2 (objet avec events[]) et v1 (tableau direct)
                        var eventsArray = Array.isArray(data) ? data : (data.events || []);

                        // Mettre à jour les métadonnées de sync
                        if (data._meta) {
                            BeeConfig.liveSyncMeta = data._meta;
                        }

                        var nowSec = Date.now() / 1000;
                        // Filtre : événements dans les 30 dernières minutes ou futurs
                        var upcoming = eventsArray.filter(function(e) {
                            return !e.timestamp || e.timestamp >= nowSec - 1800;
                        });
                        eventsModel.clear();
                        var limit = Math.min(upcoming.length, maxEvents);
                        for (var i = 0; i < limit; i++) {
                            eventsModel.append({
                                evtIcon:   upcoming[i].icon  || "📅",
                                evtTitle:  upcoming[i].title || "Événement",
                                evtTime:   upcoming[i].time  || "",
                                evtSub:    upcoming[i].sub   || "",
                                evtUrgent: upcoming[i].urge === true || upcoming[i].urgent === true
                            });
                        }
                        // Mettre à jour le compteur pour la cellule dashboard
                        BeeConfig.liveSyncCount = upcoming.length;
                    } catch(e) {
                        console.warn("BeeEvents: Erreur parsing JSON:", e);
                    }
                } else {
                    console.warn("BeeEvents: events.json load error, status:", doc.status);
                }
            }
        }
        // Qt.resolvedUrl résout le chemin relatif au fichier QML
        // V2: lecture depuis le chemin live de la config
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

        // Liste des 3 prochains événements
        Repeater {
            model: eventsModel

            delegate: Item {
                // ... (delegate code)
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

    // ─── ICS Sync : lance honey_sync_ics.py si icsUrl est définie ──
    function syncICS() {
        if (!BeeConfig.icsUrl || BeeConfig.icsUrl === "") return
        Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["python3", Qt.resolvedUrl("../scripts/honey_sync_ics.py").toString().replace("file://", "")] }',
            beeEvents, "icsSync"
        )
    }

    // ─── Auto-refresh timer (every 15 minutes) ────────────────
    Timer {
        id: refreshTimer
        interval: 900000  // 15 minutes
        running: true
        repeat: true
        onTriggered: {
            syncICS()
            Qt.callLater(loadEvents)
        }
    }

    // ─── Timer pour recharger après sync ICS (délai 3s) ──────
    Timer {
        id: reloadAfterSync
        interval: 3000
        repeat: false
        onTriggered: loadEvents()
    }

    Component.onCompleted: {
        scale = 0.92
        if (BeeConfig.icsUrl && BeeConfig.icsUrl !== "") {
            syncICS()
            reloadAfterSync.start()
        } else {
            loadEvents()
        }
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
