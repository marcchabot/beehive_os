#!/bin/bash

# --- 🐝 BEE-HIVE OS UPDATE SCRIPT v1.0 🐝 ---
# Safe post-git-pull maintenance and compatibility updates
# Run this AFTER every `git pull` to ensure system integrity
# -----------------------------------------------

# Terminal colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}"
echo "   🐝  BEE-HIVE OS : SAFE UPDATE SYSTEM  🐝"
echo "   --------------------------------------------"
echo -e "${RESET}"

# 0. Detect Git repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"

if [ -z "$REPO_ROOT" ]; then
    echo -e "${RED}❌ Error: This script must be run from within the beehive_os Git repository.${RESET}"
    exit 1
fi

echo -e "${BLUE}📍 Repository: $REPO_ROOT${RESET}"
cd "$REPO_ROOT"

# 1. Backup current configuration
echo -e "${YELLOW}🔒 Creating backup of current configuration...${RESET}"
BACKUP_DIR="$HOME/.beehive_backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup critical files
BACKUP_FILES=(
    "user_config.json"
    "data/events.json"
    "data/events_live.json"
    ".cache/icon_cache.json"
)

for file in "${BACKUP_FILES[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/"
        echo "  📋 Backed up: $file"
    fi
done

echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${RESET}"

# 2. Check if git pull was performed
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Not a git repository. Please clone first with git clone.${RESET}"
    exit 1
fi

LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git ls-remote origin HEAD | cut -f1)

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo -e "${YELLOW}⚠️  No new commits detected. Running maintenance only.${RESET}"
else
    echo -e "${GREEN}📥 New commits available. Running compatibility updates...${RESET}"
fi

# 3. Permission fixes
echo -e "${YELLOW}🔧 Fixing permissions...${RESET}"
chmod -R 755 "$REPO_ROOT"
chmod +x scripts/*.py scripts/*.sh 2>/dev/null

# 4. Run compatibility migrations
echo -e "${YELLOW}🔄 Running compatibility migrations...${RESET}"

# 4.1 Check for new required dependencies
echo -e "${BLUE}📦 Checking for new dependencies...${RESET}"
NEW_DEPS=()

# Check for Python scripts
if [ -f "scripts/update_icons.py" ] && ! command -v python3 &> /dev/null; then
    NEW_DEPS+=("python")
fi

# Check for hyprctl usage
if grep -r "hyprctl" scripts/ 2>/dev/null && ! command -v hyprctl &> /dev/null; then
    NEW_DEPS+=("hyprland")
fi

if [ ${#NEW_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  New dependencies detected: ${NEW_DEPS[@]}${RESET}"
    read -p "Install missing dependencies? [Y/n]: " choice
    case "$choice" in
        [Nn]* )
            echo "Skipping dependency installation."
            ;;
        * )
            echo "Installing dependencies..."
            sudo pacman -S --noconfirm "${NEW_DEPS[@]}"
            ;;
    esac
fi

# 4.2 Update icon mappings if script exists
if [ -f "scripts/update_icons.py" ]; then
    echo -e "${BLUE}🎨 Updating desktop icon mappings...${RESET}"
    python3 scripts/update_icons.py --update-only 2>/dev/null || echo "Icon update skipped or failed"
fi

# 4.3 Check for configuration schema changes
if [ -f "user_config.example.json" ] && [ -f "user_config.json" ]; then
    echo -e "${BLUE}📋 Checking configuration schema...${RESET}"
    
    # Simple diff check for new fields
    EXAMPLE_KEYS=$(jq -r 'keys[]' user_config.example.json 2>/dev/null | sort)
    USER_KEYS=$(jq -r 'keys[]' user_config.json 2>/dev/null | sort)
    
    if command -v jq &> /dev/null; then
        NEW_KEYS=$(comm -13 <(echo "$USER_KEYS") <(echo "$EXAMPLE_KEYS"))
        
        if [ ! -z "$NEW_KEYS" ]; then
            echo -e "${YELLOW}⚠️  New configuration fields detected:${RESET}"
            echo "$NEW_KEYS" | while read key; do
                echo "  ➕ $key"
            done
            
            read -p "Merge new fields from example config? [Y/n]: " choice
            case "$choice" in
                [Nn]* )
                    echo "Skipping config merge."
                    ;;
                * )
                    # Create merged config
                    jq -s '.[0] * .[1]' user_config.json user_config.example.json > user_config.json.new
                    mv user_config.json.new user_config.json
                    echo "✅ Configuration merged."
                    ;;
            esac
        fi
    fi
fi

# 5. Health check
echo -e "${YELLOW}🏥 Running health check...${RESET}"

HEALTH_OK=true

# Check Quickshell availability
if ! command -v quickshell &> /dev/null; then
    echo -e "${RED}❌ Quickshell not found${RESET}"
    HEALTH_OK=false
else
    echo -e "${GREEN}✅ Quickshell available${RESET}"
fi

# Check Python availability
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 not found${RESET}"
    HEALTH_OK=false
else
    echo -e "${GREEN}✅ Python3 available${RESET}"
fi

# Check critical files
CRITICAL_FILES=(
    "shell.qml"
    "modules/BeeBar.qml"
    "modules/BeeConfig.qml"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Missing critical file: $file${RESET}"
        HEALTH_OK=false
    else
        echo -e "${GREEN}✅ File exists: $file${RESET}"
    fi
done

# 6. Clear caches if needed
echo -e "${YELLOW}🧹 Cleaning caches...${RESET}"
find "$REPO_ROOT" -name "*.pyc" -delete
find "$REPO_ROOT" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# 7. Final report
echo -e "${BLUE}"
echo "   📊  UPDATE COMPLETION REPORT  📊"
echo "   -------------------------------"
echo -e "${RESET}"

if [ "$HEALTH_OK" = true ]; then
    echo -e "${GREEN}✅ System health: GOOD${RESET}"
    echo -e "${GREEN}✅ Update completed successfully${RESET}"
else
    echo -e "${YELLOW}⚠️  System health: WARNINGS${RESET}"
    echo -e "${YELLOW}⚠️  Some checks failed. Manual intervention may be needed.${RESET}"
fi

echo ""
echo -e "${BLUE}📁 Backup location:${RESET} $BACKUP_DIR"
echo -e "${BLUE}🔄 Next steps:${RESET}"
echo "   1. Review any warnings above"
echo "   2. Restart Bee-Hive OS:"
echo "      QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os"
echo "   3. Test new features"
echo ""
echo -e "${GREEN}🐝 Hive updated and ready! 🍯${RESET}"

# Exit with appropriate code
if [ "$HEALTH_OK" = true ]; then
    exit 0
else
    exit 1
fi