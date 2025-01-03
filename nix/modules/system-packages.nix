{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty
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
    oh-my-zsh
    neofetch
  ];
}
