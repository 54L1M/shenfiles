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
      "postgresql"
      "yarn"
      "python@3.9"
      "python@3.13"
      "argon2"
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
    ];
    masApps = {};
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
