#!/bin/bash

# --- 🐝 BEE-HIVE OS HEALTH CHECK v1.0 🐝 ---
# Comprehensive system diagnostic and troubleshooting
# Run this when things don't work as expected
# -----------------------------------------------

# Terminal colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}"
echo "   🐝  BEE-HIVE OS : SYSTEM HEALTH CHECK  🐝"
echo "   --------------------------------------------"
echo -e "${RESET}"

# 0. Detect environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/..")"

if [ ! -d "$REPO_ROOT" ]; then
    echo -e "${RED}❌ Cannot determine repository root${RESET}"
    exit 1
fi

cd "$REPO_ROOT"
echo -e "${BLUE}📍 Checking: $REPO_ROOT${RESET}"

# Initialize results
PASS=0
WARN=0
FAIL=0

# Function to print result
print_result() {
    local status=$1
    local message=$2
    
    case $status in
        "PASS")
            echo -e "${GREEN}✅ $message${RESET}"
            ((PASS++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${RESET}"
            ((WARN++))
            ;;
        "FAIL")
            echo -e "${RED}❌ $message${RESET}"
            ((FAIL++))
            ;;
    esac
}

# 1. SYSTEM DEPENDENCIES
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}1. SYSTEM DEPENDENCIES${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Required dependencies
REQUIRED_DEPS=("quickshell" "python3" "git")
OPTIONAL_DEPS=("hyprctl" "kitty" "fish" "fastfetch" "swww" "cava")

for dep in "${REQUIRED_DEPS[@]}"; do
    if command -v $dep &> /dev/null; then
        version=$($dep --version 2>/dev/null | head -1)
        print_result "PASS" "$dep: $version"
    else
        print_result "FAIL" "$dep: NOT FOUND (required)"
    fi
done

for dep in "${OPTIONAL_DEPS[@]}"; do
    if command -v $dep &> /dev/null; then
        version=$($dep --version 2>/dev/null | head -1)
        print_result "PASS" "$dep: $version (optional)"
    else
        print_result "WARN" "$dep: NOT FOUND (optional)"
    fi
done

# 2. FILE STRUCTURE
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}2. FILE STRUCTURE${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Critical QML files
CRITICAL_FILES=(
    "shell.qml"
    "modules/BeeBar.qml"
    "modules/BeeConfig.qml"
    "modules/BeeTheme.qml"
    "user_config.json"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || echo "?")
        print_result "PASS" "$file ($size bytes)"
    else
        print_result "FAIL" "$file: MISSING"
    fi
done

# Script files
SCRIPT_FILES=("scripts/update_icons.py" "scripts/get_window_icon.py")

for file in "${SCRIPT_FILES[@]}"; do
    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            print_result "PASS" "$file (executable)"
        else
            print_result "WARN" "$file (not executable)"
        fi
    else
        print_result "WARN" "$file: MISSING (optional)"
    fi
done

# 3. PERMISSIONS
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}3. PERMISSIONS${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Check write permissions
if [ -w "$REPO_ROOT" ]; then
    print_result "PASS" "Repository is writable"
else
    print_result "FAIL" "Repository is NOT writable"
fi

# Check script permissions
for script in scripts/*.sh scripts/*.py 2>/dev/null; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        print_result "WARN" "$script: not executable"
    fi
done

# 4. CONFIGURATION
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}4. CONFIGURATION${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Check user_config.json
if [ -f "user_config.json" ]; then
    if command -v jq &> /dev/null; then
        # Check if valid JSON
        if jq empty user_config.json 2>/dev/null; then
            print_result "PASS" "user_config.json: valid JSON"
            
            # Check for required fields
            REQUIRED_FIELDS=("window_icons" "theme")
            for field in "${REQUIRED_FIELDS[@]}"; do
                if jq -e ".${field}" user_config.json >/dev/null 2>&1; then
                    print_result "PASS" "  - $field: present"
                else
                    print_result "WARN" "  - $field: MISSING"
                fi
            done
        else
            print_result "FAIL" "user_config.json: INVALID JSON"
        fi
    else
        print_result "WARN" "user_config.json: exists (jq not available for validation)"
    fi
else
    print_result "FAIL" "user_config.json: MISSING"
fi

# 5. RUNTIME CHECKS
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}5. RUNTIME CHECKS${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Test Quickshell
if command -v quickshell &> /dev/null; then
    if quickshell --help &>/dev/null; then
        print_result "PASS" "Quickshell: functional"
    else
        print_result "FAIL" "Quickshell: not functional"
    fi
fi

# Test Python scripts
if command -v python3 &> /dev/null; then
    if python3 --version &>/dev/null; then
        print_result "PASS" "Python3: functional"
        
        # Test individual scripts
        if [ -f "scripts/update_icons.py" ]; then
            if python3 scripts/update_icons.py --test &>/dev/null; then
                print_result "PASS" "update_icons.py: functional"
            else
                print_result "WARN" "update_icons.py: may have issues"
            fi
        fi
    fi
fi

# 6. HYPRLAND INTEGRATION (if available)
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}6. HYPRLAND INTEGRATION${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if command -v hyprctl &> /dev/null; then
    print_result "PASS" "Hyprland: detected"
    
    # Check if Bee-Hive config is loaded
    if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
        if grep -q "beehive_hypr.conf" "$HOME/.config/hypr/hyprland.conf"; then
            print_result "PASS" "Hyprland config: Bee-Hive integrated"
        else
            print_result "WARN" "Hyprland config: Bee-Hive NOT integrated"
        fi
    fi
    
    # Test window detection
    if [ -f "scripts/get_window_icon.py" ]; then
        if python3 scripts/get_window_icon.py &>/dev/null; then
            print_result "PASS" "Window detection: functional"
        else
            print_result "WARN" "Window detection: may have issues"
        fi
    fi
else
    print_result "WARN" "Hyprland: not detected (optional)"
fi

# 7. SUMMARY
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}7. HEALTH SUMMARY${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

TOTAL=$((PASS + WARN + FAIL))

echo -e "${GREEN}✅ Pass: $PASS${RESET}"
echo -e "${YELLOW}⚠️  Warn: $WARN${RESET}"
echo -e "${RED}❌ Fail: $FAIL${RESET}"
echo -e "${BLUE}📊 Total: $TOTAL checks${RESET}"

# Overall status
if [ $FAIL -eq 0 ]; then
    if [ $WARN -eq 0 ]; then
        echo -e "${GREEN}🎉 EXCELLENT: System is fully operational!${RESET}"
        echo -e "${GREEN}🐝 Ready to launch: QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os${RESET}"
        exit 0
    else
        echo -e "${YELLOW}📋 GOOD: System operational with some warnings${RESET}"
        echo -e "${YELLOW}💡 Recommendations: Review warnings above${RESET}"
        exit 1
    fi
else
    echo -e "${RED}🚨 ATTENTION: System has critical issues${RESET}"
    echo -e "${RED}🔧 Action required: Fix failures before using Bee-Hive OS${RESET}"
    
    # Provide troubleshooting tips
    echo ""
    echo -e "${CYAN}🛠️  TROUBLESHOOTING TIPS:${RESET}"
    
    if [ ! -f "user_config.json" ]; then
        echo "  • Run: cp user_config.example.json user_config.json"
    fi
    
    if ! command -v quickshell &> /dev/null; then
        echo "  • Install Quickshell: sudo pacman -S quickshell"
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo "  • Install Python: sudo pacman -S python"
    fi
    
    exit 2
fi