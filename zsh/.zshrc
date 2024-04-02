##########################
#ZSH STUFF
##########################
export ZSH="$HOME/.oh-my-zsh"

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
#    zsh-vi-mode
    zsh-z       )
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
alias reload="echo \"sourcing zshrc\" && source ~/.zshrc"
# nvim
alias vim="nvim"
alias nvimconf="cd ~/.config/nvim/lua/shen/"

# alias zshconfig="mate ~/.zshrc"

# file navigation
alias tmp="cd ${HOME}//Documents/0xshen/tmp"
alias repos="cd ${HOME}/Documents/0xshen/repos"
alias 0="cd ${HOME}/Documents/0xshen"
alias ghaaf="cd ${HOME}/Documents/0xshen/ghaaf"
alias amper="cd ${HOME}/Documents/0xshen/amper"
alias side="cd ${HOME}/Documents/0xshen/side"
alias mearn="cd ${HOME}/Documents/0xshen/mearn"
alias sf="cd ${HOME}/shenfiles"
alias vids="cd ${HOME}/Videos"
alias downs="cd ${HOME}/Downloads"
alias series="cd ${HOME}/Videos/series"

# git
alias gist="git status"
alias gish="git push"
alias giad="git add"
alias gico="git commit -m"
alias gicl="git clone"

# sound setting
alias nn="amixer -c 0 sset \"Auto-Mute Mode\" Enabled"

# Rust CLI Apps
alias ls="exa -l"
alias cat="bat"
#############
alias sl="ls"
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


# go configs
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH="$PATH:$(go env GOPATH)/bin"
# virtualenvwrapper
#export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
#export WORKON_HOME=$HOME/.virtualenvs
#export VIRTUALENVWRAPPER_SCRIPT=$HOME/.local/bin/virtualenvwrapper.sh
#source $HOME/.local/bin/virtualenvwrapper_lazy.sh
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/Library/Frameworks/Python.framework/Versions/3.12/bin/python3
export VIRTUALENVWRAPPER_VIRTUALENV=/Library/Frameworks/Python.framework/Versions/3.12/bin/virtualenv
source /Library/Frameworks/Python.framework/Versions/3.12/bin/virtualenvwrapper.sh
# add user bin to pass
export PATH=$PATH:$HOME/bin

# tmuxifier
export PATH="$HOME/.tmuxifier/bin:$PATH"##########################
eval "$(tmuxifier init -)"
export TMUXIFIER_LAYOUT_PATH="$HOME/.tmuxifier-layouts"
#PATH STUFF
##########################
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# eval "$(zoxide init zsh)"
