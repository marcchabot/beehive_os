#!/bin/bash

# --- 🐝 INSTALLATEUR BEE-HIVE OS v1.3.x 🐝 ---
# Conçu pour : CachyOS + Hyprland (Arch Linux)
# Auteur : Maya l'abeille (pour Marc & François)
# -----------------------------------------------

# Couleurs pour le terminal
YELLOW='\033[1;33m'
AMBER='\033[0;33m'
RESET='\033[0m'

echo -e "${YELLOW}"
echo "   🐝  BEE-HIVE OS : INSTALLATION DE LA RUCHE  🐝"
echo "   --------------------------------------------"
echo -e "${RESET}"

# 1. Vérification des dépendances
echo -e "${AMBER}🔍 Vérification des dépendances...${RESET}"
DEPENDENCIES=("quickshell" "kitty" "fish" "fastfetch" "papirus-icon-theme" "swww" "git")
MISSING=()

for pkg in "${DEPENDENCIES[@]}"; do
    if ! pacman -Qs $pkg > /dev/null; then
        MISSING+=($pkg)
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "📦 Paquets manquants détectés : ${MISSING[@]}"
    echo "Installation via pacman..."
    sudo pacman -S --noconfirm "${MISSING[@]}"
else
    echo "✅ Toutes les dépendances sont présentes."
fi

# 2. Préparation du dossier canonique
echo -e "${AMBER}📂 Préparation du dossier ~/beehive_os...${RESET}"
if [ -d "$HOME/beehive_os" ]; then
    echo "⚠️ Le dossier ~/beehive_os existe déjà. Création d'un backup..."
    mv "$HOME/beehive_os" "$HOME/beehive_os_bak_$(date +%Y%m%d_%H%M%S)"
fi

# Copie des fichiers (en ignorant les configs personnelles locales)
cp -r . "$HOME/beehive_os"
chmod -R 755 "$HOME/beehive_os"

# Initialisation de la config si elle n'existe pas
if [ ! -f "$HOME/beehive_os/user_config.json" ]; then
    cp "$HOME/beehive_os/user_config.example.json" "$HOME/beehive_os/user_config.json"
    echo "✅ Configuration initiale créée à partir du template."
fi

# 3. Sauvegarde des configurations existantes
echo -e "${AMBER}💾 Sauvegarde de vos configurations actuelles...${RESET}"
mkdir -p "$HOME/.config/beehive_backups"
[ -f "$HOME/.config/hypr/hyprland.conf" ] && cp "$HOME/.config/hypr/hyprland.conf" "$HOME/.config/beehive_backups/hyprland.conf.bak"
[ -f "$HOME/.config/kitty/kitty.conf" ] && cp "$HOME/.config/kitty/kitty.conf" "$HOME/.config/beehive_backups/kitty.conf.bak"
[ -f "$HOME/.config/fish/config.fish" ] && cp "$HOME/.config/fish/config.fish" "$HOME/.config/beehive_backups/config.fish.bak"

# 4. Injection des configurations Bee-Hive
echo -e "${AMBER}💉 Injection du venin de la ruche (configs)...${RESET}"

# Hyprland
mkdir -p "$HOME/.config/hypr"
if ! grep -q "beehive_hypr.conf" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
    echo -e "\n# --- BEE-HIVE OS CONFIG ---\nsource = ~/beehive_os/config/beehive_hypr.conf" >> "$HOME/.config/hypr/hyprland.conf"
    echo "✅ Hyprland configuré."
fi

# Kitty
mkdir -p "$HOME/.config/kitty"
if ! grep -q "beehive_kitty.conf" "$HOME/.config/kitty/kitty.conf" 2>/dev/null; then
    echo -e "\n# --- BEE-HIVE OS THEME ---\ninclude ~/beehive_os/config/beehive_kitty.conf" >> "$HOME/.config/kitty/kitty.conf"
    echo "✅ Kitty configuré."
fi

# Fish
mkdir -p "$HOME/.config/fish"
if ! grep -q "beehive_fish.config" "$HOME/.config/fish/config.fish" 2>/dev/null; then
    echo -e "\n# --- BEE-HIVE OS PROMPT ---\nsource ~/beehive_os/config/beehive_fish.config" >> "$HOME/.config/fish/config.fish"
    echo "✅ Fish configuré."
fi

# 5. Installation du thème SDDM (Optionnel, demande sudo)
echo -e "${AMBER}🖼️ Installation du thème de login SDDM...${RESET}"
# Le thème SDDM est souvent dans un dossier séparé ~/beehive-sddm sur la machine de Marc
if [ -d "$HOME/beehive-sddm" ]; then
    sudo rm -rf /usr/share/sddm/themes/beehive
    sudo cp -r "$HOME/beehive-sddm" /usr/share/sddm/themes/beehive
    echo "✅ Thème SDDM installé à partir de ~/beehive-sddm."
else
    echo "ℹ️ Dossier ~/beehive-sddm non trouvé. Si François veut le thème de login, il devra le copier lui-même."
fi

# 6. Finalisation
echo -e "${YELLOW}"
echo "   ✨  INSTALLATION TERMINÉE !  ✨"
echo "   ----------------------------"
echo -e "${RESET}"
echo "Pour activer la ruche sans redémarrer :"
echo "1. Recharger Hyprland (SUPER + C)"
echo "2. Lancer manuellement : QML_XHR_ALLOW_FILE_READ=1 quickshell -p ~/beehive_os"
echo ""
echo "Bienvenue dans la ruche, François ! 🐝🍯"
