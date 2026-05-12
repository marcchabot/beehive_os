pragma Singleton
import QtQuick

// ═══════════════════════════════════════════════════════════════
// BeeTheme.qml — BeePalette Engine 🐝🎨  (Singleton global)
// v0.8.25: Nectar Auto-Theme (time/weather) + weather accent
//
// ─── Architecture ─────────────────────────────────────────────
//   • _progress (0.0 → 1.0) : animation de transition Dark↔Light
//   • lerpColor()            : interpolation pixel par pixel
//   • _glowPhase (0→1→0)    : pulsation continue de l'auraGlow
//   • mode (R/W)             : "HoneyDark" | "HoneyLight"
//
// ─── API publique ─────────────────────────────────────────────
//   BeeTheme.mode                 → palette courante (string)
//   BeeTheme.toggle()             → bascule Dark↔Light animée
//   BeeTheme.setMode("HoneyLight")→ changement animé explicite
//   BeeTheme.nectarSync           → bool (adaptation auto on/off)
//   BeeTheme.transitionDuration   → durée ms (défaut 600)
//   BeeTheme.accent, .bg, .glassBg, etc. → couleurs interpolées
//   BeeTheme.auraGlow             → couleur de lueur pulsée
//   BeeTheme.wallpaper            → chemin du fond d'écran actif
// ═══════════════════════════════════════════════════════════════

