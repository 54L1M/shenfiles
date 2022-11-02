{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 5;
  system.primaryUser = "54l1m";
  nixpkgs.hostPlatform = "aarch64-darwin";
  # home-manager.backupFileExtension = "bak";
  # nix.useDaemon = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
