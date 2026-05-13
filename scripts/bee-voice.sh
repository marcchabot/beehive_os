#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# bee-voice.sh — Maya AI Assistant Vocal Pipeline 🐝🎤
# Bee-Hive OS — Orchestrator: Record → Whisper STT → Ollama → ElevenLabs TTS
#
# Output: JSON lines to stdout for QML BeeVoice module integration
# Each line: {"state":"<state>","text":"<text>"}
#
# States: listening, transcribing, thinking, speaking, done, error
#
# Usage:
#   bee-voice.sh                    # Full pipeline (default 6s recording)
#   bee-voice.sh 8                  # Full pipeline with 8s recording
#   bee-voice.sh --config           # Print current config as JSON
# ═══════════════════════════════════════════════════════════════

set -uo pipefail
# Note: removed -e to prevent premature exit on transient curl/jq failures
# Individual functions handle errors explicitly

# ─── Configuration ───────────────────────────────────────────
BEE_DIR="$HOME/.config/beehive/assistant"
RECORD_DIR="$BEE_DIR/recordings"
TTS_DIR="$BEE_DIR/tts"
CONFIG_FILE="$BEE_DIR/config.json"
BEEHIVE_CONFIG="$HOME/beehive_os/user_config.json"

# Defaults (overridden by config file + env vars)
OLLAMA_MODEL="gemma4:31b-cloud"
OLLAMA_URL="http://127.0.0.1:11434"
ELEVENLABS_VOICE="BpjGufoPiobT79j2vtj4"
ELEVENLABS_MODEL="eleven_flash_v2_5"
ELEVENLABS_API_KEY="4906405d881f4883d3acf9aa69e7cdaad9312b6952cb7043bae6bef6020c0f62"
MIC_DEVICE="default"
RECORD_DURATION="6"
SAMPLE_RATE="16000"
WHISPER_MODEL="tiny"
TTS_BACKEND="edge-tts"
EDGE_TTS_VOICE="fr-CA-SylvieNeural"
EDGE_TTS_RATE="+0%"
OLLAMA_FALLBACK="glm-5.1:cloud"

# Load Bee-Hive OS user_config.json if available
if [ -f "$BEEHIVE_CONFIG" ] && command -v jq &>/dev/null; then
    OLLAMA_MODEL="$(jq -r '.bee_voice.ollama_model // "glm-5.1:cloud"' "$BEEHIVE_CONFIG" 2>/dev/null)"
    OLLAMA_URL="$(jq -r '.bee_voice.ollama_url // "http://127.0.0.1:11434"' "$BEEHIVE_CONFIG" 2>/dev/null)"
    ELEVENLABS_VOICE="$(jq -r '.bee_voice.elevenlabs_voice_id // "BpjGufoPiobT79j2vtj4"' "$BEEHIVE_CONFIG" 2>/dev/null)"
    ELEVENLABS_MODEL="$(jq -r '.bee_voice.elevenlabs_model_id // "eleven_flash_v2_5"' "$BEEHIVE_CONFIG" 2>/dev/null)"
    TTS_BACKEND="$(jq -r '.bee_voice.tts_backend // "edge-tts"' "$BEEHIVE_CONFIG" 2>/dev/null)"
    RECORD_DURATION="$(jq -r '.bee_voice.record_duration // 6' "$BEEHIVE_CONFIG" 2>/dev/null)"
    WHISPER_MODEL="$(jq -r '.bee_voice.whisper_model // "tiny"' "$BEEHIVE_CONFIG" 2>/dev/null)"
    OLLAMA_FALLBACK="$(jq -r '.bee_voice.ollama_fallback // "gemma4:31b-cloud"' "$BEEHIVE_CONFIG" 2>/dev/null)"
fi

