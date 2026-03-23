import json
import os
import sys

def merge_config(local_path, template_path):
    print(f"🐝 Maya Config Merger v1.0 🐝")
    
    if not os.path.exists(local_path):
        print(f"❌ Erreur: {local_path} non trouvé.")
        return

    if not os.path.exists(template_path):
        print(f"❌ Erreur: {template_path} non trouvé.")
        return

    try:
        with open(local_path, 'r') as f:
            local_cfg = json.load(f)
        with open(template_path, 'r') as f:
            template_cfg = json.load(f)
    except Exception as e:
        print(f"❌ Erreur lors de la lecture du JSON: {e}")
        return

    # Champs à préserver absolument (données utilisateur)
    preserve_keys = ['dashboard', 'pinned_apps', 'weather', 'lang', 'theme']
    
    # Créer le nouveau config basé sur le template (pour avoir les nouvelles structures)
    new_cfg = template_cfg.copy()
    
    # Restaurer les données perso
    for key in preserve_keys:
        if key in local_cfg:
            new_cfg[key] = local_cfg[key]
            print(f"✅ Restauration de la clé: {key}")

    # Cas particulier : ne pas écraser la version du template si elle est plus récente
    if 'version' in local_cfg and 'version' in template_cfg:
        # On garde la version du template car c'est une mise à jour
        print(f"🚀 Mise à jour vers la version: {template_cfg['version']}")

    # Sauvegarder
    backup_path = local_path + ".bak"
    try:
        with open(backup_path, 'w') as f:
            json.dump(local_cfg, f, indent=2)
        print(f"💾 Backup créé: {backup_path}")
        
        with open(local_path, 'w') as f:
            json.dump(new_cfg, f, indent=2)
        print(f"✨ Fusion terminée avec succès! Votre user_config.json est à jour. 🍯")
    except Exception as e:
        print(f"❌ Erreur lors de l'écriture: {e}")

if __name__ == "__main__":
    # Chemins relatifs au dossier beehive_os
    home = os.path.expanduser("~")
    base_dir = os.path.join(home, "beehive_os")
    
    local = os.path.join(base_dir, "user_config.json")
    template = os.path.join(base_dir, "user_config.example.json")
    
    merge_config(local, template)
