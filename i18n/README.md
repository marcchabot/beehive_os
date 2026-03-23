# Bee-Hive OS — i18n

Répertoire de traductions pour Bee-Hive OS.

## Structure

```
i18n/
├── fr.json   # Français (langue par défaut)
├── en.json   # English
└── README.md
```

## Ajouter une langue

1. Copier `en.json` et renommer en `<code_iso2>.json` (ex: `de.json`, `es.json`).
2. Traduire toutes les valeurs (ne pas modifier les clés).
3. Mettre à jour `user_config.json` : `"lang": "<code_iso2>"`.

## Intégration QML (prochaine étape)

Pour activer les traductions dans les fichiers `.qml` :

```qml
// Dans BeeConfig.qml — chargement du fichier de langue
property var i18n: JSON.parse(file.read("i18n/" + lang + ".json"))

// Usage dans un composant
text: i18n.settings.title
```

Le champ `lang` dans `user_config.json` → `weather.lang` pilote la langue d'interface.
Un sélecteur visuel sera ajouté dans **BeeSettings** (Phase 4 complète).
