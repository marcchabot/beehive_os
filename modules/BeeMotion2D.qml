import QtQuick
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
// BeeMotion2D.qml — Moteur de parallaxe 2D avancé 🐝Motion
// v1.0 : Depth-layered parallax with Canvas Painter (Qt 6)
//        Optimisé pour éviter les repaints inutiles
// ═══════════════════════════════════════════════════════════════

Item {
    id: root
    visible: false   // composant logique, pas de rendu direct

    // ─── API publique ───────────────────────────────────────────
    // Angle d'inclinaison calculé (max ±7°), retour à 0 si désactivé
    property real tiltX: 0.0
    property real tiltY: 0.0
    property bool motionEnabled: true
    property bool dashShown: true

    // ─── Profondeur (depth layers) ──────────────────────────────
    // Chaque couche a un facteur de parallaxe unique
    property int particleCount: 8

    // ─── Position normalisée de la souris (-1.0 → +1.0 depuis le centre)
    // Utilisé en interne, exposé comme readonly pour le debug
    property real _motionX: 0.0
    property real _motionY: 0.0

    // Transitions fluides sur le déplacement (écrêtage à ±1)
    Behavior on _motionX { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    Behavior on _motionY { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    // ─── Calcul des angles de tilt (exposé pour compatibilité) ─
    function _updateTilt() {
        if (motionEnabled && dashShown) {
            tiltX = _motionX * 7.0
            tiltY = _motionY * -5.0
        } else {
            tiltX = 0.0
            tiltY = 0.0
        }
    }

    // ═══════════════════════════════════════════════════════════
    // PARTICULES — Depth-layered background (Canvas Painter)
    // ═══════════════════════════════════════════════════════════
    // ─── Particules stockées sur le root Item (pas le Canvas) ──
    property var particles: []

    Canvas {
        id: parallaxCanvas
        anchors.fill: parent
        visible: false   // utilisé pour le rendu, pas visible par l'utilisateur

        Component.onCompleted: {
            // Initialisation des particules sur root
            var initParticles = []
            for (var i = 0; i < root.particleCount; i++) {
                initParticles.push({
                    floatX:       Math.random() * parent.width,
                    floatY:       Math.random() * parent.height,
                    floatSize:    40 + Math.random() * 80,
                    particleAlpha: 0.03 + Math.random() * 0.04,
                    parallaxDepth: 25 + (i % 5) * 12,
                    yBase:        Math.random() * parent.height
                })
            }
            root.particles = initParticles
        }

        // Optimisation : ne redessiner que si le mouvement a changé

        // ─── Rendu Canvas Painter (Qt 6) ───────────────────────
        onPaint: {
            var ctx = getContext("2d")
            if (!ctx) return

            // Effacer uniquement si nécessaire (optimisation)
            // ctx.clearRect(0, 0, width, height)  // SKIP: pas besoin d'effacer le fond

            var cx = width / 2
            var cy = height / 2

            // Calculer le déplacement global basé sur tilt
            var deltaX = root.tiltX * 15  // facteur de parallaxe amplifié
            var deltaY = root.tiltY * 15

            // Dessiner chaque particule avec son niveau de profondeur
            var _particles = root.particles
            if (!_particles || !_particles.length) return
            for (var i = 0; i < _particles.length; i++) {
                var p = _particles[i]

                // Parallaxe : plus la profondeur est grande, plus le déplacement est important
                // Couche arrière (lointaine) : déplacement amplifié
                var px = p.floatX - deltaX * (p.parallaxDepth / 25)
                var py = p.floatY - deltaY * (p.parallaxDepth / 25) * 0.65

                // Animation de flottement vertical (lente)
                var floatY = p.floatY + Math.sin(Date.now() / 1000 + i * 0.5) * 20

                ctx.save()
                ctx.globalAlpha = p.particleAlpha

                // Hexagone (flat-top)
                ctx.beginPath()
                var r = p.floatSize * 0.15
                for (var j = 0; j < 6; j++) {
                    var angle = (Math.PI / 3) * j - Math.PI / 6
                    var drawPx = px + r * Math.cos(angle)
                    var drawPy = floatY + r * Math.sin(angle)
                    if (j === 0) ctx.moveTo(drawPx, drawPy)
                    else         ctx.lineTo(drawPx, drawPy)
                }
                ctx.closePath()

                // Bordure (accent color via BeeTheme injection)
                ctx.strokeStyle = "rgba(255, 184, 28, " + (p.particleAlpha * 1.5) + ")"
                ctx.lineWidth = 1
                ctx.stroke()

                ctx.restore()
            }

            // Fin du rendu
        }
    }

    // ═══════════════════════════════════════════════════════════
    // TRACKER — Mouse movement handler (z:-1 to not block clicks)
    // ═══════════════════════════════════════════════════════════
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: -1

        onPositionChanged: (mouse) => {
            if (!root.motionEnabled || !root.dashShown) return

            // Normalisation [-1, +1] depuis le centre de l'écran
            var nx = (mouse.x - root.width  / 2) / (root.width  / 2)
            var ny = (mouse.y - root.height / 2) / (root.height / 2)

            // Écrêtage pour éviter les valeurs extrêmes
            root._motionX = Math.max(-1, Math.min(1, nx))
            root._motionY = Math.max(-1, Math.min(1, ny))

            // Mise à jour immédiate du tilt
            _updateTilt()

            // Redessiner le canvas
            parallaxCanvas.requestPaint()
        }

        onExited: {
            root._motionX = 0.0
            root._motionY = 0.0
            _updateTilt()
            parallaxCanvas.requestPaint()
        }
    }

    // ═══════════════════════════════════════════════════════════
    // ANIMATION — Timer pour l'animation de flottement des particules
    // ═══════════════════════════════════════════════════════════
    Timer {
        id: particleAnimationTimer
        interval: 16   // ~60 fps
        repeat: true
        running: root.motionEnabled && root.dashShown

        onTriggered: {
            // Redessiner pour l'animation de flottement
            parallaxCanvas.requestPaint()
        }
    }

    // ─── Gestion de l'activation/désactivation ─────────────────
    onMotionEnabledChanged: {
        _updateTilt()
        if (motionEnabled && dashShown) {
            particleAnimationTimer.start()
        } else {
            particleAnimationTimer.stop()
            parallaxCanvas.requestPaint()   // Reset to center
        }
    }

    onDashShownChanged: {
        _updateTilt()
        if (motionEnabled && dashShown) {
            particleAnimationTimer.start()
        } else {
            particleAnimationTimer.stop()
            parallaxCanvas.requestPaint()   // Reset to center
        }
    }

    // ─── Initialisation ────────────────────────────────────────
    Component.onCompleted: {
        _updateTilt()
        parallaxCanvas.requestPaint()
    }
}
