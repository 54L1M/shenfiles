# 54L1M's Shenanigans - Dotfiles

This repository contains personal dotfiles and system configuration for macOS. The setup is managed primarily by [Nix](https://nixos.org) and [nix-darwin](https://github.com/LnL7/nix-darwin), with a collection of custom scripts to automate common workflows.

## Philosophy

The goal is to create a reproducible and declarative development environment that is easy for others to adapt and use.

- **Declarative System Management:** `nix-darwin` is used to manage system-level settings, services, and packages. This ensures the core environment is consistent and can be rebuilt from the configuration files.
- **Hybrid Package Management:** The setup uses a combination of [Nix Flakes](https://nixos.wiki/wiki/Flakes) and [Homebrew](https://brew.sh) (via `nix-homebrew`).
- **Custom Scripting:** A set of custom scripts in the `scripts/` directory provides automation for project management, environment setup, and other common tasks.

## Quick Start

This repository can be used to set up a new macOS machine from scratch.

### 1. Clone the Repository

Clone this repository to a location of your choice on your Mac. For example:

```bash
git clone https://github.com/54L1M/shenfiles.git ~/dotfiles
```

### 2. Customize (Optional)

This repository contains configurations for cloning personal projects. You can customize this by editing the `repos` file in the root of this repository. Simply add or remove lines to control which git repositories are cloned by the setup script.

### 3. Run the Setup Script

The main setup script will install Nix, apply the system configuration, and set up your environment.

```bash
# Navigate to the cloned directory
cd ~/dotfiles

# Run the setup script
./scripts/bin/setup.sh
```

By default, the setup script will also create a personalized directory structure and clone the repositories defined in the `repos` file. If you wish to install only the applications and system settings without creating personal directories, use the `--no-dirs` flag:

```bash
./scripts/bin/setup.sh --no-dirs
```

The `setup.sh` script will:

1. Install Nix if it's not already present.
2. Enable Flakes support for Nix.
3. Apply the `nix-darwin` configuration, which installs all managed packages and applications.
4. If run without `--no-dirs`, it will execute the `create_dirs.sh` script to set up a personal directory structure and clone project repositories from the `repos` file.

## Managed Applications

This configuration manages a wide array of applications and tools, including:

**Development:**

- Neovim, VSCode
- Git & Lazygit
- Tmux & Tmuxifier
- Rust, Go, Node, Python
- Docker
- LSPs (Ruff, Pyright, gopls, etc.) and Formatters

**Terminal & Shell:**

- Alacritty, Ghostty
- Zsh, Starship, eza, bat, fzf, ripgrep

**GUI Applications:**

- Firefox, Google Chrome
- Slack, Discord, ChatGPT, Obsidian, Postman

**Window Management:**

- Aerospace, Sketchybar, Borders

## Custom Scripts

This repository contains several powerful custom scripts to streamline workflows. For a detailed breakdown of what each script does, please see the [Scripts README](./scripts/README.md).

## Structure

- **`nix/`**: Contains the core `flake.nix` and modules for the `nix-darwin` configuration.
- **`repos`**: A plain text file listing personal git repositories to be cloned by the setup process.
- **`nvim/`**, **`tmux/`**, etc.: Application-specific configuration files (dotfiles).
- **`scripts/`**: Custom shell scripts, including the main `setup.sh` script.
- **`_archive/`**: Older or unused configurations.
