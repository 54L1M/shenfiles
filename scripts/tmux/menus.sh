#!/bin/bash

# tmux-menus.sh - Centralized handler for Tmux popups and menus
# Usage: ./menus.sh [command]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

CMD="$1"

# fzf --color string using oshen palette
FZF_COLORS="bg+:${P4_OSHEN_MANTLE},bg:${P4_OSHEN_BASE},spinner:${P4_OSHEN_TEAL},hl:${P4_OSHEN_RED},fg:${P4_OSHEN_TEXT},header:${P4_OSHEN_TEAL},info:${P4_OSHEN_AMBER},pointer:${P4_OSHEN_PEACH},marker:${P4_OSHEN_PEACH},fg+:${P4_OSHEN_TEXT},prompt:${P4_OSHEN_AMBER},hl+:${P4_OSHEN_RED}"

case "$CMD" in
  switch_session)
    CURRENT_SESSION=$(tmux display-message -p '#S')

    tmux list-sessions -F "#{session_name}: #{session_windows} windows" | \
    grep -v "^${CURRENT_SESSION}:" | \
    fzf --reverse --ansi --header 'C-x: Kill Session' \
      --delimiter ':' \
      --bind "ctrl-x:execute(tmux kill-session -t {1})+reload(tmux list-sessions -F \"#{session_name}: #{session_windows} windows\" | grep -v \"^${CURRENT_SESSION}:\")" \
      --preview "tmux list-windows -t {1} -F '#{window_index}: #{window_name}#{?window_active, (active),}#{?#{>:#{window_panes},1}, [#{window_panes} panes],} ;;;    └─ #{b:pane_current_path}#{?@p4e_env,  •  #{@p4e_env},}' | awk -F ';;;' '{gsub(/•.*/, \"\\x1b[38;5;215m&\\x1b[0m\", \$2); print \$1 \"\\n\" \$2}'" \
      --color="$FZF_COLORS" \
    | awk -F':' '{print $1}' | xargs tmux switch-client -t
    ;;

  new_session)
    bash -i -c "read -p \"Session name: \" name; if [ -n \"\$name\" ]; then tmux new-session -d -s \"\$name\" && tmux switch-client -t \"\$name\"; fi"
    ;;

  p4m_session)
    yq eval 'keys | .[]' "$HOME/.config/p4/p4m.yaml" | \
    fzf --reverse --header='Select a session to load' \
      --color="$FZF_COLORS" \
    | xargs -I {} p4m {}
    ;;

  dotfiles_menu)
    tmux display-menu -T "#[align=centre,fg=${P4_OSHEN_PEACH}]    Dotfiles    " -x C -y C \
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
