# Rapport Technique — Sprint i18n Bee-Hive OS

**Date :** 2026-03-23
**Version :** 1.4.0
**Sprint :** Internationalisation (FR/EN)

---

## Résumé

Ce sprint intègre un support complet du multilingue (français/anglais) dans le framework Bee-Hive OS. L'architecture repose sur un système JSON personnalisé chargé dynamiquement par `BeeConfig`, sans dépendance externe. Le changement de langue est instantané et persisté dans `user_config.json`.

---

## Architecture i18n

### Système de traduction

| Composant | Rôle |
|-----------|------|
| `i18n/fr.json` | Dictionnaire français (langue par défaut) |
| `i18n/en.json` | Dictionnaire anglais |
| `BeeConfig.uiLang` | Propriété singleton (`"fr"` \| `"en"`) |
| `BeeConfig.tr` | Objet de traduction chargé dynamiquement |
| `BeeConfig.loadI18n(lang)` | Charge `i18n/<lang>.json` via XHR asynchrone |
| `BeeConfig.setLang(lang)` | Met à jour `uiLang` + recharge `tr` |
| `user_config.json["lang"]` | Persistance du choix utilisateur |

### Flux de chargement au démarrage

```
Component.onCompleted
  └─ loadI18n("fr")        ← pré-charge le français immédiatement
  └─ loadConfig()
       └─ applyConfig(cfg)
            └─ if cfg.lang !== uiLang → loadI18n(cfg.lang)
```

### Pattern d'accès dans les QML

Toutes les chaînes utilisent un accès null-safe avec fallback intégré :

```qml
text: (BeeConfig.tr.section && BeeConfig.tr.section.key) || "Valeur de secours"
```

Ce pattern garantit que l'interface reste fonctionnelle même si le fichier i18n n'est pas encore chargé.

---

## Fichiers modifiés

### 1. `i18n/en.json` — Ajout de 30+ nouvelles clés

**Sections ajoutées :**
- `events.upcoming`, `events.see_calendar`
- `power.subtitle`, `power.footer`
- `search.loading`, `search.hint`
- `settings.palette`, `settings.palette_desc`
- `settings.nectar_sync`, `settings.nectar_sync_desc`
- `settings.motion`, `settings.motion_desc`
- `settings.vibe`, `settings.vibe_desc`
- `settings.clock`, `settings.clock_desc`
- `settings.focus_desc`, `settings.stealth_desc`
- `settings.sound`, `settings.sound_desc`
- `settings.language`, `settings.language_desc`
- `weather.conditions` — objet avec les 24 codes WMO + `"unknown"`

### 2. `i18n/fr.json` — Ajout des mêmes clés en français

Toutes les conditions météo (codes WMO 0–99) sont maintenant externalisées dans `weather.conditions`, ce qui permet de les traduire sans modifier le code QML.

### 3. `modules/BeeConfig.qml`

**Nouvelles propriétés :**
```qml
property string uiLang: "fr"
property var    tr:     ({})
```

**Nouvelles fonctions :**
```qml
function loadI18n(lang)   // Charge i18n/<lang>.json via XHR
function setLang(lang)    // Applique la langue + recharge tr
```

**Modifications de `applyConfig()` :**
- Lecture du champ `cfg.lang` → appel `loadI18n()` si différent

**Modifications de `saveConfig()` :**
- Écriture de `cfg.lang = uiLang`

**Modification de `Component.onCompleted` :**
- Pré-charge `fr.json` avant `loadConfig()` pour éviter un flash de chaînes vides

### 4. `modules/BeeSettings.qml`

**Changements majeurs :**
- Toutes les étiquettes et descriptions des toggles utilisent `BeeConfig.tr.settings.*`
- Hauteur du panneau ajustée de 640 → 680px pour accueillir le sélecteur de langue
- **Nouveau composant : sélecteur de langue**
  - Deux boutons pill `🇫🇷 FR` / `🇬🇧 EN`
  - Bouton actif : fond doré (22% opacity) + bordure accent (65%) + texte accent
  - Bouton inactif : fond discret (6%) + bordure légère
  - `onClicked` → `BeeConfig.setLang(code)` + `BeeConfig.saveConfig()`
  - Animation `ColorAnimation` 150ms sur les transitions hover/actif

### 5. `modules/BeeSearch.qml`

| Chaîne remplacée | Clé i18n |
|-----------------|----------|
| `"Chargement des applications…"` | `tr.search.loading` |
| `"Rechercher une application…"` | `tr.search.placeholder` |
| `"Aucun résultat pour «…»"` | `tr.search.no_results` + texte saisi |
| `"↑↓/Tab naviguer  ↵ lancer  Esc fermer"` | `tr.search.hint` |

### 6. `modules/BeePower.qml`

