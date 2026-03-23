import json
import os
import sys

def merge_config(local_path, template_path):
    print(f"🐝 Maya Config Merger v1.0 🐝")
    
    if not os.path.exists(local_path):
        print(f"❌ Error: {local_path} not found.")
        return

    if not os.path.exists(template_path):
        print(f"❌ Error: {template_path} not found.")
        return

    try:
        with open(local_path, 'r') as f:
            local_cfg = json.load(f)
        with open(template_path, 'r') as f:
            template_cfg = json.load(f)
    except Exception as e:
        print(f"❌ Error reading JSON: {e}")
        return

    # Fields to preserve absolutely (user data)
    preserve_keys = ['dashboard', 'pinned_apps', 'weather', 'lang', 'theme']
    
    # Create new config based on template (to get new structures)
    new_cfg = template_cfg.copy()
    
    # Restore personal data
    for key in preserve_keys:
        if key in local_cfg:
            new_cfg[key] = local_cfg[key]
            print(f"✅ Restored key: {key}")

    # Special case: don't overwrite template version if it's newer
    if 'version' in local_cfg and 'version' in template_cfg:
        # Keep template version since this is an upgrade
        print(f"🚀 Upgrading to version: {template_cfg['version']}")

    # Sauvegarder
    backup_path = local_path + ".bak"
    try:
        with open(backup_path, 'w') as f:
            json.dump(local_cfg, f, indent=2)
        print(f"💾 Backup created: {backup_path}")
        
        with open(local_path, 'w') as f:
            json.dump(new_cfg, f, indent=2)
        print(f"✨ Merge successful! Your user_config.json is up to date. 🍯")
    except Exception as e:
        print(f"❌ Error writing: {e}")

if __name__ == "__main__":
    # Paths relative to beehive_os directory
    home = os.path.expanduser("~")
    base_dir = os.path.join(home, "beehive_os")
    
    local = os.path.join(base_dir, "user_config.json")
    template = os.path.join(base_dir, "user_config.example.json")
    
    merge_config(local, template)
)
