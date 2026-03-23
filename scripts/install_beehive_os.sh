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

# 5. Installing SDDM Theme (Optional, requires sudo)
echo -e "${AMBER}🖼️ Installing SDDM login theme...${RESET}"
# SDDM theme is usually in a separate folder ~/beehive-sddm
if [ -d "$HOME/beehive-sddm" ]; then
    sudo rm -rf /usr/share/sddm/themes/beehive
    sudo cp -r "$HOME/beehive-sddm" /usr/share/sddm/themes/beehive
    echo "✅ SDDM theme installed from ~/beehive-sddm."
else
    echo "ℹ️ Folder ~/beehive-sddm not found. Login theme skipped."
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
