# Inventaire : Features perdues vs actuelles (BeeSettings refonte)

## ✅ EXISTANT DANS L'ANCIEN BeeSettings (b733fb1) — ET TOUJOURS PRÉSENT

| Feature | Ancien emplacement | Nouvel emplacement | Status |
|---------|-------------------|---------------------|--------|
| Langue (FR/EN) | BeeSettings | GeneralTab | ✅ OK |
| Dark/Light mode | BeeSettings | AppearanceTab | ✅ OK |
| Nectar Sync (couleurs wallpaper) | BeeSettings | AppearanceTab | ✅ OK |
| Focus Mode | BeeSettings | AppearanceTab + ProductivityTab | ⚠️ Doublon |
| Wallpaper selector | BeeSettings (basique) | WallpaperTab | ✅ Amélioré |
| Presets (alvéoles) | N/A | BarWidgetsTab | ✅ Nouveau |
| Alarmes (avance/répétition) | N/A | ProductivityTab | ✅ Nouveau |
| CalDAV | N/A | ProductivityTab | ✅ Nouveau |
| Extensions toggle | N/A | ExtensionsTab | ✅ Nouveau |
| High Contrast | N/A | AccessibilityTab | ✅ Nouveau |
| Reduced Motion | N/A | AccessibilityTab | ✅ Nouveau |
| Text Scale | N/A | AccessibilityTab | ✅ Nouveau |

## ❌ EXISTANT DANS L'ANCIEN BeeSettings — MAIS PERDU/ABSENT

| Feature | Propriété BeeConfig | Description | Priorité |
|---------|---------------------|-------------|----------|
| **MayaDash (Dashboard)** | `dashTitle`, `cellsRevision` | Le dashboard hexagonal entier n'est plus accessible depuis les settings | 🔴 HAUTE |
| **BeeMotion (Parallax)** | `motionMode` | Effet de parallaxe 3D sur MayaDash — toggle perdu | 🔴 HAUTE |
| **BeeVibe (Audio visualizer)** | `vibeMode`, `vibeBackend`, `vibeXray`, `vibeXrayIntensity`, `vibeXrayBlend` | Visualiseur audio dans les alvéoles — toggle perdu + 5 propriétés | 🔴 HAUTE |
| **BeeBar Stats (CPU/RAM/NET/DISK/BAT)** | `showCpu`, `showRam`, `showNet`, `showDisk`, `showBattery` | 5 toggles pour afficher/masquer les indicateurs BeeBar — perdus | 🟡 MOYENNE |
| **Horloge analogique** | `analogClock` | Horloge analogique au centre du dashboard — toggle perdu | 🟡 MOYENNE |
| **BeeCorners (Hot corners)** | `cornersMode` | Coins actifs pour déclencher des actions — toggle perdu | 🟡 MOYENNE |
| **Contextual Bar** | `contextualBar` | Barre contextuelle qui s'adapte à l'app active — toggle perdu | 🟡 MOYENNE |
| **Stealth Mode** | `stealthMode` | Mode furtif minimal — EST dans AppearanceTab mais mal placé | 🟢 OK |
| **BeeSound (Night mode)** | `soundNightMode`, `soundNightStartHour`, `soundNightEndHour`, `soundDayGain`, `soundNightGain` | Mode nuit pour le son — toggle + 4 propriétés perdus | 🟡 MOYENNE |
| **Voice (BeeVoice)** | `voiceEnabled`, `voiceOllamaModel`, `voiceElevenlabsVoiceId`, `voiceElevenlabsModelId`, `voiceTtsBackend`, `voiceEdgeTtsVoice`, `voiceEdgeTtsRate`, `voiceRecordDuration`, `voiceWhisperModel` | 9 propriétés vocales — aucune config UI | 🟠 BASSE (avancé) |
| **Battery mode** | `batteryMode`, `batteryModeAuto`, `batteryThreshold` | Mode économie de batterie — toggle perdu | 🟡 MOYENNE |
| **Weather settings** | `weatherCity`, `weatherUnit`, `weatherLang`, `weatherLat`, `weatherLon` | Configuration météo — aucun config UI | 🟠 BASSE |

## 🆕 PROPOSITION : Onglet "Dashboard" dédié pour MayaDash

Marc suggère de donner à MayaDash sa propre "app" dans BeeControl. 

**Contenu proposé pour l'onglet Dashboard :**
1. 🐝 Titre du Dashboard (`dashTitle`)
2. 🎬 BeeMotion (Parallax 3D) — toggle
3. 🎵 BeeVibe (Audio visualizer) — toggle + config backend/xray
4. 🕰️ Horloge analogique — toggle
5. 📊 Indicateurs BeeBar — toggles CPU/RAM/NET/DISK/BAT
6. 🔋 Mode batterie — toggle + seuil
7. 📐 Hot Corners — toggle
8. 🎛️ Barre contextuelle — toggle

**Réorganisation des tabs BeeControl :**

| # | Tab | Contenu |
|---|-----|---------|
| 0 | 🏠 Général | Langue, raccourcis, profil, démarrage |
| 1 | 🎨 Apparence | Thème, Nectar Sync, Dark/Light |
| 2 | 🖼️ Fond d'écran | Sélection wallpaper |
| 3 | 📊 Dashboard | MayaDash, BeeMotion, BeeVibe, Horloge, Stats, Batterie, Corners, Contextual |
| 4 | 📅 Bar & Widgets | Presets alvéoles |
| 5 | 📅 Productivité | Calendrier, alarmes, focus, CalDAV |
| 6 | 🧩 Extensions | Plugins |
| 7 | ♿ Accessibilité | Contraste, animations, texte |
| 8 | 📜 Journal | Historique |

## ⚠️ DOUBLES À ÉLIMINER

- **Focus Mode** : présent dans AppearanceTab ET ProductivityTab → garder uniquement dans ProductivityTab