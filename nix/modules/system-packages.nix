{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mkalias
    neovim
    git
    tmux
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
  ];
}
