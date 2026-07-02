#!/bin/bash

# tmux-menus.sh - Centralized handler for Tmux popups and menus
# Usage: ./menus.sh [command]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

SELF="$SCRIPT_DIR/menus.sh"
P4M_CONFIG="$HOME/.config/p4/p4m.yaml"

CMD="$1"

# fzf --color string using oshen palette
FZF_COLORS="bg+:${P4_OSHEN_MANTLE},bg:${P4_OSHEN_BASE},spinner:${P4_OSHEN_TEAL},hl:${P4_OSHEN_RED},fg:${P4_OSHEN_TEXT},header:${P4_OSHEN_TEAL},info:${P4_OSHEN_AMBER},pointer:${P4_OSHEN_PEACH},marker:${P4_OSHEN_PEACH},fg+:${P4_OSHEN_TEXT},prompt:${P4_OSHEN_AMBER},hl+:${P4_OSHEN_RED}"

case "$CMD" in
  # ---------------------------------------------------------------------------
  # manager — the unified hub. One popup, choose what to do.
  # ---------------------------------------------------------------------------
  manager)
    tmux display-menu -T "#[align=centre,fg=${P4_OSHEN_PEACH}]  p4 Manager  " -x C -y C \
      "Session Manager"  s  "display-popup -E -w 60% -h 60% -T '#[align=centre,fg=${P4_OSHEN_PEACH}] Sessions ' 'bash $SELF session_manager'" \
      "" \
      "Start SQL Proxy"  p  "display-popup -E -w 40% -h 40% -T '#[align=centre,fg=${P4_OSHEN_PEACH}] Start Proxy ' 'bash $BIN_DIR/p4p.sh start'" \
      "Stop SQL Proxy"   x  "display-popup -E -w 40% -h 40% -T '#[align=centre,fg=${P4_OSHEN_PEACH}] Stop Proxy ' 'bash $BIN_DIR/p4p.sh stop'" \
      "K8s Context"      k  "display-popup -E -w 50% -h 50% -T '#[align=centre,fg=${P4_OSHEN_PEACH}] K8s Context ' 'bash $BIN_DIR/p4k.sh ctx'" \
      "GCloud Project"   g  "display-popup -E -w 40% -h 40% -T '#[align=centre,fg=${P4_OSHEN_PEACH}] GCloud Project ' 'bash $BIN_DIR/p4g.sh proj'" \
      "" \
      "Logs"             l  "display-popup -E -w 70% -h 70% -T '#[align=centre,fg=${P4_OSHEN_PEACH}] Logs ' 'bash $BIN_DIR/p4l.sh'" \
      "Dotfiles"         d  "run-shell 'bash $SELF dotfiles_menu'" \
      "" \
      "Exit"             q  ""
    ;;

  # ---------------------------------------------------------------------------
  # session_manager — switch, launch (from p4m layout), kill, or create.
  #   enter : open (switch if running, else create from p4m layout)
  #   C-x   : kill the highlighted session
  #   C-n   : create a new empty session (prompts for name)
  # ---------------------------------------------------------------------------
  session_manager)
    selection=$(bash "$SELF" session_list | \
      fzf --reverse --ansi \
        --delimiter='\t' --with-nth=2 \
        --header 'enter: open   C-x: kill   C-n: new' \
        --preview "bash $SELF session_preview {3}" \
        --preview-window 'right:55%' \
        --color="$FZF_COLORS" \
        --bind "ctrl-x:execute-silent(tmux kill-session -t {3})+reload(bash $SELF session_list)" \
        --bind "ctrl-n:execute(bash $SELF new_session)+abort")

    [ -z "$selection" ] && exit 0

    kind=$(printf '%s' "$selection" | cut -f1)
    name=$(printf '%s' "$selection" | cut -f3)
    [ -z "$name" ] && exit 0

    case "$kind" in
      run)
        tmux switch-client -t "$name"
        ;;
      new)
        # p4m creates the layout and switches to it
        bash "$BIN_DIR/p4m.sh" "$name"
        ;;
    esac
    ;;

  # ---------------------------------------------------------------------------
  # session_list — emit combined entries (internal; consumed by fzf).
  #   columns (tab-delimited): kind <TAB> display <TAB> name
  #   kind = run  -> a live tmux session
  #   kind = new  -> a p4m layout that is not currently running
  # ---------------------------------------------------------------------------
  session_list)
    current=$(tmux display-message -p '#S' 2>/dev/null)
    active=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

    # Live sessions (skip the current one — nothing to switch to)
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      [ "$name" = "$current" ] && continue
      printf 'run\t%b● %s%b\t%s\n' "$P4_GREEN" "$name" "$P4_RESET" "$name"
    done <<< "$active"

    # p4m layouts that are not already running
    if [ -f "$P4M_CONFIG" ]; then
      while IFS= read -r name; do
        [ -z "$name" ] && continue
        grep -qxF "$name" <<< "$active" && continue
        printf 'new\t%b○ %s%b\t%s\n' "$P4_MAGENTA" "$name" "$P4_RESET" "$name"
      done < <(yq eval 'keys | .[]' "$P4M_CONFIG" 2>/dev/null | grep -v '^x-')
    fi
    ;;

  # ---------------------------------------------------------------------------
  # session_preview <name> — fzf preview pane (internal).
  # ---------------------------------------------------------------------------
  session_preview)
    name="$2"
    [ -z "$name" ] && exit 0

    if tmux has-session -t "$name" 2>/dev/null; then
      echo "live session"
      echo
      # Highlight the active window with a green ▶ marker
      win_fmt=$'#{window_index}\t#{window_name}\t#{window_active}\t#{window_panes}'
      while IFS=$'\t' read -r idx wname wactive wpanes; do
        [ -z "$idx" ] && continue
        panes=""
        [ "$wpanes" -gt 1 ] 2>/dev/null && panes=" [${wpanes} panes]"
        if [ "$wactive" = "1" ]; then
          printf '%b▶ %s: %s%s%b\n' "$P4_GREEN" "$idx" "$wname" "$panes" "$P4_RESET"
        else
          printf '  %s: %s%s\n' "$idx" "$wname" "$panes"
        fi
      done < <(tmux list-windows -t "$name" -F "$win_fmt")
    elif [ -f "$P4M_CONFIG" ]; then
      local_path=$(yq eval "explode(.) | .${name}.path // \"\"" "$P4M_CONFIG" 2>/dev/null)
      echo "p4m layout"
      echo
      echo "path: ${local_path}"
      echo "windows:"
      yq eval "explode(.) | .${name}.windows[].name // \"\"" "$P4M_CONFIG" 2>/dev/null | sed 's/^/  - /'
    fi
    ;;

  # ---------------------------------------------------------------------------
  # new_session — create an empty, ad-hoc session (prompts for a name).
  # ---------------------------------------------------------------------------
  new_session)
    bash -i -c "read -p \"Session name: \" name; if [ -n \"\$name\" ]; then tmux new-session -d -s \"\$name\" && tmux switch-client -t \"\$name\"; fi"
    ;;

  # ---------------------------------------------------------------------------
  # dotfiles_menu — quick-edit dotfiles.
  # ---------------------------------------------------------------------------
  dotfiles_menu)
    tmux display-menu -T "#[align=centre,fg=${P4_OSHEN_PEACH}]    Dotfiles    " -x C -y C \
      ".zshrc"      z  "display-popup -d \"$HOME/.config/zsh/\" -E 'nvim $HOME/.config/zsh/.zshrc'" \
      "nix"         n  "display-popup -d \"$DOTFILES_DIR/nix/\" -E 'nvim $DOTFILES_DIR/nix/'" \
      "scripts"     s  "display-popup -d \"$DOTFILES_DIR/scripts/\" -E 'nvim $DOTFILES_DIR/scripts/'" \
      "tmux config" t  "display-popup -d \"$DOTFILES_DIR/tmux/\" -E 'nvim $DOTFILES_DIR/tmux/tmux.conf'" \
      "exit"        q  ""
    ;;

  *)
    echo "Usage: $0 {manager|session_manager|session_list|session_preview|new_session|dotfiles_menu}"
    exit 1
    ;;
esac
