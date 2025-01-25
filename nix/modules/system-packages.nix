{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mkalias
    neovim
    git
    tmuxifier
    rustup
    mpv
    go
    gopls
    bat
    vscode
    ripgrep
    thefuck
    htop
    ffmpeg
    stow
    neofetch
    eza
    yazi
  ];
}
