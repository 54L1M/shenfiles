{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
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
      "nushell"
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
    ];
    masApps = {};
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