QtObject {
    id: root

    // ─── Animations (définies comme propriétés) ───────────────
    property NumberAnimation anim: NumberAnimation {
        target: root
        property: "_progress"
        duration: root.transitionDuration
        easing.type: Easing.InOutSine
    }

    property SequentialAnimation glowAnim: SequentialAnimation {
        loops: Animation.Infinite
        running: true
        NumberAnimation {
            target: root; property: "_glowPhase"
            to: 1.0; duration: 2200
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root; property: "_glowPhase"
            to: 0.0; duration: 2200
            easing.type: Easing.InOutSine
        }
    }

    // ─── Durée de transition — modifiable via BeeConfig ───────
    property int transitionDuration: 600

    // ─── Nectar Sync 2.0 — Auto Schedule 🍯☀️🌙 ────────────
    // Suggests HoneyLight during day, HoneyDark during night.
    // Does NOT force change — notification with "Apply" button.
    property bool nectarAutoSchedule: BeeConfig.nectarAutoSchedule

    // ─── Nectar Sync 2.0 — Color Therapy 🎨 ────────────────────
    // When enabled, accent pulses slowly through calming colors
    // (amber → forest green → night blue → amber, ~60s cycle)
    property bool colorTherapyEnabled: BeeConfig.colorTherapyEnabled

    // ─── Color Therapy accent (derived, pulsing) ───────────────
    // therapyPhase: 0.0 → 1.0 → 0.0 (loop)
    property real _therapyPhase: 0.0

    property SequentialAnimation therapyAnim: SequentialAnimation {
        id: _therapyAnim
        loops: Animation.Infinite
        running: BeeTheme.colorTherapyEnabled
        NumberAnimation {
            target: BeeTheme; property: "_therapyPhase"
            to: 1.0; duration: 30000   // 30s up (half-cycle)
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: BeeTheme; property: "_therapyPhase"
            to: 0.0; duration: 30000   // 30s down (half-cycle)
            easing.type: Easing.InOutSine
        }
    }

    // Calming therapy colors:
    //   amber gold  = #FFB81C  (0.0)
    //   forest green = #2D8B46  (0.33)
    //   night blue   = #1A3A5C  (0.66)
    //   amber gold  = #FFB81C  (1.0)
    readonly property color _therapyAmber:  "#FFB81C"
    readonly property color _therapyForest: "#2D8B46"
    readonly property color _therapyBlue:   "#1A3A5C"

    // therapyAccent: the interpolated color for Color Therapy mode
    // When therapy is OFF, this equals the normal accent.
    // When therapy is ON, it cycles through the calming palette.
    property color therapyAccent: {
        if (!colorTherapyEnabled) return lerpColor(_dark.accent, _light.accent, _progress)

        var t = _therapyPhase
        // Segment 1: amber → forest (t: 0 → 0.33)
        // Segment 2: forest → blue  (t: 0.33 → 0.66)
        // Segment 3: blue → amber  (t: 0.66 → 1.0)
        if (t <= 0.33) {
            var s1 = t / 0.33
            return lerpColor(_therapyAmber, _therapyForest, s1)
        } else if (t <= 0.66) {
            var s2 = (t - 0.33) / 0.33
            return lerpColor(_therapyForest, _therapyBlue, s2)
        } else {
            var s3 = (t - 0.66) / 0.34
            return lerpColor(_therapyBlue, _therapyAmber, s3)
        }
    }

    // ─── Nectar Sync 🍯 (Adaptation auto au wallpaper) ───────
    property bool nectarSync: true

    // ─── Override manuel du wallpaper (The Hive) ─────────────
    // Vide = wallpaper automatique dérivé du mode.
    // Set = wallpaper explicitement choisi par l'utilisateur.
    property string wallpaperOverride: ""

    // ─── Mode actif (R/W — rétrocompatible) ───────────────────
    // Assigner mode déclenche l'animation de transition.
    property string mode: "HoneyDark"   // "HoneyDark" | "HoneyLight"

    onModeChanged: {
        anim.stop()
        anim.to = (mode === "HoneyLight") ? 1.0 : 0.0
        anim.start()
    }

    // ─── Progression du thème : 0.0 = HoneyDark, 1.0 = HoneyLight ─
    property real _progress: 0.0

    // ─── Phase de pulsation du glow (0.0 → 1.0 → 0.0 ∞) ─────
    property real _glowPhase: 0.0

    // ─── Breathe Phase (Color Therapy) ──────────────────────────
    // Oscille entre 0 et 1 en boucle, animé nativement par QML.
    // Quand breatheEnabled est true, l'accent pulse doucement.
    property real _breathePhase: 0.0
    property bool breatheEnabled: false
    // Base accent before breathe — stored when breathe starts
    property color _breatheBaseAccent: "#FFB81C"
    property color _breatheBaseAccentLight: "#FFD666"

    property SequentialAnimation breatheAnim: SequentialAnimation {
        loops: Animation.Infinite
        running: root.breatheEnabled
        NumberAnimation {
            target: root; property: "_breathePhase"
            to: 1.0; duration: 4000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root; property: "_breathePhase"
            to: 0.0; duration: 4000
            easing.type: Easing.InOutSine
        }
        onStopped: root._breathePhase = 0.0
    }

    // ─── Auto Theme Overlay (user_config.auto.json) ───────────
    property string autoThemeMode: ""
    property bool autoPaletteEnabled: false
    property var autoPalette: ({})
    property string autoSourceWallpaper: ""

    function _clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function _parseColorValue(raw, fallback) {
        if (raw === undefined || raw === null) return fallback
        if (typeof raw !== "string") return fallback

        var s = raw.trim()
        if (s.match(/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/)) {
            return s
        }

        var m = s.match(/^rgba?\(\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})(?:\s*,\s*([0-9]*\.?[0-9]+))?\s*\)$/i)
        if (!m) return fallback

        var r = _clamp(parseInt(m[1]), 0, 255)
        var g = _clamp(parseInt(m[2]), 0, 255)
        var b = _clamp(parseInt(m[3]), 0, 255)
        var a = (m[4] !== undefined) ? _clamp(Number(m[4]), 0.0, 1.0) : 1.0
        return Qt.rgba(r / 255.0, g / 255.0, b / 255.0, a)
    }

    function _autoColor(key, fallback, modeName) {
        if (!autoPaletteEnabled || autoThemeMode !== modeName || !autoPalette) return fallback
        return _parseColorValue(autoPalette[key], fallback)
    }

    function _autoNumber(key, fallback, modeName) {
        if (!autoPaletteEnabled || autoThemeMode !== modeName || !autoPalette) return fallback
        var v = Number(autoPalette[key])
        if (isNaN(v)) return fallback
        return _clamp(v, 0.0, 1.0)
    }

    function clearAutoPalette() {
        autoPaletteEnabled = false
        autoPalette = ({})
        autoThemeMode = ""
        autoSourceWallpaper = ""
    }

    function applyAutoPalette(modeName, paletteObj, sourceWallpaper) {
        if (!paletteObj || typeof paletteObj !== "object") {
            clearAutoPalette()
            return
        }

        autoThemeMode = (modeName === "HoneyLight") ? "HoneyLight" : "HoneyDark"
        autoPalette = paletteObj
        autoSourceWallpaper = sourceWallpaper || ""
        autoPaletteEnabled = true
    }

    // ─── Palette HoneyDark ─────────────────────────────────────
    property QtObject dark: QtObject {
        id: _dark
        readonly property color bg:            root._autoColor("bg", "#0D0D0D", "HoneyDark")
        readonly property color accent:        root._autoColor("accent", "#FFB81C", "HoneyDark")
        readonly property color secondary:     root._autoColor("secondary", "#1A1A1A", "HoneyDark")
        readonly property color textPrimary:   root._autoColor("textPrimary", "#FFFFFF", "HoneyDark")
        readonly property color textSecondary: root._autoColor("textSecondary", "#AAAAAA", "HoneyDark")
        readonly property color barBg:         root._autoColor("barBg", Qt.rgba(0.05,  0.05,  0.05,  0.92), "HoneyDark")
        readonly property color glassBg:       root._autoColor("glassBg", Qt.rgba(0.07,  0.07,  0.08,  0.65), "HoneyDark")
        readonly property color glassBorder:   root._autoColor("glassBorder", Qt.rgba(1,     0.722, 0.11,  0.2), "HoneyDark")
        readonly property color backdropBg:    root._autoColor("backdropBg", Qt.rgba(0.02,  0.02,  0.04,  0.88), "HoneyDark")
        readonly property real  auraAlpha:     root._autoNumber("auraAlpha", 0.6, "HoneyDark")
        readonly property color separator:     root._autoColor("separator", Qt.rgba(1, 1, 1, 0.08), "HoneyDark")
        readonly property string wallpaper:    "../assets/wallpaper_dark_bee.png"
    }

    // ─── Palette HoneyLight ────────────────────────────────────
    // v0.6.3: Glassmorphism revamp — translucidité, chaleur miel, lisibilité maximale
    property QtObject light: QtObject {
        id: _light
        readonly property color bg:            root._autoColor("bg", "#F5F0E8", "HoneyLight")
        readonly property color accent:        root._autoColor("accent", "#E5A200", "HoneyLight")
        readonly property color secondary:     root._autoColor("secondary", "#EDE8DD", "HoneyLight")
        readonly property color textPrimary:   root._autoColor("textPrimary", "#2A1F0A", "HoneyLight")
        readonly property color textSecondary: root._autoColor("textSecondary", "#6B5D48", "HoneyLight")
        readonly property color barBg:         root._autoColor("barBg", Qt.rgba(0.94,  0.92,  0.88,  0.96), "HoneyLight")
        readonly property color glassBg:       root._autoColor("glassBg", Qt.rgba(1,     1,     1,     0.72), "HoneyLight")
        readonly property color glassBorder:   root._autoColor("glassBorder", Qt.rgba(0.90,  0.64,  0.0,   0.40), "HoneyLight")
        readonly property color backdropBg:    root._autoColor("backdropBg", Qt.rgba(0.91,  0.89,  0.84,  0.92), "HoneyLight")
        readonly property real  auraAlpha:     root._autoNumber("auraAlpha", 0.50, "HoneyLight")
        readonly property color separator:     root._autoColor("separator", Qt.rgba(0.35, 0.28, 0.10, 0.18), "HoneyLight")
        readonly property string wallpaper:    "../assets/wallpaper_light_bee.png"
    }

    // ─── Helpers : interpolation linéaire ─────────────────────
    function lerp(a, b, t) { return a + (b - a) * t }

    function lerpColor(c1, c2, t) {
        return Qt.rgba(
            lerp(c1.r, c2.r, t),
            lerp(c1.g, c2.g, t),
            lerp(c1.b, c2.b, t),
            lerp(c1.a, c2.a, t)
        )
    }

    // ─── Palette active — interpolée en temps réel ────────────
    // Ces propriétés se mettent à jour automatiquement à chaque
    // frame d'animation grâce au binding réactif de QML.
    property color bg:            lerpColor(_dark.bg,            _light.bg,            _progress)
    property color _baseAccent:    lerpColor(_dark.accent,        _light.accent,        _progress)
    property color accent: {
        if (colorTherapyEnabled) return therapyAccent
        if (breatheEnabled) return lerpColor(_breatheBaseAccent, _breatheTarget, _breathePhase)
        return _baseAccent
    }
    property color _breatheTarget: Qt.rgba(
        Math.min(1, _breatheBaseAccent.r + 0.25),
        Math.min(1, _breatheBaseAccent.g + 0.25),
        Math.min(1, _breatheBaseAccent.b + 0.18),
        1.0
    )
    property color secondary:     lerpColor(_dark.secondary,     _light.secondary,     _progress)
    property color textPrimary:   lerpColor(_dark.textPrimary,   _light.textPrimary,   _progress)
    property color textSecondary: lerpColor(_dark.textSecondary, _light.textSecondary, _progress)
    property color barBg:         lerpColor(_dark.barBg,         _light.barBg,         _progress)
    property color glassBg:       lerpColor(_dark.glassBg,       _light.glassBg,       _progress)
    property color glassBorder:   lerpColor(_dark.glassBorder,   _light.glassBorder,   _progress)
    property color backdropBg:    lerpColor(_dark.backdropBg,    _light.backdropBg,    _progress)
    property color separator:     lerpColor(_dark.separator,     _light.separator,     _progress)

    // ─── Glow BeeAura : interpolé + pulsé ────────────────────
    // alpha oscille entre 70 % et 100 % de la valeur de la palette.
    property color auraGlow: Qt.rgba(
        (colorTherapyEnabled ? therapyAccent.r : accent.r),
        (colorTherapyEnabled ? therapyAccent.g : accent.g),
        (colorTherapyEnabled ? therapyAccent.b : accent.b),
        lerp(
            lerp(_dark.auraAlpha, _light.auraAlpha, _progress) * 0.7,
            lerp(_dark.auraAlpha, _light.auraAlpha, _progress),
            _glowPhase
        )
    )

    // ─── Fond d'écran actif ───────────────────────────────────
    // wallpaperOverride takes priority (The Hive selection),
    // sinon dérivé automatiquement du mode courant.
    property string wallpaper: wallpaperOverride !== ""
        ? wallpaperOverride
        : (_progress < 0.5 ? _dark.wallpaper : _light.wallpaper)

    // ═══════════════════════════════════════════════════════════
    // BeeAccessibility — Adaptive Contrast & Motion 🐝♿
    // ═══════════════════════════════════════════════════════════

    // ─── High Contrast Mode ─────────────────────────────────
    // When true, forces text colors to pure white (dark) or pure black (light)
    // to meet WCAG AA 4.5:1 contrast ratio
    property bool highContrast: false

    // ─── Text Scale ─────────────────────────────────────────
    // 1.0 = Normal, 1.2 = Grand, 1.4 = Très Grand
    property real textScale: 1.0

    // ─── Reduced Motion ─────────────────────────────────────
    // When true, fancy transitions are shortened or disabled
    property bool reducedMotion: false

    // ─── Accessibility Level ──────────────────────────────────
    // "none" = no auto-adjust, "AA" = WCAG AA (4.5:1), "AAA" = WCAG AAA (7.0:1)
    property string accessibilityLevel: "none"

    // ─── Contrast Issues ─────────────────────────────────────
    // List of color pair descriptions that fail the selected level
    // Populated by bee_accessibility.py audit via BeeConfig
    property var contrastIssues: []

    // ─── High Contrast for Screen Reader 🐝♿ v0.9.2 ───────────
    // When a screen reader is active, boost contrasts beyond normal
    // accessibility level to ensure visual elements are clearly
    // distinguishable (screen reader users may also need visual cues)
    property bool highContrastForScreenReader: false

    // ─── Accessible text colors ──────────────────────────────
    // Override text colors when highContrast is active
    // When accessibilityLevel is AA or AAA, auto-adjust towards compliance
    property color accessibleTextPrimary: {
        if (highContrast || highContrastForScreenReader) {
            return mode === "HoneyDark" ? "#FFFFFF" : "#000000"
        }
        if (accessibilityLevel === "AAA") {
            return mode === "HoneyDark" ? "#FFFFFF" : "#000000"
        }
        if (accessibilityLevel === "AA") {
            return mode === "HoneyDark" ? "#F0F0F0" : "#1A1A1A"
        }
        return textPrimary
    }
    property color accessibleTextSecondary: {
        if (highContrast || highContrastForScreenReader) {
            return mode === "HoneyDark" ? "#E0E0E0" : "#1A1A1A"
        }
        if (accessibilityLevel === "AAA") {
            return mode === "HoneyDark" ? "#D4D4D4" : "#2A2A2A"
        }
        if (accessibilityLevel === "AA") {
            return mode === "HoneyDark" ? "#C0C0C0" : "#333333"
        }
        return textSecondary
    }

    // ─── Reduced Animations (Battery Mode) 🐝🔋 ────────────
    // When batteryMode is active, animations are cut to ~50%
    // reducedMotion takes priority (0ms), batteryMode halves them
    property bool reducedAnimations: false

    onAccessibilityLevelChanged: {
        // When accessibility level changes, trigger contrast audit notification
        if (accessibilityLevel !== "none") {
            console.log("BeeTheme: Accessibility level set to", accessibilityLevel, "— text colors auto-adjusted")
        }
    }

    // ─── Transition durations respecting reducedMotion & reducedAnimations ─────
    // Priority: reducedMotion (0ms) > reducedAnimations (50%) > normal
    property int durationShort:   reducedMotion ? 0 : (reducedAnimations ? 75 : 150)
    property int durationMedium:  reducedMotion ? 0 : (reducedAnimations ? 150 : 300)
    property int durationLong:    reducedMotion ? 0 : (reducedAnimations ? 300 : 600)
    property int durationTheme:   reducedMotion ? 50 : (reducedAnimations ? 300 : transitionDuration)

    // ─── Wallpaper crossfade duration ────────────────────────
    // Normal: 1800ms, Battery: 800ms, Reduced Motion: 50ms
    property int durationWallpaperCrossfade: reducedMotion ? 50 : (reducedAnimations ? 800 : 1800)

    // ─── BeeBar hover duration ──────────────────────────────
    // Normal: 200ms, Battery: 100ms, Reduced Motion: 0ms
    property int durationBarHover: reducedMotion ? 0 : (reducedAnimations ? 100 : 200)
    // ─── Nectar Auto Schedule Timer 🍯☀️🌙 ────────────────────
    // Checks every 30 min if a theme mode suggestion should be made
    // (morning = HoneyLight, evening = HoneyDark)
    // Does NOT force change — just sends a notification suggestion.
    property string _lastSuggestedMode: ""

    property Timer _scheduleTimer: Timer {
        interval: 1800000  // 30 minutes
        running: BeeTheme.nectarAutoSchedule
        repeat: true
        onTriggered: BeeTheme._checkSchedule()
    }

    function _checkSchedule() {
        if (!nectarAutoSchedule) return

        var hour = new Date().getHours()
        var suggestedMode = ""
        var isFr = (typeof BeeConfig !== 'undefined' && BeeConfig.uiLang === 'fr')

        if (hour >= 7 && hour < 18) {
            // Daytime → suggest HoneyLight
            suggestedMode = "HoneyLight"
        } else if (hour >= 20 || hour < 6) {
            // Nighttime → suggest HoneyDark
            suggestedMode = "HoneyDark"
        } else {
            // Transition hours (6-7, 18-20) → no suggestion
            _lastSuggestedMode = ""
            return
        }

        // Only suggest if different from current mode and not already suggested
        if (suggestedMode !== mode && suggestedMode !== _lastSuggestedMode) {
            _lastSuggestedMode = suggestedMode
            var label = suggestedMode === 'HoneyLight'
                ? (isFr ? 'Mode Lumineux (HoneyLight)' : 'Light Mode (HoneyLight)')
                : (isFr ? 'Mode Sombre (HoneyDark)' : 'Dark Mode (HoneyDark)')
            var title = isFr ? '🌻 Suggestion Nectar' : '🌻 Nectar Suggestion'
            console.log("BeeTheme: Nectar Auto Schedule →", label)
            if (typeof BeeBarState !== 'undefined') {
                BeeBarState.dispatchNotification(title, label, "🍯")
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // Nectar Auto-Theme 🐝🎨☀️🌧️ v0.8.25
    // ═══════════════════════════════════════════════════════════
    // Mode: "off" | "timeOfDay" | "weather" | "combined"
    // Time-of-day: HoneyLight 6h-18h, HoneyDark 18h-6h,
    //   dawn/dusk transitions for smooth switching.
    // Weather: adjusts accent warmth based on condition.
    //   Sunny → warmer amber, Cloudy → cooler muted,
    //   Rainy → blue-grey undertones, Snowy → icy white-blue
    // ═══════════════════════════════════════════════════════════

    // ─── Weather condition for accent adaptation 🐝🌦️ ────────
    property string _weatherCondition: "clear"  // clear | cloudy | rainy | snowy
    property int _weatherCode: 0
    property real _weatherAccentBlend: 0.0     // 0.0 = base accent, 1.0 = fully weather-adjusted
    property string _timeOfDaySuggestion: ""    // "HoneyLight" or "HoneyDark"

    // ─── Weather accent colors 🐝🎨 ─────────────────────────
    readonly property color _sunnyAccent:    "#FFB81C"   // Warm amber (base)
    readonly property color _cloudyAccent:   "#8B9DAF"   // Cool muted blue-grey
    readonly property color _rainyAccent:    "#5B7E9A"   // Blue-grey undertone
    readonly property color _snowyAccent:   "#B8D4E3"   // Icy white-blue
    readonly property color _sunnyAccentLight:  "#FFD666"  // Warm amber (light)
    readonly property color _cloudyAccentLight: "#A0B0C0"  // Cool muted (light)
    readonly property color _rainyAccentLight:  "#7BA0BD"  // Blue-grey (light)
    readonly property color _snowyAccentLight:  "#D0E8F5"  // Icy (light)

    // ─── Computed weather accent 🐝 ─────────────────────────
    readonly property color weatherAccent: {
        var base = (_progress >= 0.5) ? _light.accent : _dark.accent
        if (BeeConfig.autoThemeMode === "off") return base
        if (BeeConfig.autoThemeMode !== "weather" && BeeConfig.autoThemeMode !== "combined") return base
        var t = _weatherAccentBlend
        var target = base
        if (_weatherCondition === "sunny") {
            target = (_progress >= 0.5) ? _sunnyAccentLight : _sunnyAccent
        } else if (_weatherCondition === "cloudy") {
            target = (_progress >= 0.5) ? _cloudyAccentLight : _cloudyAccent
        } else if (_weatherCondition === "rainy") {
            target = (_progress >= 0.5) ? _rainyAccentLight : _rainyAccent
        } else if (_weatherCondition === "snowy") {
            target = (_progress >= 0.5) ? _snowyAccentLight : _snowyAccent
        }
        return lerpColor(base, target, t)
    }

    // ─── Update weather condition from WMO code 🐝 ──────────
    function updateWeatherCondition(wmoCode) {
        _weatherCode = wmoCode
        if (wmoCode <= 1) {
            _weatherCondition = "sunny"
        } else if (wmoCode <= 3) {
            _weatherCondition = "cloudy"
        } else if (wmoCode <= 48) {
            _weatherCondition = "cloudy"
        } else if (wmoCode <= 67) {
            _weatherCondition = "rainy"
        } else if (wmoCode <= 77) {
            _weatherCondition = "snowy"
        } else if (wmoCode <= 82) {
            _weatherCondition = "rainy"
        } else if (wmoCode <= 86) {
            _weatherCondition = "snowy"
        } else {
            _weatherCondition = "rainy"
        }
        _weatherAccentBlendTarget = 1.0
        _weatherBlendAnim.start()
    }

    property real _weatherAccentBlendTarget: 0.0
    property NumberAnimation _weatherBlendAnim: NumberAnimation {
        target: root
        property: "_weatherAccentBlend"
        to: root._weatherAccentBlendTarget
        duration: root.reducedMotion ? 50 : 2000
        easing.type: Easing.InOutSine
    }

    // ─── Time-of-day auto theme timer 🐝☀️🌙 ────────────────
    property Timer _autoThemeTimer: Timer {
        interval: 300000  // 5 minutes
        running: BeeConfig.autoThemeMode === "timeOfDay" || BeeConfig.autoThemeMode === "combined"
        repeat: true
        onTriggered: root._checkTimeOfDay()
    }

    property string autoThemeMode: BeeConfig.autoThemeMode

    function _checkTimeOfDay() {
        if (BeeConfig.autoThemeMode !== "timeOfDay" && BeeConfig.autoThemeMode !== "combined") return

        var hour = new Date().getHours()
        var suggestedMode = ""

        // Dawn: 6h-7h → HoneyLight, Day: 7h-17h → HoneyLight
        // Dusk: 17h-18h → HoneyDark, Night: 18h-6h → HoneyDark
        if (hour >= 7 && hour < 17) {
            suggestedMode = "HoneyLight"
        } else if (hour >= 18 || hour < 6) {
            suggestedMode = "HoneyDark"
        } else if (hour >= 6 && hour < 7) {
            suggestedMode = "HoneyLight"
        } else {
            suggestedMode = "HoneyDark"
        }

        if (suggestedMode !== _timeOfDaySuggestion && suggestedMode !== mode) {
            _timeOfDaySuggestion = suggestedMode
            var isFr = (typeof BeeConfig !== 'undefined' && BeeConfig.uiLang === 'fr')
            var label = suggestedMode === 'HoneyLight'
                ? (isFr ? 'Mode Lumineux (HoneyLight)' : 'Light Mode (HoneyLight)')
                : (isFr ? 'Mode Sombre (HoneyDark)' : 'Dark Mode (HoneyDark)')
            console.log("BeeTheme: Nectar Auto-Theme →", label)

            // Auto-apply the theme change
            setMode(suggestedMode)
            BeeConfig.mode = suggestedMode

            if (typeof BeeBarState !== 'undefined') {
                var title = isFr ? '🐝 Thème automatique' : '🐝 Auto Theme'
                BeeBarState.dispatchNotification(title, label, "🎨")
            }
        }
        _timeOfDaySuggestion = suggestedMode
    }

    // ─── Weather accent auto-fetch timer 🐝🌧️ ────────────────
    property Timer _weatherAccentTimer: Timer {
        interval: 1800000  // 30 minutes
        running: BeeConfig.autoThemeMode === "weather" || BeeConfig.autoThemeMode === "combined"
        repeat: true
        onTriggered: root._fetchWeatherAccent()
    }

    function _fetchWeatherAccent() {
        if (BeeConfig.autoThemeMode !== "weather" && BeeConfig.autoThemeMode !== "combined") return

        var lat = BeeConfig.weatherLat
        var lon = BeeConfig.weatherLon
        if (lat === 0 && lon === 0) { lat = 45.67; lon = -73.88 }

        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=weather_code&timezone=auto"
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        var wmo = data.current ? data.current.weather_code : 0
                        updateWeatherCondition(wmo)
                        console.log("BeeTheme: Weather accent updated, WMO=" + wmo + " → " + _weatherCondition)
                    } catch (e) {
                        console.log("BeeTheme: Weather accent parse error: " + e)
                    }
                } else {
                    console.log("BeeTheme: Weather accent fetch failed, status=" + xhr.status)
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    // ─── Apply auto-theme on startup 🐝 ──────────────────────
    Component.onCompleted: {
        if (BeeConfig.autoThemeMode === "timeOfDay" || BeeConfig.autoThemeMode === "combined") {
            _checkTimeOfDay()
        }
        if (BeeConfig.autoThemeMode === "weather" || BeeConfig.autoThemeMode === "combined") {
            _fetchWeatherAccent()
        }
    }

    // ─── API publique ─────────────────────────────────────────
    function toggle() {
        mode = (mode === "HoneyDark") ? "HoneyLight" : "HoneyDark"
    }

    // Nectar Sync 🍯 : helper pour changer de thème selon le wallpaper
    function nectarSyncTo(newMode) {
        if (nectarSync) {
            setMode(newMode)
        }
    }

    // setMode() : équivalent explicite à l'assignation de mode.
    // Préférer cette fonction depuis le code externe pour plus de clarté.
    function setMode(newMode) {
        if (newMode !== mode) mode = newMode
        else {
            // Force l'animation même si mode n'a pas changé de valeur.
            anim.stop()
            anim.to = (newMode === "HoneyLight") ? 1.0 : 0.0
            anim.start()
        }
    }
}
