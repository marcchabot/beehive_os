# 🐝 BeeHive Editor v2 — Spécification de Redesign

**Date:** 19 avril 2026  
**Auteur:** Maya & Marc  
**Portée:** Refonte de l'onglet "Alvéoles" (Dashboard → Cells) dans BeeStudio

---

## 🎯 Objectifs

1. **Unifier Cells + Presets** en un seul onglet cohérent
2. **Prévisualisation live** de la grille MayaDash dans BeeStudio
3. **Drag & drop visuel** directement dans l'éditeur
4. **Édition intuitive** avec sélecteur d'emoji et actions pré-définies
5. **Feedback instantané** — chaque changement se reflète immédiatement

---

## 🏗️ Architecture : Onglet Unifié "Mes Alvéoles"

### Layout Principal (3 colonnes)

```
┌──────────────────────────────────────────────────────────────┐
│  🍯 Mes Alvéoles                                    [+] [💾] │
├──────────┬───────────────────────────┬───────────────────────┤
│          │                           │                       │
│  MINI    │     ÉDITEUR DE CELLULE    │   PANNEAU ACTIONS     │
│  GRILLE  │                           │   & PRÉSETS           │
│  (aperçu)│                           │                       │
│          │                           │  ┌─────────────────┐  │
│  ┌──┬──┐ │  ┌─────────────────────┐  │  │ 🎯 Presets      │  │
│  │📅│📝│ │  │  📅 Famille Chabot  │  │  │ ┌─────┐ ┌─────┐ │  │
│  ├──┼──┤ │  │  Calendrier familial │  │  │ │Trav. │ │Game. │ │  │
│  │🐝│🌐│ │  │  3 événements       │  │  │ └─────┘ └─────┘ │  │
│  ├──┼──┤ │  │  ▶ url:calendar...  │  │  │ ┌─────┐ ┌─────┐ │  │
│  │🖥️│💰│ │  └─────────────────────┘  │  │ │Wknd. │ │+ New│ │  │
│  ├──┼──┤ │                           │  │ └─────┘ └─────┘ │  │
│  │🎮│⚙️│ │  [Icône] [Titre]          │  └─────────────────┘  │
│  └──┴──┘ │  [Sous-titre] [Détail]    │                       │
│          │  [Action ▼] [✨ Highlight] │   Module Registry    │
│          │  [Appliquer] [Réinitialiser│   ┌───────────────┐  │
│          │                           │   │ 🌐 Réseau     │  │
│          │                           │   │ 📅 Calendrier  │  │
│          │                           │   │ 📧 Courriel    │  │
│          │                           │   │ + Ajouter...   │  │
│          │                           │   └───────────────┘  │
└──────────┴───────────────────────────┴───────────────────────┘
```

---

## 📐 Composants Détaillés

### 1. Mini-Grille (Gauche — 200px)

- **Réplique miniature** de la grille hexagonale MayaDash (2-3-3)
- **Sélection visuelle** : l'alvéole sélectionnée brille (bordure accent + glow)
- **Drag & drop** : réorganiser en glissant les mini-hexagones
- **Temps réel** : reflète instantanément tout changement (icône, titre, etc.)
- **Non-éditable** directement — clic pour sélectionner, double-clic pour éditer

**Spécifications QML :**
- Scale factor : 0.45x par rapport au MayaDash réel
- HexCell simplifié : icône + titre uniquement (pas de sous-titre/détail)
- Hover effect : bordure accent + scale 1.05
- Selected : glow accent + bordure animée
- Drag : même mécanique que MayaDash (long-press → swap)

### 2. Éditeur de Cellule (Centre — flexible)

Quand une cellule est sélectionnée, afficher un **aperçu grand format** de l'alvéole en haut, suivi du formulaire d'édition.

#### Aperçu Grand Format
```
┌─────────────────────────────┐
│         📅 (42px)           │
│    Famille Chabot            │
│    Calendrier familial       │
│    3 événements à venir      │
│    ▶ url:calendar.google... │
│         [✨ Highlighted]     │
└─────────────────────────────┘
```
- Affiche l'alvéole exactement comme dans MayaDash
- **Live preview** : chaque champ édité met à jour l'aperçu en temps réel
- Fond hexagonal stylisé (same colors/theme que MayaDash)

#### Formulaire d'Édition

**Sélecteur d'Icône** (au lieu du champ texte brut) :
```
[Icône actuelle: 📅 ] [🎨 Choisir...]

┌──────────────────────────────────────┐
│ Emojis populaires:                    │
│ 📅 📧 🌐 🖥️ 💰 🎮 ⚙️ 🐝 📝 🎵 🌤️ 🔒 │
│ ❤️ 📊 🛒 🎬 📱 💡 🏠 ✈️ 🎓 ☕ 📸       │
│                                       │
│ [Rechercher...]         [Custom...]   │
└──────────────────────────────────────┘
```
- Grille d'emojis populaires (2-3 lignes)
- Champ de recherche emoji (filtrage en temps réel)
- Bouton "Custom" pour entrer un emoji non listé

**Champ Titre** : TextField avec placeholder (ex: "Famille Chabot")

**Champ Sous-titre** : TextField avec placeholder

**Champ Détail** : TextEdit multiligne (inchangé)

**Sélecteur d'Action** (au lieu du champ texte brut) :
```
┌──────────────────────────────────────┐
│ Type d'action :                       │
│ ○ Aucune (none)                       │
│ ○ Application (app:)    [kitty ▼]    │
│ ○ URL (url:)           [https://...▼] │
│ ○ Toggle (toggle:)     [settings ▼]  │
│ ○ Détail (detail:)     [network ▼]   │
│                                       │
│ Action complète : url:https://cal...  │
└──────────────────────────────────────┘
```
- **Radio buttons** pour le type d'action
- **Dropdown** pré-rempli pour les valeurs courantes
- Champ texte éditable pour les actions personnalisées
- Presets d'applications : kitty, firefox, discord, steam, etc.

