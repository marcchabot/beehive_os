#!/bin/bash

# --- 🐝 BEE-HIVE OS INSTALLER v1.3.x 🐝 ---
# Designed for: CachyOS + Hyprland (Arch Linux)
# Author: Maya the Bee (for Marc & Community)
# -----------------------------------------------

# Terminal colors
YELLOW='\033[1;33m'
AMBER='\033[0;33m'
RESET='\033[0m'

echo -e "${YELLOW}"
echo "   🐝  BEE-HIVE OS : HIVE INSTALLATION  🐝"
echo "   --------------------------------------------"
echo -e "${RESET}"

# 0. Detect Git repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"

if [ -z "$REPO_ROOT" ]; then
    echo "❌ Error: This script must be run from within the beehive_os Git repository."
    echo "Please run: git clone https://github.com/marcchabot/beehive_os.git && cd beehive_os"
    exit 1
fi

echo -e "${AMBER}📍 Repository root detected: $REPO_ROOT${RESET}"
cd "$REPO_ROOT"

# 1. Dependency Check
echo -e "${AMBER}🔍 Checking dependencies...${RESET}"
DEPENDENCIES=("quickshell" "kitty" "fish" "fastfetch" "papirus-icon-theme" "swww" "git" "python" "python-dbus" "cava")
MISSING=()

for pkg in "${DEPENDENCIES[@]}"; do
    if ! pacman -Qs $pkg > /dev/null; then
        MISSING+=($pkg)
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "📦 Missing packages detected: ${MISSING[@]}"
    echo "Installing via pacman..."
    sudo pacman -S --noconfirm "${MISSING[@]}"
else
    echo "✅ All dependencies are met."
fi

# 2. Canonical Directory Setup
echo -e "${AMBER}📂 Preparing directory ~/beehive_os...${RESET}"
if [ -d "$HOME/beehive_os" ]; then
    echo "⚠️ Directory ~/beehive_os already exists. Creating a backup..."
    mv "$HOME/beehive_os" "$HOME/beehive_os_bak_$(date +%Y%m%d_%H%M%S)"
fi

# Copying files (ignoring local personal configs)
cp -r . "$HOME/beehive_os"
chmod -R 755 "$HOME/beehive_os"

# Initializing config if it doesn't exist
if [ ! -f "$HOME/beehive_os/user_config.json" ]; then
    cp "$HOME/beehive_os/user_config.example.json" "$HOME/beehive_os/user_config.json"
    echo "✅ Initial configuration created from template."
fi

# 3. Backing up existing configurations
echo -e "${AMBER}💾 Backing up your current configurations...${RESET}"
mkdir -p "$HOME/.config/beehive_backups"
[ -f "$HOME/.config/hypr/hyprland.conf" ] && cp "$HOME/.config/hypr/hyprland.conf" "$HOME/.config/beehive_backups/hyprland.conf.bak"
[ -f "$HOME/.config/kitty/kitty.conf" ] && cp "$HOME/.config/kitty/kitty.conf" "$HOME/.config/beehive_backups/kitty.conf.bak"
[ -f "$HOME/.config/fish/config.fish" ] && cp "$HOME/.config/fish/config.fish" "$HOME/.config/beehive_backups/config.fish.bak"

# 3.5. Privacy cleanup (remove personal data)
echo -e "${AMBER}🔒 Cleaning up personal data...${RESET}"
if [ -f "$HOME/beehive_os/data/events.json" ]; then
    rm "$HOME/beehive_os/data/events.json"
    echo "✅ Removed personal calendar events (data/events.json)."
fi
if [ -f "$HOME/beehive_os/user_config.json" ]; then
    rm "$HOME/beehive_os/user_config.json"
    echo "✅ Removed personal configuration (user_config.json)."
fi

# 4. Injecting Bee-Hive configurations
echo -e "${AMBER}💉 Injecting hive venom (configs)...${RESET}"

# Hyprland
mkdir -p "$HOME/.config/hypr"
if ! grep -q "beehive_hypr.conf" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
    echo -e "\n# --- BEE-HIVE OS CONFIG ---\nsource = ~/beehive_os/config/beehive_hypr.conf" >> "$HOME/.config/hypr/hyprland.conf"
    echo "✅ Hyprland configured."
fi

# Kitty
mkdir -p "$HOME/.config/kitty"
if ! grep -q "beehive_kitty.conf" "$HOME/.config/kitty/kitty.conf" 2>/dev/null; then
    echo -e "\n# --- BEE-HIVE OS THEME ---\ninclude ~/beehive_os/config/beehive_kitty.conf" >> "$HOME/.config/kitty/kitty.conf"
    echo "✅ Kitty configured."
