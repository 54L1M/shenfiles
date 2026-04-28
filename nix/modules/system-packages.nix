{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mkalias
    neovim
    git
    tmuxifier
    rustup
    go_1_25
    gopls
    bat
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
    tree-sitter
    esptool

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
