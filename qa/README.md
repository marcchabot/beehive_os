# Bee-Hive OS — QA Visuelle

Ce dossier contient la méthodologie et le tracking des bugs visuels pour atteindre v1.0.

## Philosophie

On ne peut pas se permettre de QA aléatoire "au feeling". Chaque fenêtre, chaque composant
intégré doit passer par une checklist standardisée AVANT de pouvoir être marqué comme
"visuellement propre" pour v1.0.

## Workflow

```
1. INSPECTER  →  Ouvrir la fenêtre, prendre 1-3 screenshots
2. COCHER     →  Passer la checklist (qa/checklists/<Module>.md)
3. SIGNALER   →  Si bug trouvé, créer un BUG-XXX dans qa/visual-bugs.md
4. PATCHER    →  Fix QML, commiter atomiquement
5. VÉRIFIER   →  Re-screenshot, confirmer, fermer le bug
```

## Nomenclature des bugs

Format : `BUG-NNN-courte-description-kebab-case`

Exemples :
- `BUG-001-bee-bar-text-overflow-right-edge`
- `BUG-002-mayadash-icons-clipping-on-resize`
- `BUG-003-bee-welcome-scrollbar-missing`

Les bugs sont trackés dans `qa/visual-bugs.md` avec statut, sévérité, fichier, et statut de fix.

## Sévérités

- **🔴 BLOQUANT** — fenêtre inutilisable, breakage visible immédiatement
- **🟠 MAJEUR** — défaut visible, dégradation UX significative
- **🟡 MINEUR** — cosmétique, alignement, padding
- **🟢 NIT** — subjectif, pourrait rester en v1.0

## Priorité d'inspection

D'après l'audit statique du 10 juin 2026, ordre recommandé :

1. **MayaDash.qml** (144 KB, 50 anchors.fill suspects, 1 seul clip)
2. **BeeStudio.qml** (127 KB, 53 anchors.fill, 60 Rectangle)
3. **BeeCalendar.qml** (122 KB, 47 anchors.fill)
4. **BeeConfig.qml** (90 KB, parent de tous les *Tab)
5. **BarWidgetsTab.qml** (47 KB, 17 anchors.fill)
6. **ProductivityTab.qml** (46 KB)
7. **DashboardTab.qml** (36 KB)
8. **BeeBar.qml** (37 KB, 0 anchors.margins, 18 Text sans elide)
9. **BeeWelcome.qml** (42 KB, 9 anchors.fill, 0 marges)
10. Reste par taille décroissante

## Checklist standard par fenêtre

Voir `qa/checklists/_TEMPLATE.md` et un exemple par module.

## Audit statique préventif

L'outil `qa/audit-static.py` scanne tous les .qml et détecte les anti-patterns connus :
- anchors.fill sans anchors.margins
- Rectangle sans clip:true
- Text sans elide ni wrapMode
- ListView sans ScrollBar
- Couleurs hex hardcodées (à migrer vers theme)

Usage : `python3 qa/audit-static.py`

## Fichiers

- `qa/visual-bugs.md` — registre principal des bugs (statut, sévérité, lien commit)
- `qa/checklists/_TEMPLATE.md` — checklist standard par fenêtre
- `qa/checklists/<Module>.md` — checklist par module
- `qa/audit-static.py` — script d'audit préventif
- `qa/screenshots/` — dossier pour les screenshots fournis par Marc
