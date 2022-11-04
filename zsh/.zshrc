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
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

# aliases
# alias zshconfig="mate ~/.zshrc"


# nvm configs
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# go configs
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go

# emacs configs
export PATH=$PATH:$HOME/.emacs.d/bin

# virtualenvwrapper
export WORKON_HOME=$HOME/.virtualenvs
