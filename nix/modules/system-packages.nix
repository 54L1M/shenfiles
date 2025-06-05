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
    htop
    ffmpeg
    stow
    neofetch
    eza
    yazi
    glow
    aerospace
    unrar
    tree
    libffi
  ];
}
