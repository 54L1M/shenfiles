#!/bin/bash

# fzf-git.sh - Run fzf-git.sh pickers (files, branches, hashes, ...) in a
# tmux popup and paste the selection into the pane the popup was opened from.
#
# Sidesteps the CTRL-G chord entirely, so it also works when tmux plugins
# (vim-tmux-navigator) swallow CTRL-H / CTRL-L before zsh can see them.
#
# Usage:
#   fzf-git.sh menu                 # display-menu listing all pickers
#   fzf-git.sh run <kind> <pane_id> # run one picker, send result to pane
#
# <kind> is any _fzf_git_<kind> function in zsh/fzf-git.sh:
#   files branches tags remotes hashes stashes lreflogs worktrees each_ref

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

SELF="$SCRIPT_DIR/fzf-git.sh"
FZF_GIT="$HOME/.config/zsh/fzf-git.sh"

# Oshen palette for fzf. Exported so the redefined _fzf_git_fzf below can
# read it inside the child bash that runs fzf-git.sh.
export FZF_GIT_COLORS="bg+:${P4_OSHEN_MANTLE},bg:${P4_OSHEN_BASE},spinner:${P4_OSHEN_TEAL},hl:${P4_OSHEN_RED},fg:${P4_OSHEN_TEXT},header:${P4_OSHEN_TEAL},info:${P4_OSHEN_AMBER},pointer:${P4_OSHEN_PEACH},marker:${P4_OSHEN_PEACH},fg+:${P4_OSHEN_TEXT},prompt:${P4_OSHEN_AMBER},hl+:${P4_OSHEN_RED},border:${P4_OSHEN_OVERLAY0},label:${P4_OSHEN_PEACH}"

# Each menu entry opens a borderless popup (fzf draws its own labelled
# border) in the pane's cwd, and passes the origin pane id through so the
# selection lands in the right shell.
popup() {
  local kind="$1" w="$2" h="$3"
  echo "display-popup -B -E -w $w -h $h -d '#{pane_current_path}' 'bash $SELF run $kind #{pane_id}'"
}

case "$1" in
  menu)
    tmux display-menu -T "#[align=centre,fg=${P4_OSHEN_PEACH}]  fzf-git  " -x C -y C \
      "Files"      f "$(popup files     85% 75%)" \
      "Branches"   b "$(popup branches  85% 75%)" \
      "Tags"       t "$(popup tags      70% 60%)" \
      "Remotes"    r "$(popup remotes   70% 60%)" \
      "" \
      "Hashes"     h "$(popup hashes    85% 75%)" \
      "Stashes"    s "$(popup stashes   85% 75%)" \
      "Reflogs"    l "$(popup lreflogs  85% 75%)" \
      "" \
      "Worktrees"  w "$(popup worktrees 70% 60%)" \
      "Each ref"   e "$(popup each_ref  85% 75%)" \
      "" \
      "Exit"       q ""
    ;;

  run)
    kind="$2"
    pane="$3"
    [[ -z "$kind" || -z "$pane" ]] && { p4_error "usage: fzf-git.sh run <kind> <pane_id>"; exit 1; }
    [[ -f "$FZF_GIT" ]] || { p4_error "fzf-git.sh not found at $FZF_GIT"; sleep 2; exit 1; }

    # fzf-git.sh evals $__fzf_git_fzf instead of its own _fzf_git_fzf when
    # set. The upstream default uses --tmux, which would try to open a nested
    # popup from inside this one, so replace it with a full-size fzf using
    # the oshen palette. Kept in sync with upstream's flags otherwise.
    _fzf_git_fzf() {
      fzf --layout reverse --multi \
        --no-separator --header-border horizontal \
        --border rounded --border-label-pos 2 \
        --color "$FZF_GIT_COLORS" \
        --preview-window 'right,50%' --preview-border line \
        --bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
    }
    export __fzf_git_fzf
    __fzf_git_fzf="$(declare -f _fzf_git_fzf)"

    result="$(bash "$FZF_GIT" --run "$kind")"
    [[ -z "$result" ]] && exit 0

    # Multi-select comes back one per line; shell-quote and join with spaces
    # so it drops into the command line the same way the CTRL-G widget does.
    out=""
    while IFS= read -r item; do
      [[ -n "$item" ]] && out+="$(printf '%q' "$item") "
    done <<< "$result"

    tmux send-keys -t "$pane" -l "$out"
    ;;

  *)
    p4_error "unknown command: $1"
    echo "usage: fzf-git.sh menu | run <kind> <pane_id>"
    exit 1
    ;;
esac
