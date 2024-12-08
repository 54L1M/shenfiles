{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    alacritty
    mkalias
    neovim
    git
    tmux
    rustup
    mpv
    go
    gopls
    python313
    bat
    vscode
    ripgrep
    nodejs_22
    thefuck
    htop
    ffmpeg
    postgresql_16
  ];
}