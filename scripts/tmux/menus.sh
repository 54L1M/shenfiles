#!/bin/bash

# tmux-menus.sh - Centralized handler for Tmux popups and menus
# Usage: ./menus.sh [command]

# --- Dynamic Path Resolution ---
# 1. Get the directory where this script is located (scripts/tmux)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 2. Go up two levels to find the repository root (shenfiles)
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CMD="$1"

# Common styling colors (Gruvbox Material)
THM_BG="#1d2021"
THM_FG="#ebdbb2"
THM_PEACH="#e78a4e"
THM_SURFACE="#292929"
THM_OVERLAY="#595959"

case "$CMD" in
  switch_session)
    # Filter out current session and use fzf to switch
    CURRENT_SESSION=$(tmux display-message -p '#S')
    tmux list-sessions | sed -E 's/:.*$//' | grep -v "^${CURRENT_SESSION}$" | \
    fzf --reverse --ansi --header 'C-x: Kill Session' \
      --bind "ctrl-x:execute(tmux kill-session -t {})+reload(tmux list-sessions | sed -E 's/:.*$//' | grep -v \"^$(tmux display-message -p '#S')\$\")" \
      --preview "tmux list-windows -t {} -F '#{window_index}: #{window_name}#{?window_active, (active),} ;;;    └─ #{pane_current_command}  #{b:pane_current_path}' | awk -F ';;;' '{print \$1 \"\n\" \$2}'" \
      --color="bg+:$THM_SURFACE,bg:$THM_BG,spinner:#7daea3,hl:#ea6962,fg:$THM_FG,header:#7daea3,info:#d8a657,pointer:$THM_PEACH,marker:$THM_PEACH,fg+:$THM_FG,prompt:#d8a657,hl+:#ea6962" \
    | xargs tmux switch-client -t
    ;;

  new_session)
    bash -i -c "read -p \"Session name: \" name; if [ -n \"\$name\" ]; then tmux new-session -d -s \"\$name\" && tmux switch-client -t \"\$name\"; fi"
    ;;

  p4m_session)
    # Select and launch a p4m session
    yq eval 'keys | .[]' "$HOME/.config/p4/p4m.yaml" | \
    fzf --reverse --header='Select a session to load' \
      --color="bg+:$THM_SURFACE,bg:$THM_BG,spinner:#7daea3,hl:#ea6962,fg:$THM_FG,header:#7daea3,info:#d8a657,pointer:$THM_PEACH,marker:$THM_PEACH,fg+:$THM_FG,prompt:#d8a657,hl+:#ea6962" \
    | xargs -I {} p4m {}
    ;;

  dotfiles_menu)
    # Uses the dynamic DOTFILES_DIR
    tmux display-menu -T "#[align=centre,fg=$THM_PEACH]    Dotfiles    " -x C -y C \
      ".zshrc"      z  "display-popup -d \"$HOME/.config/zsh/\" -E 'nvim $HOME/.config/zsh/.zshrc'" \
      "nix"         n  "display-popup -d \"$DOTFILES_DIR/nix/\" -E 'nvim $DOTFILES_DIR/nix/'" \
      "scripts"     s  "display-popup -d \"$DOTFILES_DIR/scripts/\" -E 'nvim $DOTFILES_DIR/scripts/'" \
      "tmux config" t  "display-popup -d \"$DOTFILES_DIR/tmux/\" -E 'nvim $DOTFILES_DIR/tmux/tmux.conf'" \
      "exit"        q  ""
    ;;

  *)
    echo "Usage: $0 {switch_session|new_session|p4m_session|dotfiles_menu}"
    exit 1
    ;;
esac
