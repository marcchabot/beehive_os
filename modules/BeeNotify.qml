import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
// BeeNotify.qml — Bee-Hive OS notification system 🐝🔔
// Animations organiques, glassmorphism, positionnement intelligent
// ═══════════════════════════════════════════════════════════════

Item {
    id: notifyRoot
    width: 400
    height: 600

    // ─── Global Listener (BeeBarState) ─────────────────────
    Connections {
        target: BeeBarState
        function onNotificationReceived(title, body, icon) {
            notifyRoot.show(title, body, icon)
            BeeSound.play("notify")
        }
    }

    // ─── Data model ────────────────────────────────────────
    ListModel {
        id: notifyModel
    }

    // ─── Display function ──────────────────────────────────
    function show(title, body, icon = "🐝", type = "info") {
        notifyModel.insert(0, {
            "title": title,
            "body": body,
            "icon": icon,
            "type": type,
            "timestamp": new Date().toLocaleTimeString(Qt.locale("fr_CA"), "HH:mm")
        })
    }

    // ─── Timer de test (optionnel) ────────────────────────
    /*
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: show("System Alert", "The hive is buzzing with activity!", "🍯", "info")
    }
    */

    // ─── Notification list ─────────────────────────────────
    ListView {
        id: notifyList
        anchors.fill: parent
        spacing: 15
        model: notifyModel
        interactive: false

        delegate: Rectangle {
            id: notifyBox
            width: notifyRoot.width
            height: 90
            radius: 16
            clip: true   // ← prevents duration bar from overflowing rounded corners
            color: BeeTheme.mode === "HoneyDark"
                ? Qt.rgba(0.06, 0.05, 0.08, 0.93)
                : Qt.rgba(0.96, 0.94, 0.90, 0.95)
            border.color: type === "warning" ? "#FF4444" : BeeTheme.glassBorder
            border.width: 1

            // Drop shadow (BeeAura style)
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0,0,0, BeeTheme.mode === "HoneyDark" ? 0.4 : 0.1)
                shadowBlur: 0.5
                shadowVerticalOffset: 3
            }

            // ─── Entry/exit animation ──────────────────────
            SequentialAnimation {
                id: addAnim
                NumberAnimation { target: notifyBox; property: "x"; from: 450; to: 0; duration: 500; easing.type: Easing.OutBack }
            }
            ListView.onAdd: addAnim.start()

            SequentialAnimation {
                id: removeAnim
                PropertyAction { target: notifyBox; property: "ListView.delayRemove"; value: true }
                NumberAnimation { target: notifyBox; property: "opacity"; to: 0; duration: 300 }
                PropertyAction { target: notifyBox; property: "ListView.delayRemove"; value: false }
            }
            ListView.onRemove: removeAnim.start()

            // ─── Contenu ───────────────────────────────────
            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                // Icon with glow circle
                Item {
                    width: 50; height: 50
                    Rectangle {
                        anchors.fill: parent
                        radius: 25
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                        
                        // Emoji (if icon is short)
                        Text {
                            visible: icon.length <= 4
                            text: icon
                            font.pixelSize: 24
                            anchors.centerIn: parent
                        }

                        // Image / System icon (if it's a path or icon name)
                        Image {
                            visible: icon.length > 4
                            anchors.fill: parent
                            anchors.margins: 10
                            source: icon.startsWith("/") ? "file://" + icon : "image://icon/" + icon
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                    }
                }

                // Texte
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Text {
                            text: title
                            color: BeeTheme.textPrimary
                            font { bold: true; pixelSize: 14 }
                            Layout.fillWidth: true
                        }
                        Text {
                            text: timestamp
                            color: Qt.rgba(BeeTheme.textSecondary.r, BeeTheme.textSecondary.g, BeeTheme.textSecondary.b, 0.6)
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: body
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.75)
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }

            // ─── Barre de durée (autodestruction) ───────────
            // ⚠️ On utilise un Item conteneur pour ne pas toucher aux bords du Rectangle parent
            Item {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1   // petit retrait pour ne pas chevaucher le border
                height: 3

                Rectangle {
                    id: progressBar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: 2
                    color: BeeTheme.accent

                    PropertyAnimation on width {
                        from: progressBar.parent.width; to: 0; duration: 6000
                        onFinished: notifyModel.remove(index)
                    }
                }
            }

            // Fermeture au clic
            MouseArea {
                anchors.fill: parent
                onClicked: notifyModel.remove(index)
            }
        }
    }
}
