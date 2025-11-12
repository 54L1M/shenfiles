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

    #language server protocols
    ruff
    pyright
    lua-language-server
    bash-language-server
    dockerfile-language-server
    docker-compose-language-service 
    llvmPackages.clang

    #formatters
    prettier
    stylua
    black
    isort
    djlint
  ];
}
