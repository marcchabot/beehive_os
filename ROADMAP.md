# Roadmap Bee-Hive OS 🐝🚀

L'objectif est un lancement "hallucinant" le week-end du 20-21 mars 2026.

## 📅 Calendrier de production

### Phase 1 : Fondations & UI (12 - 14 mars) - COMPLÉTÉE
- [x] Initialisation Git & GitHub
- [x] Concept visuel (BeeAura, Thème Noir/Or)
- [x] Wallpaper 4K (Dark) - *wallpaper_dark_bee.png*
- [x] Collection de Wallpapers (Light & Dark) via nano-banana
- [x] Structure Quickshell (BeeBar, MayaDash)
- [x] Widgets système réels (CPU/RAM/Net/Disk) - *BeeBar à jour*
- [x] BeeWallpaper Engine : Switcher animé avec transition (1.5s)

### Phase 2 : Intégration Contextuelle & Modularité Framework (15 - 17 mars) - FINALISÉE (v0.7.0)
- [x] **BeePalette Engine** : Transitions fluides `lerpColor()` + glow BeeAura pulsé — *BeeTheme.qml v0.5*.
- [x] **BeeConfig System** : `user_config.json` v1.1 — personnalisation alvéoles, transitions, métadonnées framework — *BeeConfig.qml v0.5*.
- [x] **Universal Weather** : Module `BeeWeather.qml` intégré à la `BeeBar`. Support Open-Meteo (Sans clé) — *v0.6.1*.
- [x] **Connecteurs BeeEvents** : Intégration Google Calendar (Noah/Johanne) et Pharmacie vers MayaDash — *v0.7.0*.
- [x] Système de notifications BeeAura (animations organiques) - *BeeNotify.qml opérationnel*.
- [ ] ~~Support Multi-écrans~~ (Mis sur la glace le 15 mars - Indisponible sur le setup de Marc).

### Phase 3 : Raffinement & "Wow Factor" (18 - 20 mars) - COMPLÉTÉE (v1.0.0) 🐝🛡️
- [x] **BeeSettings** : Interface graphique (GUI) pour configurer l'OS (Toggles implémentés)
- [x] **BeeCorners** : Coins d'écran arrondis (Fake Rounding) - *BeeCorners.qml prêt*
- [x] **BeeMotion** : Effet de parallaxe 3D sur la MayaDash (v0.8.0)
- [x] **BeeStudio Full** : Éditeur visuel complet avec sauvegarde réelle — *v0.8.4 (17 mars)*
- [x] **BeeSearch** : Lanceur d'applications (Fuzzy search, scan .desktop réel, Favoris 📌) — *v0.8.4 (17 mars)*
- [x] **BeeVibe** : Visualiseur audio Pipewire/Cava intégré aux alvéoles — *v0.8.4 (17 mars)*
- [x] **Stealth Mode** : BeeBar auto-masquante avec zone de déclenchement sentinelle — *v0.8.3 (17 mars)*
- [x] **BeePower** : Gestion de l'alimentation (⚡, Éteindre, Reboot, Lock) — *v0.8.5 (17 mars)*
- [x] **BeeAura Notifications & OSD** : Système de notifications et OSD (Volume/Luminosité) 100% natif Quickshell — *v0.8.6 (19 mars)*
- [x] **Bee-Hive SDDM** : Écran de login animé (Variantes Hexa-Neon et Cyber-Bee) — *v0.2.7 (19 mars)*
- [ ] **Effets sonores Bee-Hive** (discrets et élégants) — *Reporté post-lancement*
- [x] **Optimisation des performances & Fix Souris** (Solution officielle `mask: Region {}`) — *v1.0.0 (20 mars)*
- [x] **Mode Focus 🎯** : Toggle Focus/Dashboard via BeeSettings + IPC — *v0.9.0 (20 mars)*
- [x] **Tests finaux sur CachyOS (Marc)** : STABILITÉ TOTALE ! 🚀🍯

### Lancement : 21 Mars 🚀🍯
- Présentation finale et déploiement complet — **DÉROULEMENT RÉUSSI (v1.0.0)**. 🎉

### Phase 4 : Préparation au Lancement Public (Sprint 21 mars — v1.3.7) 🐝🌍🚀
- [x] **Sécurité & Confidentialité** : `.gitignore` renforcé — `client_secret.json`, `google_access.json`, `GATEWAY_TOKEN.txt`, `pending_messages.json` retirés du tracking Git. Données privées protégées. *(v1.3.7 — 21 mars)*
- [x] **Template Public** : `user_config.example.json` créé — données anonymisées (FR/EN), prêt pour les nouveaux utilisateurs. *(v1.3.7 — 21 mars)*
- [x] **i18n — Structure de base** : Dossier `i18n/` créé avec fichiers `fr.json` et `en.json`. Plan d'intégration `qsTr()` documenté. *(v1.3.7 — 21 mars)*
- [ ] **i18n (Complet)** : Intégration `qsTr()` dans tous les fichiers QML + sélecteur de langue dans BeeSettings.
- [ ] **Bee-Live Sync v2** : Découpler la synchronisation des données du flux Git (Live API).
- [ ] **Documentation "Grand Public"** : Nouveau `README.md` avec guide d'installation en une ligne pour CachyOS.

---

### 🌱 Idées Post-Lancement (v1.1+)
- **Multilingual Support (i18n)** : Internationalisation complète (FR/EN) pour une diffusion mondiale.
    - *Plan de match :* Wrap `qsTr()`, dossier `i18n/`, sélecteur de langue dans BeeSettings.
- **BeeVibe Couleurs** : Personnaliser la couleur des barres d'égaliseur par alvéole (couleur unique, dégradé, ou synchronisée avec le thème de l'alvéole). Idée de Marc — 17 mars 2026.
- **BeeStudio Advanced** : Ajout/suppression d'alvéoles + choix du layout.
- **Multi-config** : Fichier `my_config.json` qui override `user_config.json` pour faciliter les mises à jour communautaires.

---
---
*Note de Maya : Chaque jour à 08h30, je lance un "Sprint de réflexion" pour évaluer les progrès et planifier la tâche du jour. Version courante : **v1.3.7** (21 mars 2026).*
