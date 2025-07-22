{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [
       "nikitabobko/tap"
       "FelixKratz/formulae"
       "FelixKratz/formulae"
    ];

    brews = [
      "mas"
      "hugo"
      "yq"
      "lazygit"
      "zellij"
      "fzf"
      "node"
      "postgresql@14"
      "yarn"
      "python@3.9"
      "python@3.13"
      "argon2"
      "glib"
      "pango"
      "pgcli"
      "virtualenv"
      "virtualenvwrapper"
      "starship"
      "tmux"
      "k9s"
      "kubectx"
      "httpie"
      "sshpass"
      "fd"
      "coreutils"
      "findutils"
      "sketchybar"
      "borders"
      "figlet"
      "gh"
    ];
    casks = [
      "firefox"
      "chatgpt"
      "android-file-transfer"
      "discord"
      "obsidian"
      "spotify"
      "ghostty"
      "google-chrome"
      "alacritty"
      "lens"
      "slack"
      "postman"
      "aerospace"
    ];
    masApps = {};
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
