import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════
// BeeVoice.qml — Maya AI Assistant Vocal Overlay 🐝🎤
// v1.0 : Super+M overlay — Whisper STT → Ollama → ElevenLabs TTS
//
// Architecture:
//   • Process-based pipeline via scripts/bee-voice.sh
//   • States: idle → listening → transcribing → thinking → speaking → done
//   • Glass morphism panel matching BeeTheme
//   • Animated mic waveform while listening
//   • Streaming text display for transcription + response
//   • Auto-dismiss after response with fade-out
//   • Escape key to cancel at any point
//
// Triggered via IPC: quickshell ipc call root toggleVoiceAssistant
// ═══════════════════════════════════════════════════════════════

Item {
    id: voiceRoot

    // ─── Public API ──────────────────────────────────────────
    property bool active: false
    property string state: "idle"    // idle, listening, transcribing, thinking, speaking, done, error
    property string transcript: ""
    property string response: ""
    property string errorMessage: ""

    // ─── Config (synced from BeeConfig) ──────────────────────
    property string ollamaModel: BeeConfig.voiceOllamaModel
    property string ollamaUrl: BeeConfig.voiceOllamaUrl
    property string elevenlabsVoice: BeeConfig.voiceElevenlabsVoiceId
    property string elevenlabsModel: BeeConfig.voiceElevenlabsModelId
    property string ttsBackend: BeeConfig.voiceTtsBackend  // "elevenlabs", "edge-tts", or "local"
    property string edgeTtsVoice: BeeConfig.voiceEdgeTtsVoice  // e.g. "fr-CA-SylvieNeural"
    property string edgeTtsRate: BeeConfig.voiceEdgeTtsRate     // e.g. "+0%"
    property int recordDuration: BeeConfig.voiceRecordDuration
    property string whisperModel: BeeConfig.voiceWhisperModel

    // ─── Internal ────────────────────────────────────────────
    property real _micLevel: 0.0
    property int _wavePhase: 0

    // ─── Show / Hide ─────────────────────────────────────────
    function show() {
        active = true
        state = "idle"
        transcript = ""
        response = ""
        errorMessage = ""
        startPipeline()
    }

    signal hideRequested()

    // Auto-start pipeline when activated by parent (e.g. via Loader)
    onActiveChanged: {
        if (active && state === "idle") {
            startPipeline()
        }
    }

    function hide() {
        active = false
        voiceProc.running = false
        micProc.running = false
        state = "idle"
        hideRequested()
    }

    function toggle() {
        if (active) hide()
        else show()
    }

    // ─── Pipeline ────────────────────────────────────────────
    function startPipeline() {
        voiceProc.running = false
        state = "listening"
        transcript = ""
        response = ""

        // Pass TTS backend and edge-tts voice to the shell script via environment
        var envPrefix = '';
        if (voiceRoot.ttsBackend) envPrefix += 'BEE_TTS_BACKEND=' + voiceRoot.ttsBackend + ' ';
        if (voiceRoot.edgeTtsVoice) envPrefix += 'BEE_EDGE_TTS_VOICE=' + voiceRoot.edgeTtsVoice + ' ';
        if (voiceRoot.edgeTtsRate) envPrefix += 'BEE_EDGE_TTS_RATE=' + voiceRoot.edgeTtsRate + ' ';

        voiceProc.command = [
            "bash",
            "-c",
            envPrefix + "cd ~/beehive_os && bash scripts/bee-voice.sh " + recordDuration
        ]
        voiceProc.running = true

        // Start mic level simulation
        micProc.running = true
    }

    // ─── Mic level simulation ────────────────────────────────
    Process {
        id: micProc
        running: false
        command: ["bash", "-c", "while true; do printf '%.2f\\n' $(echo \"scale=2; 0.3 + $RANDOM % 50 / 100\" | bc); sleep 0.08; done"]
        stdout: SplitParser {
            onRead: (line) => {
                if (voiceRoot.state === "listening") {
                    var val = parseFloat(line.trim())
                    if (!isNaN(val)) voiceRoot._micLevel = val
                }
            }
        }
    }

    // ─── Main voice pipeline process ─────────────────────────
    Process {
        id: voiceProc
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                // stdout now only carries data, not state JSON
                var trimmed = line.trim()
                if (!trimmed) return

                // If it looks like raw text during transcription, capture it
                if (voiceRoot.state === "transcribing" && trimmed) {
                    voiceRoot.transcript = trimmed
                }
            }
        }

        stderr: SplitParser {
            onRead: (line) => {
                var trimmed = line.trim()
                if (!trimmed) return

                // JSON state lines come via stderr now
                try {
                    var json = JSON.parse(trimmed)
                    if (json.state) {
                        voiceRoot.state = json.state
                        if (json.text) {
                            if (json.state === "transcribed") {
                                voiceRoot.transcript = json.text
                            } else if (json.state === "responded" || json.state === "done") {
                                voiceRoot.response = json.text
                            } else if (json.state === "error") {
                                voiceRoot.errorMessage = json.text
                            }
                        }
                        // Stop mic level when not listening
                        if (json.state !== "listening") {
                            micProc.running = false
                            voiceRoot._micLevel = 0
                        }
                        // Auto-dismiss after done
                        if (json.state === "done") {
                            dismissTimer.start()
                        }
                    }
                } catch (e) {
                    // Non-JSON stderr — just log it
                    console.log("BeeVoice:", trimmed)
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0 && voiceRoot.state !== "done" && voiceRoot.state !== "idle") {
                voiceRoot.state = "error"
                if (!voiceRoot.errorMessage) voiceRoot.errorMessage = "Pipeline exited with code " + code
            }
            micProc.running = false
            voiceRoot._micLevel = 0
        }
    }

    // ─── Auto-dismiss timer ───────────────────────────────────
    Timer {
        id: dismissTimer
        interval: 4000
        repeat: false
        onTriggered: voiceRoot.hide()
    }

    // ─── Wave animation ───────────────────────────────────────
    Timer {
        id: waveTimer
        interval: 50
        repeat: true
        running: voiceRoot.active
        onTriggered: voiceRoot._wavePhase = (voiceRoot._wavePhase + 1) % 360
    }

    // ─── Visual Panel ─────────────────────────────────────────
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 460
        height: contentColumn.height + 50
        radius: 24
        color: BeeTheme.glassBg
        border.color: BeeTheme.glassBorder
        border.width: 1.5
        opacity: voiceRoot.active ? 1.0 : 0.0
        visible: opacity > 0.01

        // Glow
        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled:     true
            shadowEnabled:          true
            shadowColor:            BeeTheme.accent
            shadowBlur:             0.7
            shadowVerticalOffset:   0
            shadowHorizontalOffset: 0
        }

        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ─── Backdrop (click outside to dismiss) ─────────────
        MouseArea {
            anchors.fill: parent
            onClicked: voiceRoot.hide()
        }

        // ─── Content ──────────────────────────────────────────
        Column {
            id: contentColumn
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 24
            }
            spacing: 14
            width: panel.width - 48

            // ─── Header: 🐝 Maya + Status ─────────────────────
            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: "🐝"
                    font.pixelSize: 28
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: voiceRoot.state === "listening" ? qsTr("En écoute…")
                          : voiceRoot.state === "transcribing" ? qsTr("Transcription…")
                          : voiceRoot.state === "thinking" ? qsTr("Maya réfléchit…")
                          : voiceRoot.state === "speaking" ? qsTr("Maya parle…")
                          : voiceRoot.state === "done" ? qsTr("🐝 Réponse")
                          : voiceRoot.state === "error" ? qsTr("Erreur")
                          : ""
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: BeeTheme.accent
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // ─── Mic Waveform (animated while listening) ───────
            Item {
                width: parent.width
                height: 40
                visible: voiceRoot.state === "listening"
                opacity: visible ? 1.0 : 0.0

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: 24
                        delegate: Rectangle {
                            width: 6
                            height: {
                                if (!voiceRoot.active || voiceRoot.state !== "listening") return 4
                                var phase = (voiceRoot._wavePhase + index * 15) % 360
                                var wave = Math.sin(phase * Math.PI / 180)
                                return Math.max(4, 4 + Math.abs(wave) * 28 * (0.3 + voiceRoot._micLevel * 0.7))
                            }
                            radius: 3
                            color: BeeTheme.accent
                            opacity: 0.7 + voiceRoot._micLevel * 0.3

                            Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 60 } }
                        }
                    }
                }
            }

            // ─── Spinning indicator (thinking) ─────────────────
            Item {
                width: parent.width
                height: 40
                visible: voiceRoot.state === "thinking" || voiceRoot.state === "transcribing"
                opacity: visible ? 1.0 : 0.0

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: 3
                        delegate: Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: BeeTheme.accent
                            opacity: {
                                var phase = (voiceRoot._wavePhase + index * 120) % 360
                                0.3 + 0.7 * Math.abs(Math.sin(phase * Math.PI / 180))
                            }
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }
                }
            }

            // ─── Transcript (what user said) ──────────────────
            Rectangle {
                width: parent.width
                height: transcriptText.implicitHeight + 16
                radius: 12
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                border.width: 1
                visible: voiceRoot.transcript !== ""

                Text {
                    id: transcriptText
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    text: "🗣️ " + voiceRoot.transcript
                    font.pixelSize: 14
                    color: BeeTheme.textPrimary
                    wrapMode: Text.WordWrap
                }
            }

            // ─── Response (Maya's answer) ─────────────────────
            Rectangle {
                width: parent.width
                height: responseText.implicitHeight + 16
                radius: 12
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.12)
                border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
                border.width: 1
                visible: voiceRoot.response !== ""

                Text {
                    id: responseText
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    text: "🐝 " + voiceRoot.response
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: BeeTheme.textPrimary
                    wrapMode: Text.WordWrap
                }
            }

            // ─── Error message ─────────────────────────────────
            Rectangle {
                width: parent.width
                height: errorText.implicitHeight + 16
                radius: 12
                color: Qt.rgba(1.0, 0.3, 0.3, 0.1)
                border.color: Qt.rgba(1.0, 0.3, 0.3, 0.3)
                border.width: 1
                visible: voiceRoot.errorMessage !== ""

                Text {
                    id: errorText
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    text: "⚠️ " + voiceRoot.errorMessage
                    font.pixelSize: 13
                    color: "#ff6b6b"
                    wrapMode: Text.WordWrap
                }
            }

            // ─── TTS Backend indicator ───────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                visible: voiceRoot.state === "idle" || voiceRoot.state === "done" || voiceRoot.state === "error"
                opacity: visible ? 0.5 : 0

                Text {
                    text: voiceRoot.ttsBackend === "elevenlabs" ? "🎙️ Premium"
                          : voiceRoot.ttsBackend === "edge-tts" ? "🔊 Edge TTS"
                          : "🔊 Local"
                    font.pixelSize: 10
                    color: BeeTheme.textSecondary
                }
            }

            // ─── Hint text ─────────────────────────────────────
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: voiceRoot.state === "listening"
                      ? qsTr("Parle maintenant…")
                      : voiceRoot.state === "done"
                      ? qsTr("Appuie sur Esc pour fermer")
                      : ""
                font.pixelSize: 12
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
                visible: text !== ""
            }
        }
    }

    // ─── Key handler: Escape to dismiss ───────────────────────
    Keys.onEscapePressed: voiceRoot.hide()
    Keys.onReturnPressed: {
        // Re-trigger if idle
        if (voiceRoot.state === "done" || voiceRoot.state === "error") {
            voiceRoot.show()
        }
    }

    // ─── Play sound on state transitions ─────────────────────
    onStateChanged: {
        if (state === "listening") {
            BeeSound.playEvent("dash.open", {})
        } else if (state === "done" || state === "idle") {
            BeeSound.playEvent("dash.close", {})
        } else if (state === "error") {
            BeeSound.playEvent("system.error", {})
        }
    }
}