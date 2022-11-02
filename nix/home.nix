{ config, pkgs, ... }:

let
  dotfilesPath = "/Users/54L1M/shenfiles";  # Use absolute path
in
{
  home.stateVersion = "23.11";

  # User settings
  home.username = "54l1m";
  home.homeDirectory = "/Users/54L1M";

  # Symlink dotfiles
  home.file = {
    ".zshrc" = {
      source = "${dotfilesPath}/zsh/.zshrc";
    };
    ".tmux.conf" = {
      source = "${dotfilesPath}/tmux/.tmux.conf";
    };
    # ".config/nvim" = {
    #   source = "${dotfilesPath}/nvim/.config/nvim";
    # };
    ".config/alacritty" = {
      source = "${dotfilesPath}/alacritty/.config/alacritty";
    };
  };

  # Install essential packages
  home.packages = with pkgs; [
  ];
}
