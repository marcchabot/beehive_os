# 🐝 Bee-Hive OS

> Environnement de bureau (*ricing*) ambitieux basé sur **Quickshell** (QML/Qt6) pour **CachyOS + Hyprland**.
> Esthétique "Nexus" : jaune miel 🍯 sur noir profond, animations organiques, glassmorphism et lueur "BeeAura".

---

## 🏗️ Architecture

```
beehive_os/
├── shell.qml                 # Point d'entrée ShellRoot (Global UI)
├── theme.json                # Centralisation de l'identité visuelle
├── user_config.json          # Configuration utilisateur persistante
├── assets/                   # Fonds d'écran 4K et ressources graphiques
└── modules/
    ├── BeeBar.qml            # Barre de statut (CPU, RAM, NET, DISK) + Stealth Mode
    ├── BeeBarState.qml       # Singleton de communication inter-fenêtres
    ├── BeeApps.qml           # Gestionnaire d'applications (Scan & Favoris)
    ├── BeeConfig.qml         # Singleton config (météo, dashboard, thème, persistence)
    ├── BeeNotify.qml         # Système de notifications "In-Shell"
    ├── BeeWallpaper.qml      # Gestionnaire de fonds d'écran dynamiques
    ├── BeeWeather.qml        # Météo universelle (Open-Meteo, sans clé API)
    ├── BeeEvents.qml         # Connecteur d'événements (Calendar/Work)
    ├── BeeCorners.qml        # Rendu organique des coins de l'écran
    ├── BeeSettings.qml       # Panneau de configuration (GUI)
    ├── BeeStudio.qml         # Éditeur visuel d'alvéoles (Full persistence)
    ├── BeeSearch.qml         # Lanceur d'applications (Fuzzy search + Pins)
    ├── BeeVibe.qml           # Visualiseur audio discret (Cava integration)
    ├── BeePower.qml          # Gestion alimentation (Éteindre, Reboot, Lock, Exit)
    ├── MayaDash.qml          # Tableau de bord hexagonal (Nid d'abeille)
    └── Clock.qml             # Widget horloge analogique + digitale
```

---

## 📦 Modules

### BeeWeather — Météo Universelle 🌦️ *(v0.6.3)*
- **Sans clé API** : Utilise Open-Meteo pour des données météo précises
- **Coordonnées centralisées** : `BeeConfig.weatherLat/Lon` — détection automatique pour Blainville et Mont-Tremblant
- **Persistance** : Ville, unité et langue sauvegardées dans `user_config.json`
- **Synchronisé** : Plus de divergence entre le widget et la BeeBar

### BeeAura Notifications & OSD 🔔 *(v1.0.0)*
- **100% Natif** : Système de notifications et OSD (Volume/Luminosité) intégré sans dépendances externes.
- **Zéro Capture Souris** : Utilisation de la propriété officielle `mask: Region {}` pour un click-through total sur les zones transparentes.
- **BeeNotify** : Support complet des notifications système via `beenotifier.py`.
- **BeeOSD** : Feedback visuel élégant pour le matériel (Clavier/Souris Razer).

### BeePower — Gestion de l'alimentation ⚡ *(v1.0.0)*
- **Interface BeeAura** : Menu dédié accessible via ⚡ dans la BeeBar
- **Actions Système** : Éteindre, Redémarrer, Déconnexion, Verrouillage

### BeeSearch — Lanceur d'applications 🔍 *(v1.0.0)*
- **Scan système** : Parse les fichiers `.desktop` via Python
- **Favoris 📌** : Jusqu'à 4 apps épinglées, persistance dans `user_config.json`

### BeeVibe — Visualiseur audio 🎵 *(v0.8.4)*
- **Barres d'égaliseur** intégrées au bas de chaque alvéole MayaDash
- **Moteur Cava** : Capture audio système via Pipewire/Pulse

### BeeStudio — Éditeur visuel 🎨 *(v0.8.4)*
- **Édition Live** : Icônes, titres et actions des alvéoles avec prévisualisation immédiate
- **Sauvegarde** dans `user_config.json`

### Stealth Mode 🫥 *(v0.8.3)*
- **Auto-Hide** : BeeBar s'efface après 3 secondes d'inactivité
- **Sentinelle** : Fenêtre invisible en haut détecte le survol de souris

### BeeMotion — Parallaxe 3D 🌊 *(v0.8.0)*
- Inclinaison 3D de la MayaDash en fonction de la position de la souris

### BeeBar — Barre de statut ⚡
- CPU, RAM, NET, DISK en temps réel
- Barres de progression avec animations et glow adaptatif

### BeeEvents — Hub d'événements 📅 *(v0.7.0)*
- Centralise les événements calendrier et alertes professionnelles

---

## 🎨 Design System — BeeAura (Nexus)

| Élément       | Valeur                              |
|---------------|-------------------------------------|
| Or primaire   | `#FFB81C` (Honey Gold)             |
| Fond sombre   | `rgba(0.05, 0.05, 0.07, 0.95)`     |
| Surface       | `rgba(255, 255, 255, 0.03)`         |
| Animations    | `Easing.InOutCubic` / `OutBack`    |

---

## 🚀 Utilisation

```bash
# Prérequis : CachyOS + Hyprland + Quickshell (Qt6) + Cava
QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os
```

### 🐝 Mise à jour de la Ruche
Pour mettre à jour sans perdre vos réglages personnels (alvéoles, météo, apps favorites) :
1. `git pull`
2. `python3 scripts/bee_config_merge.py`
3. Redémarrer la ruche : `qs ipc call root restart` (ou relancer Quickshell)

---

## 📋 Roadmap

### ✅ Complété

- [x] BeeBar — CPU/RAM/NET/DISK + Stealth Mode
- [x] BeeNotify — Notifications stylisées
- [x] BeeCorners — Fake Rounding engine
- [x] BeeWallpaper — Transitions fluides + Assets 4K
- [x] BeeSettings — Interface de configuration
- [x] BeeWeather — Météo universelle sans clé API (v0.6.1)
- [x] **BeeWeather sync fix** — Blainville/Tremblant coordonnées centralisées (v0.6.3)
- [x] BeeEvents — Connecteurs calendrier (v0.7.0)
- [x] BeeMotion — Parallaxe 3D (v0.8.0)
- [x] BeeStudio — Éditeur visuel complet (v0.8.4)
- [x] BeeSearch — Scan système + Favoris 📌 (v0.8.4)
- [x] BeeVibe — Visualiseur audio Cava (v0.8.4)
- [x] Stealth Mode — Auto-masquage avec sentinelle (v0.8.3)
- [x] BeePower — Gestion alimentation ⚡ (v0.8.5)
- [x] **BeeAura Notifications & OSD** — Système 100% natif Quickshell (v0.8.6)
- [x] Nectar Sync 🍯 — Adaptation automatique du thème au wallpaper (v0.6.2)

### 🔄 En cours / À venir

- [ ] Effets sonores Bee-Hive (discrets et élégants)
- [ ] Mode "Focus" vs Mode "Dashboard"
- [ ] Optimisation des performances (Quickshell profiling)
- [ ] Tests finaux sur CachyOS (Marc)
- [ ] Widget notifications persistantes
- [ ] Intégration agenda pharmacie / Google Calendar

---

## 🐝 Crédits

Développé avec amour par **Maya** 🐝✨ & **Marc**.

*"La ruche ne dort jamais, elle s'optimise."* 🍯🚀
