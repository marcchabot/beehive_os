import QtQuick
import QtQuick.Controls

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

    readonly property int maxEvents: 3

    function loadEvents() {
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState === XMLHttpRequest.DONE) {
                // status 0 = fichier local OK sous Qt, 200 = HTTP OK
                if (doc.status === 200 || doc.status === 0) {
                    try {
                        var data = JSON.parse(doc.responseText);
                        var nowSec = Date.now() / 1000;
                        // Filtre : événements dans les 30 dernières minutes ou futurs
                        var upcoming = data.filter(function(e) {
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
                                evtUrgent: upcoming[i].urgent === true
                            });
                        }
                    } catch(e) {
                        console.warn("BeeEvents: Erreur parsing JSON:", e);
                    }
                } else {
                    console.warn("BeeEvents: events.json load error, status:", doc.status);
                }
            }
        }
        // Qt.resolvedUrl résout le chemin relatif au fichier QML
        doc.open("GET", Qt.resolvedUrl("../data/events.json"));
        doc.send();
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
                id: evtRow
                width:  eventsColumn.width
                height: 54
                clip:   false

                property bool hovered: false

                // Fond hover
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin:  -4
                    anchors.rightMargin: -4
                    radius: 10
                    color: evtRow.hovered
                        ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.07)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: evtRow.hovered = true
                    onExited:  evtRow.hovered = false
                }

                // Indicateur urgence (bande gauche)
                Rectangle {
                    anchors.left:       parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width:  3
                    height: 32
                    radius: 2
                    color: evtUrgent
                        ? "#FF6B35"
                        : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.5)
                    visible: true
                }

                // Icône
                Text {
                    id: iconLabel
                    anchors.left:           parent.left
                    anchors.leftMargin:     12
                    anchors.verticalCenter: parent.verticalCenter
                    text:            evtIcon
                    font.pixelSize:  20
                }

                // Textes
                Column {
                    anchors.left:           iconLabel.right
                    anchors.leftMargin:     10
                    anchors.right:          timeLabel.left
                    anchors.rightMargin:    8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text:            evtTitle
                        color:           evtUrgent
                            ? "#FF9A6C"
                            : BeeTheme.textPrimary
                        font.pixelSize:  13
                        font.weight:     Font.Medium
                        elide:           Text.ElideRight
                        width:           parent.width
                    }
                    Text {
                        text:            evtSub
                        color:           BeeTheme.textSecondary
                        font.pixelSize:  10
                        elide:           Text.ElideRight
                        width:           parent.width
                        opacity:         0.75
                    }
                }

                // Heure (badge)
                Rectangle {
                    id: timeLabel
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin:    4
                    width:  52
                    height: 22
                    radius: 11
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text:            evtTime
                        color:           BeeTheme.accent
                        font.pixelSize:  11
                        font.weight:     Font.Medium
                    }
                }
            }
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

    Component.onCompleted: {
        scale = 0.92
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
