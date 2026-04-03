# Assets Sounds - Bee-Hive OS

Ce répertoire contient les sons utilisés par le module BeeSound 3.0.

## Structure

```
assets/sounds/
├── .gitkeep                      # Pour maintenir le dossier dans Git
├── button-pressed.ogg    -> pack/button-pressed.ogg
├── audio-volume-change.ogg -> pack/audio-volume-change.ogg
├── message.ogg           -> pack/message.ogg
├── power-plug.ogg        -> pack/power-plug.ogg
└── pack/
    ├── PremiumBeat_0013_cursor_click_01.ogg (button-pressed)
    ├── PremiumBeat_0013_cursor_selection_02.ogg (audio-volume-change)
    ├── PremiumBeat_0046_sci_fi_beep_button_6.ogg (message)
    └── PremiumBeat_0046_sci_fi_device_3.ogg (power-plug)
```

## Notes

- Les fichiers `.ogg` sont au format Opus (96k, 48kHz) optimisé pour BeeSound.
- Les liens symboliques à la racine permettent une auto-décection par BeeSound.
- Ne garder que les fichiers listés ci-dessus. Supprimer tout le reste pour maintenir un dépôt léger.
- Pour ajouter ou modifier un son :
  1. Remplacer le fichier correspondant dans `pack/`
  2. Mettre à jour le lien symbolique si nécessaire
  3. Tester dans l'interface

## Licence

Les sons proviennent du pack "PB-Sci-Fi-UI-Free-SFX1" de PremiumBeat.
Voir le fichier PDF original (non inclus) pour les termes de licence.
