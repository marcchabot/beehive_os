#!/usr/bin/env bash
# Bee-Hive OS — Correctif post-migration BeeEvents (Bee-Live Sync v2)
# Usage: bash scripts/bee_fix_events.sh
#
# Corrige le bug où data/events.json est un symlink vide après la migration v2,
# et ajoute les URLs ICS connues dans user_config.json.

set -euo pipefail

BEEHIVE_DIR="${HOME}/beehive_os"
CONFIG_DIR="${HOME}/.config/beehive_os"
DATA_EVENTS="${BEEHIVE_DIR}/data/events.json"
USER_CONFIG="${BEEHIVE_DIR}/user_config.json"

echo "🐝 Bee-Hive OS — Correctif BeeEvents v2"

# 1. Supprimer le symlink si c'est le problème
if [[ -L "${DATA_EVENTS}" ]]; then
    rm "${DATA_EVENTS}"
    echo "  ✓ Symlink data/events.json supprimé (causait widget vide)"
elif [[ ! -f "${DATA_EVENTS}" ]]; then
    echo "  ℹ  data/events.json absent — sera régénéré"
fi

# 2. Régénérer data/events.json via sync_events.py
if python3 "${BEEHIVE_DIR}/scripts/sync_events.py" 2>/dev/null; then
    echo "  ✓ data/events.json régénéré avec les événements frais"
else
    echo "  ⚠ sync_events.py échoué (réseau ou auth) — les données statiques seront utilisées"
fi

# 3. Injecter l'URL ICS Pharmacie (Office365) dans user_config.json si absente
python3 - <<'PYEOF'
import json, os, sys

PHARMACIE_ICS = "https://outlook.office365.com/owa/calendar/6f5d92f21da74f34b231535c59720427@pharmaciechabot.com/fdb0b4bef82f42049d4ed21138dcdb326116550443663087075/S-1-8-3645858165-128246543-3786118207-2508868002/reachcalendar.ics"
cfg_path = os.path.expanduser("~/beehive_os/user_config.json")

try:
    with open(cfg_path) as f:
        cfg = json.load(f)
except Exception as e:
    print(f"  ⚠ Impossible de lire user_config.json: {e}")
    sys.exit(0)

calendars = cfg.get("calendars", [])
already_has_url = any(c.get("url") == PHARMACIE_ICS for c in calendars)

if already_has_url:
    print("  ✓ URL ICS Pharmacie déjà présente")
    sys.exit(0)

# Chercher une entrée pharmacie sans URL et la mettre à jour
updated = False
for c in calendars:
    if c.get("id") in ("pharmacie", "pharmacie_o365") and not c.get("url"):
        c["url"] = PHARMACIE_ICS
        updated = True
        break

if not updated:
    # Ajouter une nouvelle entrée
    calendars.append({
        "id": "pharmacie_o365",
        "type": "ics",
        "url": PHARMACIE_ICS,
        "label": "Pharmacie",
        "color": "#4CAF50"
    })

cfg["calendars"] = calendars
if "live_sync" not in cfg:
    cfg["live_sync"] = {"enabled": True, "interval_seconds": 900, "max_events": 5}

with open(cfg_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
print("  ✓ URL ICS Pharmacie (Office365) ajoutée dans user_config.json")
PYEOF

# 4. Redémarrer le daemon pour relire la config
if systemctl --user restart bee-sync.service 2>/dev/null; then
    echo "  ✓ Service bee-sync redémarré"
else
    echo "  ⚠ Impossible de redémarrer bee-sync (démarrer manuellement?)"
fi

echo ""
echo "✅ Correctif appliqué!"
echo ""
echo "   ► Pour ajouter vos calendriers Google Calendar :"
echo "     1. Aller sur calendar.google.com"
echo "     2. Paramètres → {Nom du calendrier} → 'Adresse secrète au format iCal'"
echo "     3. Copier l'URL et l'ajouter dans user_config.json → 'calendars'"
echo ""
echo "   ► Logs du daemon : journalctl --user -u bee-sync -f"
