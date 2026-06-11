# Audit statique baseline — Bee-Hive OS

> Généré le 2026-06-10 23:19
> Outil : `qa/audit-static.py`
> But : point de référence pour mesurer la progression des correctifs

## Résumé

29 fichiers concernés, 50 issues au total

## Détail complet

```
=== 28 fichiers avec issues, 50 issues au total ===

=== modules/BeeStudio.qml  (127,297 bytes, score 256)
   [MIN ] anchors.fill_sans_margins: 53 anchors.fill mais seulement 15 anchors.margins
   [MAJ ] rectangle_sans_clip: 60 Rectangle, seulement 9 avec clip:true

=== modules/MayaDash.qml  (144,708 bytes, score 234)
   [MIN ] anchors.fill_sans_margins: 50 anchors.fill mais seulement 14 anchors.margins
   [MAJ ] rectangle_sans_clip: 54 Rectangle, seulement 1 avec clip:true

=== modules/BeeCalendar.qml  (122,673 bytes, score 226)
   [MIN ] anchors.fill_sans_margins: 47 anchors.fill mais seulement 15 anchors.margins
   [MAJ ] rectangle_sans_clip: 52 Rectangle, seulement 8 avec clip:true
   [MAJ ] listview_sans_scrollbar: 2 ListView/GridView sans ScrollBar visible

=== modules/BeeBar.qml  (37,995 bytes, score 112)
   [MIN ] anchors.fill_sans_margins: 8 anchors.fill mais seulement 0 anchors.margins
   [MAJ ] rectangle_sans_clip: 20 Rectangle, seulement 0 avec clip:true
   [MIN ] text_sans_elide_wrap: 18 Text, aucun elide ni wrapMode

=== modules/GeneralTab.qml  (36,626 bytes, score 102)
   [MIN ] anchors.fill_sans_margins: 18 anchors.fill mais seulement 6 anchors.margins
   [MAJ ] rectangle_sans_clip: 26 Rectangle, seulement 3 avec clip:true

=== modules/BarWidgetsTab.qml  (47,696 bytes, score 95)
   [MIN ] anchors.fill_sans_margins: 17 anchors.fill mais seulement 7 anchors.margins
   [MAJ ] rectangle_sans_clip: 25 Rectangle, seulement 3 avec clip:true

=== modules/BeeTheme.qml  (32,896 bytes, score 82)
   [MIN ] hex_colors_hardcoded: 41 couleurs hex hardcodees

=== modules/MayaDashConfigCells.qml  (36,430 bytes, score 81)
   [MIN ] anchors.fill_sans_margins: 17 anchors.fill mais seulement 5 anchors.margins
   [MAJ ] rectangle_sans_clip: 19 Rectangle, seulement 4 avec clip:true

=== modules/ProductivityTab.qml  (46,654 bytes, score 74)
   [MIN ] anchors.fill_sans_margins: 8 anchors.fill mais seulement 1 anchors.margins
   [MAJ ] rectangle_sans_clip: 20 Rectangle, seulement 1 avec clip:true

=== modules/BeeSearch.qml  (23,587 bytes, score 69)
   [MIN ] anchors.fill_sans_margins: 8 anchors.fill mais seulement 0 anchors.margins
   [MAJ ] rectangle_sans_clip: 11 Rectangle, seulement 2 avec clip:true
   [MIN ] text_sans_elide_wrap: 10 Text, aucun elide ni wrapMode

=== modules/DashboardTab.qml  (36,740 bytes, score 67)
   [MIN ] anchors.fill_sans_margins: 6 anchors.fill mais seulement 1 anchors.margins
   [MAJ ] rectangle_sans_clip: 19 Rectangle, seulement 1 avec clip:true

=== modules/BeeWelcome.qml  (42,846 bytes, score 60)
   [MIN ] anchors.fill_sans_margins: 9 anchors.fill mais seulement 0 anchors.margins
   [MAJ ] rectangle_sans_clip: 14 Rectangle, seulement 0 avec clip:true

=== modules/AppearanceTab.qml  (25,102 bytes, score 59)
   [MIN ] anchors.fill_sans_margins: 11 anchors.fill mais seulement 4 anchors.margins
   [MAJ ] rectangle_sans_clip: 15 Rectangle, seulement 2 avec clip:true

=== modules/BeeOSD.qml  (18,363 bytes, score 54)
   [MIN ] anchors.fill_sans_margins: 6 anchors.fill mais seulement 2 anchors.margins
   [MAJ ] rectangle_sans_clip: 10 Rectangle, seulement 1 avec clip:true
   [MIN ] text_sans_elide_wrap: 8 Text, aucun elide ni wrapMode

=== modules/AccessibilityTab.qml  (25,186 bytes, score 48)
   [MIN ] anchors.fill_sans_margins: 5 anchors.fill mais seulement 2 anchors.margins
   [MAJ ] rectangle_sans_clip: 14 Rectangle, seulement 1 avec clip:true

=== modules/BeeNotes.qml  (22,966 bytes, score 36)
   [MAJ ] rectangle_sans_clip: 11 Rectangle, seulement 1 avec clip:true
   [MAJ ] listview_sans_scrollbar: 1 ListView/GridView sans ScrollBar visible

=== modules/BeeSystemMonitor.qml  (26,191 bytes, score 33)
   [MAJ ] rectangle_sans_clip: 10 Rectangle, seulement 1 avec clip:true
   [MAJ ] listview_sans_scrollbar: 1 ListView/GridView sans ScrollBar visible

=== modules/BeePower.qml  (12,176 bytes, score 26)
   [MIN ] anchors.fill_sans_margins: 6 anchors.fill mais seulement 0 anchors.margins
   [MIN ] text_sans_elide_wrap: 7 Text, aucun elide ni wrapMode

=== modules/BeeReminder.qml  (17,454 bytes, score 21)
   [MAJ ] rectangle_sans_clip: 7 Rectangle, seulement 1 avec clip:true

=== modules/BeeVoice.qml  (18,907 bytes, score 18)
   [MAJ ] rectangle_sans_clip: 6 Rectangle, seulement 0 avec clip:true

=== modules/BeeControl.qml  (12,732 bytes, score 14)
   [MIN ] anchors.fill_sans_margins: 8 anchors.fill mais seulement 1 anchors.margins

=== modules/ExtensionsTab.qml  (3,467 bytes, score 12)
   [MIN ] text_sans_elide_wrap: 6 Text, aucun elide ni wrapMode

=== modules/BeeNotify.qml  (11,146 bytes, score 11)
   [MIN ] anchors.fill_sans_margins: 7 anchors.fill mais seulement 3 anchors.margins
   [MAJ ] listview_sans_scrollbar: 1 ListView/GridView sans ScrollBar visible

=== modules/BeeWallpaper.qml  (4,022 bytes, score 8)
   [MIN ] anchors.fill_sans_margins: 4 anchors.fill mais seulement 0 anchors.margins

=== modules/Clock.qml  (10,871 bytes, score 8)
   [MIN ] text_sans_elide_wrap: 4 Text, aucun elide ni wrapMode

=== modules/BeeWeatherDetail.qml  (29,332 bytes, score 6)
   [MAJ ] listview_sans_scrollbar: 2 ListView/GridView sans ScrollBar visible

=== modules/MayaDashConfig.qml  (11,001 bytes, score 6)
   [MIN ] anchors.fill_sans_margins: 4 anchors.fill mais seulement 1 anchors.margins

=== modules/HistoryTab.qml  (5,351 bytes, score 3)
   [MAJ ] listview_sans_scrollbar: 1 ListView/GridView sans ScrollBar visible


```

## Comment re-générer

```bash
cd /home/marc/.hermes/sandbox/beehive-os
python3 qa/audit-static.py > qa/audit-baseline.txt
```

## Interprétation des scores

- Score = somme pondérée (critical=4, major=3, minor=2, nit=1) × count
- Plus le score est haut, plus le fichier a de chance de contenir des bugs visuels
- L'objectif v1.0 est de réduire le score total de 50%+ sur le top 10
