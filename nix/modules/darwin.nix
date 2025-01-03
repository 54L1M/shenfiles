{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