**Toggle Highlighted** : Switch avec label descriptif (inchangé)

**Boutons :**
- [✅ Appliquer] — sauvegarde les modifications
- [🔄 Réinitialiser] — annule les modifications non sauvegardées

### 3. Panneau Droit — Presets & Modules (260px)

#### Section Presets (haut)
- **Grille de cartes preset** (2 colonnes, style actuel)
- Chaque carte : icône + nom + aperçu miniature (6 mini-hex)
- Clic → appliquer le preset
- Bouton [+] pour créer un preset depuis la grille actuelle
- Presets par défaut : Travail, Gaming, Weekend (non-supprimables, 🔒)
- Presets personnalisés : supprimables

#### Section Module Registry (bas)
- **Liste des modules disponibles** non-utilisés
- Chaque module : icône + nom + description courte
- Bouton [+] pour ajouter à la première position vide
- Modules : Réseau, Calendrier, Courriel, Système, Météo, Gaming, Notes, Analytics
- Seuls les modules pas déjà dans la grille sont affichés

---

## 🔄 Flux de Travail Utilisateur

### Scénario 1 : Réorganiser les alvéoles
1. Ouvrir BeeStudio → onglet "Mes Alvéoles"
2. Glisser une mini-alvéole vers une autre position dans la mini-grille
3. La grille se met à jour en temps réel (swap)
4. Le MayaDash reflète le changement immédiatement

### Scénario 2 : Éditer une alvéole
1. Cliquer sur une alvéole dans la mini-grille
2. L'aperçu grand format et le formulaire apparaissent au centre
3. Modifier l'icône (sélecteur emoji), le titre, etc.
4. L'aperçu se met à jour en temps réel
5. Cliquer "Appliquer" pour sauvegarder

### Scénario 3 : Changer de preset
1. Cliquer sur un preset dans le panneau droit
2. Confirmation visuelle (animation de transition)
3. Toutes les alvéoles se mettent à jour
4. Le MayaDash reflète le changement immédiatement

### Scénario 4 : Ajouter un module
1. Cliquer [+] sur un module dans le Module Registry
2. Le module est ajouté à la première position vide
3. Si pas de position vide : notification "Grille pleine"

---

## 🎨 Design Tokens

- **Mini-hex scale** : 0.45x (environ 100x110px par cell)
- **Mini-hex spacing** : -15px (au lieu de -30px)
- **Aperçu scale** : 1.0x (même taille que MayaDash)
- **Preset cards** : 180x200px (inchangé)
- **Couleurs** : même palette que BeeStudio actuel (accent, glassBg, etc.)
- **Animations** : transitions de 150-200ms (cohérent avec BeeStudio existant)

---

## ⚙️ Contraintes Techniques

1. **Pas de breaking changes** — le code existant (BeePresets, BeeConfig.cells) continue de fonctionner
2. **BeePresets.qml** est conservé mais le panneau Presets dans BeeStudio est refondu pour utiliser la nouvelle UI
3. **BeeModuleRegistry.qml** est enrichi avec descriptions et catégories pour le Module Registry
4. **i18n** — tous les nouveaux labels doivent passer par `tr()` ( BeeConfig.tr )
5. **Drag & drop** — réutiliser la logique swapCells de BeePresets
6. **Thème Dark/Light** — le nouvel onglet doit respecter BeeTheme comme le reste

---

## 📁 Fichiers à Modifier/Créer

| Fichier | Action | Description |
|---------|--------|-------------|
| `modules/BeeStudio.qml` | Modifier | Refonte onglet Cells, fusion avec Presets |
| `modules/BeeStudio/EmojiPicker.qml` | Créer | Sélecteur d'emoji réutilisable |
| `modules/BeeStudio/ActionEditor.qml` | Créer | Sélecteur d'action avec radio buttons |
| `modules/BeeStudio/MiniHexGrid.qml` | Créer | Mini-grille hexagonale avec drag & drop |
| `modules/BeeStudio/CellPreview.qml` | Créer | Aperçu grand format d'une alvéole |
| `modules/BeeStudio/ModuleRegistry.qml` | Créer | Panneau des modules disponibles |
| `modules/BeeModuleRegistry.qml` | Modifier | Ajouter descriptions et catégories |
| `modules/BeePresets.qml` | Modifier | Ajouter tr() pour nouveaux labels |

---

## 🚀 Plan d'Implémentation (Sprint)

### Phase 1 : Structure de base
- Créer le dossier `modules/BeeStudio/`
- Implémenter `MiniHexGrid.qml` (mini-grille avec sélection + drag)
- Implémenter `CellPreview.qml` (aperçu grand format)

### Phase 2 : Éditeur intuitif
- Implémenter `EmojiPicker.qml` (grille + recherche)
- Implémenter `ActionEditor.qml` (radio buttons + dropdown)
- Intégrer le formulaire rénové

### Phase 3 : Panneau droit
- Migrer les Presets dans le nouveau layout
- Créer `ModuleRegistry.qml`
- Intégrer avec BeeModuleRegistry

### Phase 4 : Fusion & Polish
- Fusionner les onglets "Dashboard" et "Alvéoles" en un seul
- Supprimer l'onglet "Presets" séparé (4→4 onglets : Dashboard, Mes Alvéoles, Fonds d'écran, Historique)
- Animations de transition entre presets
- Tests Dark/Light

---

*Document version 1.0 — 18 avril 2026*
*Par Maya 🐝*