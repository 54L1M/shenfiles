{
  description = "54L1M Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = { self, nixpkgs, nix-darwin, nix-homebrew, ... }: {
    darwinConfigurations."54L1M" = nix-darwin.lib.darwinSystem {
      modules = [
        ./modules/darwin.nix
        ./modules/system-packages.nix
        ./modules/homebrew.nix
        ./modules/fonts.nix
        ./modules/defaults.nix
        ./modules/services.nix
        ./modules/programs/zsh.nix
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "54L1M";
            autoMigrate = true;
          };
        }
      ];
    };
  };
}