# Override with local assistant config if available
if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
    _val=$(jq -r '.ollama_model // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && OLLAMA_MODEL="$_val"
    _val=$(jq -r '.ollama_url // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && OLLAMA_URL="$_val"
    _val=$(jq -r '.elevenlabs_voice_id // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && ELEVENLABS_VOICE="$_val"
    _val=$(jq -r '.elevenlabs_model_id // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && ELEVENLABS_MODEL="$_val"
    _val=$(jq -r '.tts_backend // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && TTS_BACKEND="$_val"
    _val=$(jq -r '.edge_tts_voice // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && EDGE_TTS_VOICE="$_val"
    _val=$(jq -r '.edge_tts_rate // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && EDGE_TTS_RATE="$_val"
    _val=$(jq -r '.record_duration // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && RECORD_DURATION="$_val"
    _val=$(jq -r '.whisper_model // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && WHISPER_MODEL="$_val"
    _val=$(jq -r '.elevenlabs_api_key // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && ELEVENLABS_API_KEY="$_val"
    _val=$(jq -r '.ollama_fallback // empty' "$CONFIG_FILE" 2>/dev/null) || _val=""
    [ -n "$_val" ] && OLLAMA_FALLBACK="$_val"
fi

# Environment variables override all configs
[ -n "${BEE_ASSISTANT_MODEL:-}" ] && OLLAMA_MODEL="$BEE_ASSISTANT_MODEL"
[ -n "${BEE_ASSISTANT_URL:-}" ] && OLLAMA_URL="$BEE_ASSISTANT_URL"
[ -n "${BEE_ASSISTANT_VOICE:-}" ] && ELEVENLABS_VOICE="$BEE_ASSISTANT_VOICE"
[ -n "${BEE_ASSISTANT_API_KEY:-}" ] && ELEVENLABS_API_KEY="$BEE_ASSISTANT_API_KEY"
[ -n "${BEE_MIC_DEVICE:-}" ] && MIC_DEVICE="$BEE_MIC_DEVICE"
[ -n "${BEE_RECORD_DURATION:-}" ] && RECORD_DURATION="$BEE_RECORD_DURATION"
[ -n "${BEE_WHISPER_MODEL:-}" ] && WHISPER_MODEL="$BEE_WHISPER_MODEL"
[ -n "${BEE_TTS_BACKEND:-}" ] && TTS_BACKEND="$BEE_TTS_BACKEND"
[ -n "${BEE_EDGE_TTS_VOICE:-}" ] && EDGE_TTS_VOICE="$BEE_EDGE_TTS_VOICE"
[ -n "${BEE_EDGE_TTS_RATE:-}" ] && EDGE_TTS_RATE="$BEE_EDGE_TTS_RATE"

# Ensure directories exist
mkdir -p "$RECORD_DIR" "$TTS_DIR"

# ─── Helper: emit JSON state for QML ────────────────────────
# States go to stderr (for QML SplitParser), data goes to stdout
emit_state() {
    local state="$1"
    local text="${2:-}"
    printf '{"state":"%s","text":"%s"}\n' "$state" "$(echo "$text" | sed 's/"/\\"/g' | tr '\n' ' ')" >&2
}

# ─── Record audio ────────────────────────────────────────────
record_audio() {
    local duration="${1:-$RECORD_DURATION}"
    local output="$RECORD_DIR/recording_$(date +%Y%m%d_%H%M%S).wav"

    emit_state "listening" ""

    # Try arecord first (ALSA)
    if command -v arecord &>/dev/null; then
        if arecord -D "$MIC_DEVICE" -f S16_LE -r "$SAMPLE_RATE" -c 1 -d "$duration" "$output" 2>/dev/null; then
            echo "$output"
            return 0
        fi
    fi

    # Fallback: ffmpeg with PulseAudio/PipeWire
    if command -v ffmpeg &>/dev/null; then
        if ffmpeg -y -f pulse -i default -t "$duration" -ar "$SAMPLE_RATE" -ac 1 "$output" 2>/dev/null; then
            echo "$output"
            return 0
        fi
    fi

    emit_state "error" "No recording device available"
    return 1
}

# ─── Transcribe with Whisper ─────────────────────────────────
transcribe_audio() {
    local audio_path="$1"

    emit_state "transcribing" ""

    # Try whisper CLI (fastest, uses /usr/bin/whisper)
    if command -v whisper &>/dev/null; then
        local result
        result=$(whisper "$audio_path" --model "$WHISPER_MODEL" --language fr --output_format none --no_speech_threshold 0.6 2>/dev/null | grep -v '\[\|\]' | head -1 | sed 's/^\s*//')
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    fi

    # Try whisper.cpp CLI (whisper-cli is the binary name on CachyOS)
    local whisper_bin=""
    if command -v whisper-cli &>/dev/null; then
        whisper_bin="whisper-cli"
    elif command -v whisper-cpp &>/dev/null; then
        whisper_bin="whisper-cpp"
    fi
    if [ -n "$whisper_bin" ]; then
        local model_path=""
        # Try standard paths
        for p in "$HOME/.local/share/whisper/ggml-${WHISPER_MODEL}.bin" \
                 "$HOME/.cache/whisper/ggml-${WHISPER_MODEL}.bin" \
                 "/opt/maya/.openclaw/workspace/whisper.cpp/models/ggml-${WHISPER_MODEL}.bin"; do
            if [ -f "$p" ]; then
                model_path="$p"
                break
            fi
        done
        if [ -z "$model_path" ]; then
            model_path="$HOME/.local/share/whisper/ggml-${WHISPER_MODEL}.bin"
        fi
        local result
        result=$($whisper_bin -m "$model_path" -f "$audio_path" -l fr 2>/dev/null | tail -1)
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    fi

    # Try openai-whisper Python module (slow fallback — loads model each call)
    if python3 -c "import whisper" &>/dev/null; then
        local result
        result=$(python3 -c "
import whisper
model = whisper.load_model('$WHISPER_MODEL')
result = model.transcribe('$audio_path', language='fr')
print(result['text'].strip())
" 2>/dev/null)
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    fi

    emit_state "error" "Whisper not installed. Install: python-openai-whisper or faster-whisper"
    return 1
}

# ─── Ask Ollama ──────────────────────────────────────────────
ask_ollama() {
    local prompt="$1"
    local model="${2:-$OLLAMA_MODEL}"

    emit_state "thinking" "$prompt"

    local system_prompt="Tu es Maya, l'assistante IA de Bee-Hive OS. Tu es chaleureuse, amicale, et un peu espiègle. Tu réponds en français de façon concise et utile (max 2 phrases). Tu utilises l'emoji 🐝 parfois."

    # DEBUG: log prompt and request for troubleshooting
    echo "DEBUG prompt: [$prompt] model: [$model]" > /tmp/bee-voice-debug.log

    local json_payload
    json_payload=$(jq -n \
        --arg model "$model" \
        --arg system "$system_prompt" \
        --arg prompt "$prompt" \
        '{model: $model, system: $system, prompt: $prompt, stream: false, options: {temperature: 0.7, num_predict: 200}}')

    # DEBUG: log the JSON payload
    echo "DEBUG payload: $json_payload" >> /tmp/bee-voice-debug.log

    local response
    local curl_output
    curl_output=$(curl -s --max-time 30 --retry 1 --retry-delay 2 "$OLLAMA_URL/api/generate" \
        -d "$json_payload" \
        -H "Content-Type: application/json" 2>/dev/null) || true
    response=$(echo "$curl_output" | jq -r '.response // empty' 2>/dev/null) || true

    # DEBUG: log response
    echo "DEBUG response primary: [$response]" >> /tmp/bee-voice-debug.log

    # Fallback to alternate model if primary failed
    if [ -z "$response" ] && [ -n "$OLLAMA_FALLBACK" ] && [ "$OLLAMA_FALLBACK" != "$model" ]; then
        echo "DEBUG: primary model failed, trying fallback [$OLLAMA_FALLBACK]" >> /tmp/bee-voice-debug.log
        emit_state "thinking" "$prompt"
        local fallback_payload
        fallback_payload=$(jq -n \
            --arg model "$OLLAMA_FALLBACK" \
            --arg system "$system_prompt" \
            --arg prompt "$prompt" \
            '{model: $model, system: $system, prompt: $prompt, stream: false, options: {temperature: 0.7, num_predict: 200}}')
        curl_output=$(curl -s --max-time 30 --retry 1 --retry-delay 2 "$OLLAMA_URL/api/generate" \
            -d "$fallback_payload" \
            -H "Content-Type: application/json" 2>/dev/null) || true
        response=$(echo "$curl_output" | jq -r '.response // empty' 2>/dev/null) || true
        echo "DEBUG response fallback: [$response]" >> /tmp/bee-voice-debug.log
    fi

    if [ -z "$response" ]; then
        emit_state "error" "Ollama request failed - tried: $model, $OLLAMA_FALLBACK"
        return 1
    fi

    echo "$response"
}

# ─── TTS: ElevenLabs ────────────────────────────────────────
speak_elevenlabs() {
    local text="$1"
    local output_mp3="$TTS_DIR/response.mp3"
    local output_ogg="$TTS_DIR/response.ogg"

    emit_state "speaking" "$text"

    # Generate speech
    local http_code
    http_code=$(curl -s -o "$output_mp3" -w "%{http_code}" \
        -X POST "https://api.elevenlabs.io/v1/text-to-speech/$ELEVENLABS_VOICE" \
        -H "xi-api-key: $ELEVENLABS_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg text "$text" \
            --arg model "$ELEVENLABS_MODEL" \
            '{text: $text, model_id: $model, voice_settings: {stability: 0.8, similarity_boost: 0.8}}')" \
        --max-time 30 2>/dev/null)

    if [ "$http_code" != "200" ]; then
        emit_state "error" "ElevenLabs TTS failed - HTTP $http_code"
        return 1
    fi

    # Convert to OGG Opus for PipeWire
    if ffmpeg -y -i "$output_mp3" -c:a libopus -b:a 64k "$output_ogg" 2>/dev/null; then
        paplay "$output_ogg" 2>/dev/null || pw-play "$output_ogg" 2>/dev/null || true
    else
        # Try playing MP3 directly
        paplay "$output_mp3" 2>/dev/null || pw-play "$output_mp3" 2>/dev/null || true
    fi
}

# ─── TTS: edge-tts (Microsoft Edge, gratuit, haute qualité) ───
speak_edge_tts() {
    local text="$1"
    local output_mp3="$TTS_DIR/response.mp3"
    local output_ogg="$TTS_DIR/response.ogg"

    emit_state "speaking" "$text"

    # Generate speech via edge-tts
    if ! command -v edge-tts &>/dev/null; then
        echo "ERROR: edge-tts not installed" >&2
        return 1
    fi

    local http_code
    edge-tts --voice "$EDGE_TTS_VOICE" --rate="$EDGE_TTS_RATE" --text "$text" --write-media "$output_mp3" 2>/dev/null
    http_code=$?

    if [ $http_code -ne 0 ]; then
        emit_state "error" "edge-tts failed (exit $http_code)"
        return 1
    fi

    # Verify the output file exists and is not empty
    if [ ! -s "$output_mp3" ]; then
        emit_state "error" "edge-tts produced empty output"
        return 1
    fi

    # Convert to OGG Opus for PipeWire
    if ffmpeg -y -i "$output_mp3" -c:a libopus -b:a 64k "$output_ogg" 2>/dev/null; then
        paplay "$output_ogg" 2>/dev/null || pw-play "$output_ogg" 2>/dev/null || true
    else
        # Try playing MP3 directly
        paplay "$output_mp3" 2>/dev/null || pw-play "$output_mp3" 2>/dev/null || true
    fi
}

# ─── TTS: Local (espeak-ng fallback) ─────────────────────────
speak_local() {
    local text="$1"
    emit_state "speaking" "$text"

    if command -v espeak-ng &>/dev/null; then
        espeak-ng -v fr "$text" 2>/dev/null
    else
        # No TTS available at all
        emit_state "error" "No TTS backend available"
        return 1
    fi
}

# ─── TTS dispatcher (3-tier fallback) ──────────────────────────
# Priority: elevenlabs (premium) → edge-tts (gratuit, haute qualité) → espeak-ng (fallback local)
speak() {
    local text="$1"
    case "$TTS_BACKEND" in
        elevenlabs)
            speak_elevenlabs "$text" || speak_edge_tts "$text" || speak_local "$text"
            ;;
        edge-tts)
            speak_edge_tts "$text" || speak_local "$text"
            ;;
        local|espeak-ng)
            speak_local "$text"
            ;;
        *)
            # Unknown backend: try edge-tts first (best free option), then fallback
            speak_edge_tts "$text" || speak_local "$text"
            ;;
    esac
}

# ─── Show config ─────────────────────────────────────────────
show_config() {
    jq -n \
        --arg model "$OLLAMA_MODEL" \
        --arg url "$OLLAMA_URL" \
        --arg voice "$ELEVENLABS_VOICE" \
        --arg tts_model "$ELEVENLABS_MODEL" \
        --arg mic "$MIC_DEVICE" \
        --arg duration "$RECORD_DURATION" \
        --arg whisper "$WHISPER_MODEL" \
        --arg tts "$TTS_BACKEND" \
        --arg edge_voice "$EDGE_TTS_VOICE" \
        --arg edge_rate "$EDGE_TTS_RATE" \
        '{ollama_model: $model, ollama_url: $url, elevenlabs_voice: $voice, elevenlabs_model: $tts_model, mic_device: $mic, record_duration: $duration, whisper_model: $whisper, tts_backend: $tts, edge_tts_voice: $edge_voice, edge_tts_rate: $edge_rate}'
}

# ─── Main Pipeline ───────────────────────────────────────────
main() {
    local duration="${1:-$RECORD_DURATION}"

    # Step 1: Record
    local audio_path
    audio_path=$(record_audio "$duration") || exit 1

    # Step 2: Transcribe
    local transcription
    transcription=$(transcribe_audio "$audio_path") || exit 1

    if [ -z "$transcription" ]; then
        emit_state "error" "No speech detected"
        exit 1
    fi

    emit_state "transcribed" "$transcription"

    # Step 3: Ask Ollama
    local response
    response=$(ask_ollama "$transcription") || exit 1

    emit_state "responded" "$response"

    # Step 4: Speak
    speak "$response"

    # Step 5: Done
    emit_state "done" "$response"
}

# ─── CLI ──────────────────────────────────────────────────────
case "${1:-}" in
    --config)
        show_config
        ;;
    record)
        shift
        record_audio "${1:-$RECORD_DURATION}"
        ;;
    transcribe)
        shift
        [ -z "${1:-}" ] && { echo "Usage: bee-voice.sh transcribe <file.wav>"; exit 1; }
        transcribe_audio "$1"
        ;;
    ask)
        shift
        [ -z "${1:-}" ] && { echo "Usage: bee-voice.sh ask <prompt>"; exit 1; }
        ask_ollama "$1"
        ;;
    speak)
        shift
        [ -z "${1:-}" ] && { echo "Usage: bee-voice.sh speak <text>"; exit 1; }
        speak "$1"
        ;;
    *)
        main "${1:-}"
        ;;
esac