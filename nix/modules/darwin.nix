{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
  home-manager.backupFileExtension = "bak";
  nix.useDaemon = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