**Architecture modifiée :**
- Le modèle `Repeater` utilise désormais un champ `key` (`"shutdown"`, `"reboot"`, `"logout"`, `"lock"`) à la place du champ `label` statique
- La propriété `btnLabel` est calculée dynamiquement via `BeeConfig.tr.power[key]`
- Réactif aux changements de `BeeConfig.tr` grâce au binding QML

| Chaîne remplacée | Clé i18n |
|-----------------|----------|
| `"Que veux-tu faire ?"` | `tr.power.subtitle` |
| `"Éteindre"` | `tr.power.shutdown` |
| `"Redémarrer"` | `tr.power.reboot` |
| `"Déconnexion"` | `tr.power.logout` |
| `"Verrouiller"` | `tr.power.lock` |
| `"clic extérieur pour fermer"` | `tr.power.footer` |

### 7. `modules/BeeWeather.qml`

**Architecture modifiée :**
- `getWmoInfo(code)` lit les conditions depuis `BeeConfig.tr.weather.conditions[String(code)]` en priorité
- Fallback intégré (table française) si les traductions ne sont pas encore disponibles
- `condition` initialisée avec `tr.weather.loading`
- `"Erreur API"` remplacé par `tr.weather.error`
- Nouveau `Connections { target: BeeConfig; onTrChanged }` : relance `updateWeather()` lors d'un changement de langue pour mettre à jour la condition météo courante

### 8. `modules/BeeEvents.qml`

| Chaîne remplacée | Clé i18n |
|-----------------|----------|
| `"Prochains événements"` | `tr.events.upcoming` |
| `"Voir le calendrier →"` | `tr.events.see_calendar` |

### 9. `user_config.json`

**Champ ajouté :**
```json
"lang": "fr",
"_lang_comment": "Langue de l'interface : 'fr' (français) | 'en' (anglais). Changeable via BeeSettings."
```

---

## Nouvelles fonctionnalités

### Sélecteur de langue dans BeeSettings

Le panneau des paramètres dispose d'une nouvelle section **Langue** avec deux boutons pill visuellement distincts :

- Le bouton de la langue active est mis en évidence (fond doré, texte accent, bordure visible)
- Le changement de langue est instantané : tous les bindings QML se ré-évaluent
- La météo se rafraîchit automatiquement pour afficher les conditions dans la nouvelle langue
- Le choix est persisté dans `user_config.json` à chaque changement

### Réactivité complète

Grâce à la propriété `BeeConfig.tr` de type `var`, tous les bindings QML dans les 6 composants modifiés se réévaluent automatiquement dès que `setLang()` est appelé — sans rechargement de l'interface.

### Extensibilité

Pour ajouter une nouvelle langue (ex. espagnol) :
1. Copier `i18n/fr.json` → `i18n/es.json`
2. Traduire les valeurs (ne pas modifier les clés)
3. Ajouter un bouton `🇪🇸 ES` dans le sélecteur de BeeSettings
4. Aucune modification de code QML requise

---

## Chaînes non translatees (volontaire)

| Chaîne | Raison |
|--------|--------|
| `"BEE-HIVE"`, `"FOCUS"` dans BeeBar | Identité produit — marque invariable |
| `"CPU"`, `"RAM"`, `"NET"`, `"DISK"` dans BeeBar | Abréviations techniques identiques en FR/EN |
| `"BEE POWER"` dans BeePower | Nom de fonctionnalité — marque invariable |
| Noms d'alvéoles dans MayaDash | Contenu utilisateur personnalisé, géré via BeeStudio |
| Logs console (`console.log`, `console.warn`) | Messages de débogage internes |

---

## Tests recommandés

- [ ] Démarrer avec `"lang": "fr"` → interface en français
- [ ] Démarrer avec `"lang": "en"` → interface en anglais
- [ ] Basculer FR→EN dans BeeSettings → changement instantané de toutes les chaînes
- [ ] Vérifier que la météo se rafraîchit avec les conditions en anglais après bascule
- [ ] Ouvrir BeePower → boutons traduits selon la langue active
- [ ] Ouvrir BeeSearch → placeholder et hint traduits
- [ ] Redémarrer Bee-Hive OS avec `"lang": "en"` → langue persistée correctement
- [ ] Vérifier que `user_config.json` contient `"lang": "en"` après sauvegarde

---

## Statistiques

| Métrique | Valeur |
|---------|--------|
| Fichiers modifiés | 9 |
| Nouvelles clés i18n (par langue) | ~34 |
| Codes WMO traduits | 24 |
| Composants QML mis à jour | 6 |
| Lignes de code ajoutées (~) | ~120 |
| Langues supportées | 2 (FR, EN) |
| Architecture pour ajout futur | JSON + 1 bouton pill |

---

*Rapport de sprint — Bee-Hive OS i18n 🐝🌍*
