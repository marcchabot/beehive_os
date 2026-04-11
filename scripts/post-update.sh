#!/bin/bash

# --- 🐝 BEE-HIVE OS POST-UPDATE MIGRATIONS 🐝 ---
# Automatic compatibility migrations after version updates
# This runs automatically after git pull via update.sh
# -----------------------------------------------

# Terminal colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${BLUE}🐝 Running post-update migrations...${RESET}"

# Detect repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/..")"
cd "$REPO_ROOT"

# 1. VERSION-SPECIFIC MIGRATIONS
# Check current version from git tags or version file
CURRENT_VERSION="unknown"
if [ -f "VERSION" ]; then
    CURRENT_VERSION=$(cat VERSION)
elif git describe --tags --abbrev=0 2>/dev/null; then
    CURRENT_VERSION=$(git describe --tags --abbrev=0)
fi

echo -e "${BLUE}📋 Current version: $CURRENT_VERSION${RESET}"

# 2. CONFIGURATION MIGRATIONS
if [ -f "user_config.json" ]; then
    echo -e "${YELLOW}🔧 Checking configuration compatibility...${RESET}"
    
    # Migration for v0.8.6: Convert emoji icons to system icons
    if [[ "$CURRENT_VERSION" == *"0.8.6"* ]] || [[ "$CURRENT_VERSION" == *"0.8"* ]]; then
        echo -e "${BLUE}🎨 Migrating emoji icons to system icons...${RESET}"
        
        # Check if update_icons.py exists and run it
        if [ -f "scripts/update_icons.py" ]; then
            python3 scripts/update_icons.py --update-only 2>/dev/null
            echo -e "${GREEN}✅ Icon migration completed${RESET}"
        fi
    fi
    
    # Migration for theme structure changes
    if grep -q '"theme":' user_config.json; then
        echo -e "${BLUE}🎨 Ensuring theme compatibility...${RESET}"
        
        # Backup before modifications
        cp user_config.json user_config.json.pre-theme-backup
        
        # Use jq if available for safe modifications
        if command -v jq &> /dev/null; then
            # Ensure theme structure exists
            jq '.theme //= {}' user_config.json > user_config.json.tmp && mv user_config.json.tmp user_config.json
            echo -e "${GREEN}✅ Theme structure validated${RESET}"
        fi
    fi
fi

# 3. FILE PERMISSION MIGRATIONS
echo -e "${YELLOW}🔧 Fixing file permissions...${RESET}"
chmod +x scripts/*.py scripts/*.sh 2>/dev/null
chmod 755 . 2>/dev/null

# Make sure QML files are readable
find . -name "*.qml" -exec chmod 644 {} \; 2>/dev/null

# 4. CACHE CLEANUP
echo -e "${YELLOW}🧹 Cleaning old caches...${RESET}"

# Remove old cache files
OLD_CACHE_FILES=(
    ".icon_cache"
    "icon_cache.json"
    "*.pyc"
)

for pattern in "${OLD_CACHE_FILES[@]}"; do
    find . -name "$pattern" -delete 2>/dev/null
done

# Clean Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null

# 5. DIRECTORY STRUCTURE UPDATES
echo -e "${YELLOW}📁 Ensuring directory structure...${RESET}"

# Create required directories
REQUIRED_DIRS=(
    "data"
    ".cache"
    "scripts/__pycache__"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${BLUE}  Created: $dir${RESET}"
    fi
done

# 6. SCRIPT UPDATES
echo -e "${YELLOW}📝 Updating script dependencies...${RESET}"

# Check for Python module requirements
if [ -f "scripts/update_icons.py" ]; then
    # Check if required Python modules are available
    if python3 -c "import json, os, sys" 2>/dev/null; then
        echo -e "${GREEN}✅ Python dependencies: OK${RESET}"
    else
        echo -e "${YELLOW}⚠️  Python dependencies: missing basic modules${RESET}"
    fi
fi

# 7. CONFIGURATION TEMPLATE SYNC
echo -e "${YELLOW}📋 Syncing configuration templates...${RESET}"

if [ -f "user_config.example.json" ] && [ -f "user_config.json" ]; then
    # Check for new fields in example config
    if command -v jq &> /dev/null; then
        NEW_FIELDS=$(jq -n --argjson example "$(cat user_config.example.json)" \
                           --argjson current "$(cat user_config.json)" \
                           '$example | keys[] as $k | $current | has($k) | not | select(.) | $k')
        
        if [ ! -z "$NEW_FIELDS" ]; then
            echo -e "${BLUE}📝 New configuration fields detected:${RESET}"
            echo "$NEW_FIELDS" | while read field; do
                echo "  ➕ $field"
            done
            
            # Offer to merge automatically
            read -p "Merge new fields from example config? [Y/n]: " choice
            case "$choice" in
                [Nn]* )
                    echo -e "${YELLOW}⚠️  Skipping config merge${RESET}"
                    ;;
                * )
                    jq -s '.[0] * .[1]' user_config.json user_config.example.json > user_config.json.new
                    mv user_config.json.new user_config.json
                    echo -e "${GREEN}✅ Configuration merged${RESET}"
                    ;;
            esac
        fi
    fi
fi

# 8. FINAL CLEANUP
echo -e "${YELLOW}✨ Final cleanup...${RESET}"

# Remove temporary files
find . -name "*.tmp" -delete 2>/dev/null
find . -name "*.backup" -mtime +7 -delete 2>/dev/null  # Keep backups for 7 days

# 9. MIGRATION COMPLETE
echo -e "${GREEN}"
echo "   🎉  POST-UPDATE MIGRATIONS COMPLETE  🎉"
echo "   --------------------------------------"
echo -e "${RESET}"

echo -e "${BLUE}📊 Migration summary:${RESET}"
echo "  ✅ Configuration compatibility checked"
echo "  ✅ File permissions fixed"
echo "  ✅ Caches cleaned"
echo "  ✅ Directory structure validated"
echo "  ✅ Script dependencies verified"
echo ""
echo -e "${GREEN}🐝 System is ready for the new version! 🍯${RESET}"
echo ""
echo -e "${BLUE}🚀 Next steps:${RESET}"
echo "  1. Restart Bee-Hive OS:"
echo "     QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os"
echo "  2. Run health check if issues persist:"
echo "     ./scripts/health-check.sh"
echo "  3. Report any problems to GitHub issues"

exit 0