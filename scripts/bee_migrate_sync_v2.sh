#!/usr/bin/env bash
# Bee-Live Sync v2 — Migration depuis la v1
# Usage: bash scripts/bee_migrate_sync_v2.sh

set -euo pipefail

BEEHIVE_DIR="${HOME}/beehive_os"
CONFIG_DIR="${HOME}/.config/beehive_os"
CACHE_DIR="${HOME}/.cache/beehive"

echo "🐝 Bee-Live Sync v2 — Migration"

# 1. Créer les répertoires nécessaires
mkdir -p "${CONFIG_DIR}" "${CACHE_DIR}"
echo "  ✓ Répertoires créés: ${CONFIG_DIR}"

# 2. Migrer la config via bee_config_merge.py (déclenche migrate_v1_to_v2)
if [[ -f "${BEEHIVE_DIR}/scripts/bee_config_merge.py" ]]; then
    python3 "${BEEHIVE_DIR}/scripts/bee_config_merge.py"
    echo "  ✓ Configuration migrée vers v2.0"
else
    echo "  ⚠ bee_config_merge.py non trouvé, migration manuelle requise"
fi

# 3. Vérifier les dépendances Python
python3 -c "import aiohttp, icalendar" 2>/dev/null || {
    echo "  ⚠ Installation des dépendances Python..."
    pip install --user aiohttp icalendar
}
echo "  ✓ Dépendances Python OK"

# 4. Installer le service systemd
SERVICE_SRC="${BEEHIVE_DIR}/config/systemd/bee-sync.service"
SERVICE_DST="${HOME}/.config/systemd/user/bee-sync.service"
if [[ -f "${SERVICE_SRC}" ]]; then
    mkdir -p "$(dirname "${SERVICE_DST}")"
    cp "${SERVICE_SRC}" "${SERVICE_DST}"
    chmod +x "${BEEHIVE_DIR}/scripts/bee_sync_daemon.py" 2>/dev/null || true
    systemctl --user daemon-reload
    systemctl --user enable --now bee-sync.service
    echo "  ✓ Service bee-sync activé"
else
    echo "  ⚠ Fichier service non trouvé: ${SERVICE_SRC}"
fi

# 5. Première sync immédiate (via daemon ou fallback)
echo "  → Première synchronisation..."
if systemctl --user is-active --quiet bee-sync.service; then
    systemctl --user restart bee-sync.service
    sleep 2
else
    python3 "${BEEHIVE_DIR}/scripts/bee_sync_daemon.py" --once 2>/dev/null || \
    python3 "${BEEHIVE_DIR}/scripts/honey_sync_ics.py" 2>/dev/null || true
fi

# 6. Créer un lien symbolique de compatibilité (optionnel)
LEGACY_DIR="${BEEHIVE_DIR}/data"
LIVE_JSON="${CONFIG_DIR}/events_live.json"
if [[ -f "${LIVE_JSON}" && ! -L "${LEGACY_DIR}/events.json" ]]; then
    mkdir -p "${LEGACY_DIR}"
    ln -sf "${LIVE_JSON}" "${LEGACY_DIR}/events.json"
    echo "  ✓ Lien de compatibilité v1 créé"
fi

echo ""
echo "✅ Migration Bee-Live Sync v2 terminée!"
echo "   Logs: journalctl --user -u bee-sync -f"
echo "   Config: ${CONFIG_DIR}"
echo "   Service: systemctl --user status bee-sync"
