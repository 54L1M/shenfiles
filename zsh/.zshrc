##########################
#ZSH STUFF
##########################
fpath=($HOME/shenfiles/scripts/completions $fpath)

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
[[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

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
# nix (per machine)
if [[ "$OSTYPE" == darwin* ]]; then
  alias nixconf="cd ~/shenfiles/nix/ && nvim ."
  alias rn="sudo darwin-rebuild switch --impure --flake ~/shenfiles/nix#54L1M"
else
  alias nixconf="cd ~/server/ && nvim ."
  alias rn="sudo nixos-rebuild switch --flake ~/server#pc"
fi
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
if [[ "$OSTYPE" == darwin* ]]; then
  tgl() {
    cd "${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/TheGreatLibrary"
  }
fi
alias series="cd ${HOME}/Videos/series"
alias i2d="cd ${HOME}/Documents/WorkStation/In2Dialog"
alias ats="cd ${HOME}/Documents/WorkStation/In2Dialog/I2D_ATS"
alias comp="cd ${HOME}/Documents/WorkStation/In2Dialog/I2D_Companion"
alias pf4="cd ${HOME}/Documents/pf4/"
alias 4="cd ${HOME}/Documents/pf4/"
# git
alias gist="git status -s -b"
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
#alias sl="ls"
# apt shortcuts, only where apt exists (Debian/Ubuntu machines)
if command -v apt >/dev/null; then
  alias upd="sudo apt update"
  alias upg="sudo apt upgrade"
  alias lupg="apt list --upgradable"
  alias in="sudo apt install"
  alias unin="sudo apt remove"
  alias are="sudo apt autoremove"
fi
alias lg="lazygit"
alias gca="p4g login"
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
command -v go >/dev/null && export PATH="$PATH:$(go env GOPATH)/bin"
# add user bin to pass
export PATH=$PATH:$HOME/bin

# tmuxifier
# export PATH="$HOME/.tmuxifier/bin:$PATH"##########################
# eval "$(tmuxifier init -)"
# export TMUXIFIER_LAYOUT_PATH="$HOME/.config/tmux/.tmuxifier-layouts"
#PATH STUFF
##########################
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# eval "$(zoxide init zsh)"

# eval $(thefuck --alias)
# neofetch
command -v fm6000 >/dev/null && fm6000 -r -c "random"

# Homebrew (Mac only)
if [[ "$OSTYPE" == darwin* ]]; then
  export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
fi
fpath+=($HOME/.zsh/completions)
fpath+=~/.zfunc
autoload -Uz compinit
compinit -D

if [[ "$OSTYPE" == darwin* ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi

source <(fzf --zsh)

# Clipboard command for fzf's CTRL-Y: pbcopy on the Mac, wl-copy on Wayland
if [[ "$OSTYPE" == darwin* ]]; then
  _clip="pbcopy"
  bindkey "ç" fzf-cd-widget   # Option+C on the Mac keyboard
else
  _clip="wl-copy"
fi
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# CTRL-Y to copy the command into clipboard
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | $_clip)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"
unset _clip
# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# Print tree structure in the preview window
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --preview 'tree -C {}'"

[[ -r "$ZDOTDIR/fzf-git.sh" ]] && source "$ZDOTDIR/fzf-git.sh"
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.

if [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"; fi
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.emacs.d/bin:$PATH"

if [[ "$OSTYPE" == darwin* ]]; then
  export ANDROID_HOME=~/Library/Android/sdk
  export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
fi

export TODO_DIR="$HOME/Documents/todo"
export TODO_FILE="$TODO_DIR/todo.txt"
export DONE_FILE="$TODO_DIR/done.txt"

eval "$(direnv hook zsh)"

[[ -r "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"


# Custom script completions
fpath+=($HOME/.zsh/completions $fpath)