fi

# Fish
mkdir -p "$HOME/.config/fish"
if ! grep -q "beehive_fish.config" "$HOME/.config/fish/config.fish" 2>/dev/null; then
    echo -e "\n# --- BEE-HIVE OS PROMPT ---\nsource ~/beehive_os/config/beehive_fish.config" >> "$HOME/.config/fish/config.fish"
    echo "✅ Fish configured."
fi

# 5. SDDM Login Theme (Optional)
echo -e "${YELLOW}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🖼️  BEE-HIVE SDDM THEME (Login Screen)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
echo "This theme transforms your login screen into a sleek"
echo "Nexus-style interface (honey yellow & black) that"
echo "matches Bee-Hive OS perfectly."
echo ""
echo "📦 Requirements:"
echo "   • SDDM display manager installed"
echo "   • sudo privileges (installs to /usr/share/sddm/themes/)"
echo ""
echo "✨ Result: A cohesive Bee-Hive experience from boot to desktop!"
echo ""

INSTALL_SDDM=false

# Check if SDDM is installed
if ! pacman -Qs sddm > /dev/null 2>&1; then
    echo "⚠️  SDDM is not installed on your system."
    echo "   The login theme requires SDDM as your display manager."
    echo ""
    read -p "🐝 Install SDDM display manager? [Y/n]: " install_sddm_pkg
    case "$install_sddm_pkg" in
        [Yy]*|"" )
            echo -e "${AMBER}📦 Installing SDDM...${RESET}"
            sudo pacman -S --noconfirm sddm
            echo "✅ SDDM installed."
            ;;
        [Nn]* )
            echo "ℹ️ Skipping SDDM theme (requires SDDM)."
            INSTALL_SDDM="skip"
            ;;
    esac
fi

# Proceed with theme installation if not skipped
if [ "$INSTALL_SDDM" != "skip" ]; then
    # Check if beehive-sddm folder exists
    if [ ! -d "$HOME/beehive-sddm" ]; then
        echo ""
        echo "ℹ️  Bee-Hive SDDM theme not found locally."
        read -p "🐝 Clone beehive-sddm from GitHub? [Y/n]: " clone_choice
        case "$clone_choice" in
            [Yy]*|"" )
                echo -e "${AMBER}🔧 Cloning beehive-sddm...${RESET}"
                git clone https://github.com/marcchabot/beehive-sddm.git "$HOME/beehive-sddm"
                echo "✅ Clone complete!"
                ;;
            [Nn]* )
                echo "ℹ️ Skipping SDDM theme installation."
                INSTALL_SDDM="skip"
                ;;
        esac
    fi

    # Ask for installation if we have the theme
    if [ "$INSTALL_SDDM" != "skip" ] && [ -d "$HOME/beehive-sddm" ]; then
        echo ""
        read -p "🐝 Install the Bee-Hive login theme? [Y/n]: " choice
        case "$choice" in
            [Yy]*|"" ) INSTALL_SDDM=true;;
            [Nn]* ) INSTALL_SDDM=false; echo "ℹ️ Skipping SDDM theme installation.";;
        esac
    fi
fi

# Install the theme
if [ "$INSTALL_SDDM" = true ]; then
    echo -e "${AMBER}🔧 Installing SDDM theme...${RESET}"
    sudo rm -rf /usr/share/sddm/themes/beehive
    sudo cp -r "$HOME/beehive-sddm" /usr/share/sddm/themes/beehive
    
    # Check if beehive is set as current theme
    if [ -f "/etc/sddm.conf" ]; then
        if ! grep -q "Theme=beehive" /etc/sddm.conf 2>/dev/null; then
            echo ""
            echo "💡 Tip: To activate the theme, add this to /etc/sddm.conf:"
            echo "   [Theme]"
            echo "   Current=beehive"
        fi
    else
        echo ""
        echo "💡 Tip: Create /etc/sddm.conf with:"
        echo "   [Theme]"
        echo "   Current=beehive"
    fi
    
    echo "✅ SDDM theme installed! Your login screen is now hive-ready."
fi

# 6. Finalization
echo -e "${YELLOW}"
echo "   ✨  INSTALLATION COMPLETED !  ✨"
echo "   ----------------------------"
echo -e "${RESET}"
echo "To activate the hive without restarting:"
echo "1. Reload Hyprland (SUPER + C)"
echo "2. Launch manually: QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os"
echo ""
echo "Welcome to the hive! 🐝🍯"
