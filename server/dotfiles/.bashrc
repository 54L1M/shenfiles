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
export PATH="/usr/local/go/bin:$PATH" 
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

# 4. FUNCTIONS & ALIASES
# Smart Vim Function (opens current dir if no args)
v(){
  if [[ -z $1 ]]; then
    nvim .
  else
    nvim "$1"
  fi
}


alias ls="eza -l --icons --git"
alias lt="eza -lT --icons --git"
alias ..='cd ..'
alias reload='source ~/.bashrc && echo "Bashrc reloaded"'
alias sf="cd ${HOME}/shenfiles"


# Git
alias gist="git status"
alias gish="git push"
alias giad="git add"
alias gico="git commit -m"
alias gicl="git clone"


# System
alias upd='sudo apt update && sudo apt upgrade -y'
alias in='sudo apt install'
alias unin='sudo apt remove'
alias are='sudo apt autoremove'

# Tools
alias k='kubectl'
alias tx='tmux'
alias cat='bat' # Ubuntu usually names the binary 'batcat'
alias catc="bat -p"
alias d='docker'
alias dc='docker compose'

# 5. TOOLS & INTEGRATIONS
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

# FZF Configuration (Matches your local Zsh experience)
export FZF_CTRL_R_OPTS="
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Preview file content using bat (needs batcat installed on server)
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'batcat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# Tree preview for directory jumps (Alt-C)
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
