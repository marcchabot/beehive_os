import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io
import "."

// ═══════════════════════════════════════════════════════════════
// BeeWelcome.qml — First Run Welcome Screen 🐝🍯
// Shown on first launch to guide the user through setup
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: welcomeRoot
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.75)   // Overlay sombre

    signal dismissed()

    // ─── Vérification first run ────────────────────────────
    // Le fichier .bee_welcomed est créé au premier lancement
    // S'il existe déjà, on ne montre pas cet écran

    // ─── Carte centrale ────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 560; height: 560
        radius: 28
        color: BeeTheme.mode === "HoneyDark"
            ? Qt.rgba(0.06, 0.05, 0.08, 0.97)
            : Qt.rgba(0.97, 0.95, 0.91, 0.97)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0,0,0,0.5)
            shadowBlur: 1.0
            shadowVerticalOffset: 8
        }

        // Apparition animée
        scale: 0.88; opacity: 0
        Component.onCompleted: appearAnim.start()
        ParallelAnimation {
            id: appearAnim
            NumberAnimation { target: card; property: "scale";   to: 1.0; duration: 450; easing.type: Easing.OutBack }
            NumberAnimation { target: card; property: "opacity"; to: 1.0; duration: 350; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 40 }
            spacing: 0

            // ─── Header ──────────────────────────────────
            Text {
                text: "🐝"; font.pixelSize: 52
                Layout.alignment: Qt.AlignHCenter
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.12; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
                }
            }
            Item { height: 10 }
            Text {
                text: "Welcome to Bee-Hive OS"
                color: BeeTheme.accent
                font { bold: true; pixelSize: 26; letterSpacing: 0.5 }
                Layout.alignment: Qt.AlignHCenter
            }
            Item { height: 6 }
            Text {
                text: "Your hive is almost ready! Add these keybinds\nto your hyprland.conf to unlock everything."
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.6)
                font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap; Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }

            Item { height: 22 }

            // ─── Keybinds list ────────────────────────────
            Rectangle {
                Layout.fillWidth: true; radius: 14
                height: keybindsCol.implicitHeight + 24
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18)
                border.width: 1

                Column {
                    id: keybindsCol
                    anchors { fill: parent; margins: 12 }
                    spacing: 8

                    Repeater {
                        model: [
                            { keys: "Super + D",      desc: "🍯 Toggle Dashboard" },
                            { keys: "Super + Z",      desc: "🔍 App Launcher (BeeSearch)" },
                            { keys: "Super + Escape", desc: "⚙️  The Hive (Control Center)" },
                            { keys: "Super + P",      desc: "⏻  Power Menu" },
                            { keys: "Super + F12",    desc: "🌙 Toggle Dark / Light Theme" },
                        ]
                        RowLayout {
                            width: keybindsCol.width; spacing: 12
                            Rectangle {
                                width: 140; height: 28; radius: 8
                                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.keys
                                    color: BeeTheme.accent
                                    font { pixelSize: 12; bold: true }
                                }
                            }
                            Text {
                                text: modelData.desc
                                color: BeeTheme.textPrimary
                                font.pixelSize: 13
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            Item { height: 18 }

            // ─── Source hint ──────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 38; radius: 10
                color: Qt.rgba(0, 0, 0, 0.25)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1
                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                    Text {
                        text: "source = ~/beehive_os/config/beehive_keybinds.conf"
                        color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.9)
                        font { pixelSize: 11; family: "monospace" }
                        Layout.fillWidth: true
                    }
                    // Copy button
                    Rectangle {
                        width: 65; height: 26; radius: 8
                        color: copyHov.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.25) : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.1)
                        border.color: BeeTheme.accent; border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { id: copyLabel; anchors.centerIn: parent; text: parent.copied ? "✓ Done" : "📋 Copy"; color: BeeTheme.accent; font { pixelSize: 11; bold: true } }
                        property bool copied: false
                        MouseArea {
                            id: copyHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Qt.createQmlObject(
                                    'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "printf \'source = ~/beehive_os/config/beehive_keybinds.conf\' | wl-copy"] }',
                                    copyHov, "clipCopy"
                                )
                                parent.copied = true
                                copyReset.start()
                            }
                        }
                        Timer { id: copyReset; interval: 2000; onTriggered: parent.copied = false }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ─── CTA Button ───────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 46; radius: 14
                color: ctaHov.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35) : Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.color: BeeTheme.accent; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "🍯 Let's go! Open my Hive"
                    color: BeeTheme.accent
                    font { bold: true; pixelSize: 15; letterSpacing: 0.5 }
                }
                MouseArea {
                    id: ctaHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Crée le dossier ET le fichier marker → ne plus jamais afficher
                        Qt.createQmlObject(
                            'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "mkdir -p ~/.config/beehive && touch ~/.config/beehive/.bee_welcomed"] }',
                            welcomeRoot, "markWelcome"
                        )
                        welcomeRoot.dismissed()
                    }
                }
            }
        }
    }
}
