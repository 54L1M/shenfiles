{
  description = "54L1M Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:

    let
      configuration = { pkgs,config, ... }: {

        nixpkgs.config.allowUnfree = true;
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = with pkgs; [
          alacritty
          mkalias
          neovim
          git
          tmux
          tmuxifier
          rustup
          mpv
          go
          gopls
          # Adding python with packages directly
          python313   
          bat
          vscode
          ripgrep
          nodejs_22
          thefuck
          htop
          ffmpeg
          postgresql_16
          python313Packages.pip
      	  stow
          oh-my-zsh
          neofetch
        ];
        homebrew = {
          enable = true;
          brews = [
            "mas"
            "hugo"
            "yq"
          ];
          casks = [
            "firefox"
            "chatgpt"
            "android-file-transfer"
	          "discord"
            "obsidian"
            "spotify"
          ];
          masApps = {
          };
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;

        };
        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
          
        system.activationScripts.applications.text =
          let
            env = pkgs.buildEnv {
              name = "system-applications";
              paths = config.environment.systemPackages;
              pathsToLink = "/Applications";
            };
          in
          pkgs.lib.mkForce ''
            # Set up applications.
            echo "setting up /Applications..." >&2
            rm -rf /Applications/Nix\ Apps
            mkdir -p /Applications/Nix\ Apps
            find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read -r src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
          '';

        system.defaults = {
          dock.autohide = true;
          dock.persistent-apps = [
            "${pkgs.alacritty}/Applications/Alacritty.app"
            "/Applications/Firefox.app"
            #"/System/Applications/Mail.app"
            "/System/Applications/Calendar.app"
            "/Applications/Obsidian.app/"
            "/Applications/Spotify.app/"
            "/Applications/Discord.app/"
            "/Applications/Google Chrome.app/"
          ];
          finder.FXPreferredViewStyle = "clmv";
          loginwindow.GuestEnabled = false;
          NSGlobalDomain.AppleICUForce24HourTime = true;
          NSGlobalDomain.AppleInterfaceStyle = "Dark";
          NSGlobalDomain.KeyRepeat = 2;
        };
        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        # programs.fish.enable = true;
        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 5;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."shen" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
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

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."shen".pkgs;
    };
}
