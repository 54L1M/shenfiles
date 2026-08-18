{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mkalias
    neovim
    emacs30              # doom emacs (config in shenfiles/doom)
    fd                   # doom dependency (fast file finding)
    coreutils-prefixed   # gls for dired (doesn't shadow BSD tools)
    cmake                # vterm module compilation
    libtool              # vterm module compilation
    # macOS builds (e.g. emacs vterm's bundled libvterm) invoke GNU
    # libtool as `glibtool` (homebrew's naming); nix installs it
    # unprefixed, so expose it under both names.
    (pkgs.runCommand "glibtool" { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.libtool}/bin/libtool $out/bin/glibtool
      ln -s ${pkgs.libtool}/bin/libtoolize $out/bin/glibtoolize
    '')
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
    shfmt
    nixfmt-rfc-style
  ];
}
