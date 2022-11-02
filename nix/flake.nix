{
  description = "54L1M Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
        ./modules/users.nix
        # Home Manager user configurations
        # home-manager.darwinModules.home-manager
        # {
        #   home-manager.useGlobalPkgs = true;
        #   home-manager.useUserPackages = true;
        #
        #   # User-specific Home Manager configuration
        #   home-manager.users."54l1m" = import ./home.nix;
        # }

        # Homebrew configuration (for Nix homebrew)
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "54l1m";
            autoMigrate = true;
          };
        }
      ];
    };
  };
}
