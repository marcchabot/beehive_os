pragma Singleton
import QtQuick

// ═══════════════════════════════════════════════════════════════
// BeeTheme.qml — BeePalette Engine 🐝🎨  (Singleton global)
// v0.6.1: Nectar Sync 🍯 — wallpaperOverride (BeeStudio selection)
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

    // ─── Nectar Sync 🍯 (Adaptation auto au wallpaper) ───────
    property bool nectarSync: true

    // ─── Override manuel du wallpaper (BeeStudio) ─────────────
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
    property color accent:        lerpColor(_dark.accent,        _light.accent,        _progress)
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
        accent.r,
        accent.g,
        accent.b,
        lerp(
            lerp(_dark.auraAlpha, _light.auraAlpha, _progress) * 0.7,
            lerp(_dark.auraAlpha, _light.auraAlpha, _progress),
            _glowPhase
        )
    )

    // ─── Fond d'écran actif ───────────────────────────────────
    // wallpaperOverride takes priority (BeeStudio selection),
    // sinon dérivé automatiquement du mode courant.
    property string wallpaper: wallpaperOverride !== ""
        ? wallpaperOverride
        : (_progress < 0.5 ? _dark.wallpaper : _light.wallpaper)

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
