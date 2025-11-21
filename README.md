# 54L1M's Shenanigans - Dotfiles

This repository contains my personal dotfiles and system configuration for macOS. The setup is managed primarily by [Nix](https://nixos.org) and [nix-darwin](https://github.com/LnL7/nix-darwin), with a collection of custom scripts to automate common workflows.

## Philosophy

The goal is to create a reproducible and declarative development environment.

- **Declarative System Management:** `nix-darwin` is used to manage system-level settings, services, and packages. This ensures the core environment is consistent and can be rebuilt from the configuration files.
- **Hybrid Package Management:** The setup uses a combination of [Nix Flakes](https://nixos.wiki/wiki/Flakes) and [Homebrew](https://brew.sh) (via `nix-homebrew`).
  - **Nix:** Installs the majority of CLI tools, development libraries, and language servers.
  - **Homebrew:** Manages GUI applications (casks) and certain CLI tools that are more convenient to install via Homebrew.
- **Home Directory Management:** Application configurations (dotfiles) are symlinked from this repository using GNU Stow.
- **Custom Scripting:** A set of custom scripts in the `scripts/` directory provides automation for project management, environment setup, and other common tasks.

## Quick Start

This repository includes a bootstrap script to set up a new macOS machine from scratch.

**Warning:** The bootstrap script is idempotent but invasive. It will install Nix, configure your system using `nix-darwin`, and clone personal repositories. Review the script before running.

```bash
# 1. Clone the repository
git clone https://github.com/your-username/your-dotfiles-repo.git ~/shenfiles

# 2. Run the bootstrap script
/bin/bash ~/shenfiles/scripts/bin/mac_setup.sh
```

The `mac_setup.sh` script will:
1. Install Nix if it's not already present.
2. Enable Flakes support for Nix.
3. Apply the `nix-darwin` configuration from this repository, which installs all the managed packages and applications.
4. Run the `create_dirs.sh` script to set up a personal directory structure and clone project repositories.

## Managed Applications

This configuration manages a wide array of applications and tools, including:

**Development:**
- Neovim
- Git & Lazygit
- Tmux & Tmuxifier
- Rust, Go, Node, Python
- Docker
- VSCode
- Multiple LSPs (Ruff, Pyright, gopls, etc.)
- Formatters (Prettier, Stylua, Black, etc.)

**Terminal & Shell:**
- Alacritty, Ghostty
- Zsh
- Starship Prompt
- eza, bat, fzf, ripgrep

**GUI Applications:**
- Firefox, Google Chrome
- Slack, Discord, ChatGPT
- Obsidian
- Postman

**Window Management:**
- Aerospace
- Sketchybar
- Borders

## Custom Scripts

This repository contains several powerful custom scripts to streamline workflows. These are located in the `scripts/` directory and are automatically installed to `~/.local/bin` by the `scripts/install.sh` script.

For a detailed breakdown of what each script does, please see the [Scripts README](./scripts/README.md).

## Structure

- **`nix/`**: Contains the core `flake.nix` and modules for the `nix-darwin` configuration.
  - `flake.nix`: Defines the inputs (Nixpkgs, nix-darwin, etc.) and the main `darwinSystem`.
  - `modules/`: Splits the configuration into logical units like packages, fonts, services, and Homebrew.
- **`nvim/`**, **`tmux/`**, **`zsh/`**, etc.: Contain the configuration files (dotfiles) for individual applications. These are symlinked into place by Stow.
- **`scripts/`**: Contains custom shell scripts.
  - `bin/`: Executable scripts intended to be in the `$PATH`.
  - `lib/`: Helper functions and libraries for the scripts.
  - `install.sh`: A script to symlink the `bin` and `lib` files into `~/.local/bin` and `~/.local/lib`.
- **`_archive/`**: Contains older or unused configurations.
