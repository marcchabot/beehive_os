# ═══════════════════════════════════════════════════════════════
# Bee-Hive OS — Oh My Zsh Theme 🐝🍯
# v1.1.0 : Nectar Prompt — Custom Honey/Black
# ═══════════════════════════════════════════════════════════════

# Colors
BEE_YELLOW="%F{#FFB81C}"
BEE_WHITE="%F{#FFFFFF}"
BEE_GREY="%F{#AAAAAA}"
BEE_RESET="%f"
BEE_BOLD="%B"
BEE_UNBOLD="%b"

# Git integration
ZSH_THEME_GIT_PROMPT_PREFIX="${BEE_YELLOW} (${BEE_RESET}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${BEE_YELLOW})${BEE_RESET}"
ZSH_THEME_GIT_PROMPT_DIRTY="${BEE_YELLOW}*${BEE_RESET}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Prompt
# 🍯 ~/path/to/dir (git-branch*)  ❯
PROMPT='${BEE_YELLOW}${BEE_BOLD}🍯 ${BEE_UNBOLD}${BEE_RESET}${BEE_WHITE}%~${BEE_RESET}$(git_prompt_info) ${BEE_YELLOW}❯${BEE_RESET} '

# Right prompt — heure + abeille
RPROMPT='${BEE_GREY}%T${BEE_RESET} ${BEE_YELLOW}🐝${BEE_RESET}'
