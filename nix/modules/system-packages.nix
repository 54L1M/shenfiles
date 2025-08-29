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
    eza
    yazi
    glow
    aerospace
    unrar
    tree
    libffi
  ];
}
