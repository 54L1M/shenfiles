# ~/.bashrc
[[ $- != *i* ]] && return

# 1. HISTORY
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# 2. PATHS
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR='nvim'

# 3. PROMPT
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
GREEN='\[\033[01;32m\]'
BLUE='\[\033[01;34m\]'
PURPLE='\[\033[01;35m\]'
RESET='\[\033[00m\]'
PS1="${GREEN}\u@\h${RESET}:${BLUE}\w${PURPLE}\$(parse_git_branch)${RESET}\$ "

# 4. ALIASES
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias v='nvim'
alias g='git'
alias upd='sudo apt update && sudo apt upgrade -y'
alias gs='git status'
alias d='docker'
alias dc='docker compose'
alias cat='batcat'

# 5. TOOLS
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
