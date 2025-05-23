##########################
#ZSH STUFF
##########################
export ZSH="$HOME/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
# zsh theme
ZSH_THEME="muse"
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# zsh update reminder
zstyle ':omz:update' mode reminder  

# waiting dots
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
COMPLETION_WAITING_DOTS="true"

# oh-my-zsh plugins
plugins=(git
    history-substring-search
    colored-man-pages
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
#    zsh-vi-mode
    z       )
source $ZSH/oh-my-zsh.sh

# set edtitor to neovim
export EDITOR='nvim'
##########################
#ZSH STUFF
##########################


##########################
#ALIAS
##########################
# zsh
alias zshconf="cd ~/shenfiles/zsh/ && nvim ."
alias reload="echo \"sourcing zshrc\" && source ~/.config/zsh/.zshrc"
# nvim
alias vim="nvim"
v(){
  if [[ -z $1 ]]; then
    nvim .
  else 
    nvim $1
  fi
}
alias nvimconf="cd ~/.config/nvim && nvim ."
# kubectl
alias k="kubectl"
# nix
alias nixconf="cd ~/shenfiles/nix/ && nvim ."
alias rn="sudo darwin-rebuild switch --impure --flake ~/shenfiles/nix#54L1M"
# alias zshconfig="mate ~/.zshrc"

# file navigation
alias tmp="cd ${HOME}//Documents/WorkStation/tmp"
alias repos="cd ${HOME}/Documents/WorkStation/repos"
alias 0="cd ${HOME}/Documents/WorkStation"
alias ghaaf="cd ${HOME}/Documents/WorkStation/ghaaf"
alias side="cd ${HOME}/Documents/WorkStation/side"
alias mearn="cd ${HOME}/Documents/WorkStation/mearn"
alias sf="cd ${HOME}/shenfiles"
alias vids="cd ${HOME}/Videos"
alias docs="cd ${HOME}/Documents"
alias downs="cd ${HOME}/Downloads"
tgl() {
  cd "${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/TheGreatLibrary"
}
alias series="cd ${HOME}/Videos/series"
alias i2d="cd ${HOME}/Documents/WorkStation/In2Dialog"
alias ats="cd ${HOME}/Documents/WorkStation/In2Dialog/I2D_ATS"
alias comp="cd ${HOME}/Documents/WorkStation/In2Dialog/I2D_Companion"
alias p4="cd ${HOME}/Documents/P4ndaF4ce"
# git
alias gist="git status"
alias gish="git push"
alias giad="git add"
alias gico="git commit -m"
alias gicl="git clone"

# sound setting
alias nn="amixer -c 0 sset \"Auto-Mute Mode\" Enabled"

# Rust CLI Apps
alias y="yazi"
alias ls="eza -l --icons --git"
alias cat="bat"
alias catc="bat -p"
#############
alias tf="tmuxifier"
alias tx="tmux"
alias f="fuck"
#alias sl="ls"
alias upd="sudo apt update"
alias upg="sudo apt upgrade"
alias lupg="apt list --upgradable"
alias in="sudo apt install"
alias unin="sudo apt remove"
alias are="sudo apt autoremove"
alias lg="lazygit"
##########################
#ALIAS
##########################

##########################
#PATH STUFF
##########################

# nvm configs
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

#pip 
export PATH=$PATH:$HOME/.local/bin/
#cargo
export PATH=$PATH:$HOME/.cargo/bin/


# go configs
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH="$PATH:$(go env GOPATH)/bin"
# virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_SCRIPT=/opt/homebrew/bin/virtualenvwrapper.sh
source /opt/homebrew/bin/virtualenvwrapper_lazy.sh
#export WORKON_HOME=$HOME/.virtualenvs
#export VIRTUALENVWRAPPER_PYTHON=/Library/Frameworks/Python.framework/Versions/3.12/bin/python3
#export VIRTUALENVWRAPPER_VIRTUALENV=/Library/Frameworks/Python.framework/Versions/3.12/bin/virtualenv
#source /Library/Frameworks/Python.framework/Versions/3.12/bin/virtualenvwrapper.sh
# add user bin to pass
export PATH=$PATH:$HOME/bin

# tmuxifier
export PATH="$HOME/.tmuxifier/bin:$PATH"##########################
eval "$(tmuxifier init -)"
export TMUXIFIER_LAYOUT_PATH="$HOME/.config/tmux/.tmuxifier-layouts"
#PATH STUFF
##########################
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# eval "$(zoxide init zsh)"

eval $(thefuck --alias)
# neofetch
fm6000 -r -c "random"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
fpath+=($HOME/.zsh/completions $fpath)
fpath+=~/.zfunc
autoload -Uz compinit
compinit -D

export PATH="/opt/homebrew/bin:$PATH"

source <(fzf --zsh)

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/54l1m/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/54l1m/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.

if [ -f '/Users/54l1m/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/54l1m/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

. "$HOME/.local/bin/env"

