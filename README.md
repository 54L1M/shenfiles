# 54L1M's Shenanigans - Dotfiles

Personal dotfiles for two machines: a MacBook (nix-darwin) and a desktop PC (NixOS with Hyprland). The system configuration for both, and for a VPS, lives in the `nix/` git submodule ([54L1M/nix](https://github.com/54L1M/nix)).

Two layers, kept apart on purpose:

- **`nix/` decides what is installed.** Packages, services, system settings, users. Changing it needs a rebuild.
- **Everything else here is plain config files.** They are symlinked into `~/.config`, so an edit applies immediately with no rebuild.

The repo is expected at `~/shenfiles`; the shell aliases and the PC's Home Manager config use that path.

## Structure

| Path | What it is |
|---|---|
| `nix/` | Submodule: one flake for the Mac, the PC and the VPS. See its [README](https://github.com/54L1M/nix#readme) |
| `nvim/` | Neovim config (has its own [README](./nvim/README.md)) |
| `tmux/` | tmux config, colors, tmuxifier layouts |
| `zsh/` | `.zshrc` and fzf-git |
| `git/` | Global git config and ignore file |
| `ghostty/`, `bat/`, `starship/`, `yazi/` | Terminal, pager theme, prompt, file manager |
| `hypr/`, `waybar/` | Hyprland and Waybar, used on the PC only |
| `p4/` | Config files for the `p4*` scripts |
| `scripts/` | Custom scripts, their completions and the installer. See the [Scripts README](./scripts/README.md) |
| `repos` | List of personal repositories that `create_dirs.sh` clones |
| `_archive/` | Configs no longer in use (Alacritty, WezTerm, Sketchybar, Borders, AeroSpace, glow) |

## Clone

```bash
git clone --recurse-submodules git@github.com:54L1M/shenfiles.git ~/shenfiles
```

Run this once in every clone so the `nix/` submodule stays on its `master` branch:

```bash
cd ~/shenfiles
git -C nix switch master
git config submodule.nix.update merge
```

Without it, each `git pull` leaves `nix/` on a detached HEAD (`HEAD (no branch)`), and commits made there belong to no branch. The setting is stored in `.git/config`, so it is not synced between machines. If `nix/` is empty after a plain clone, run `git submodule update --init nix`.

## Mac setup

```bash
cd ~/shenfiles
./scripts/bin/setup.sh    # install Nix, enable flakes, apply the nix-darwin config
stow .                    # link the config directories into ~/.config
./scripts/install.sh      # link the scripts into ~/.local/bin, install zsh completions
```

- `setup.sh` also creates a personal directory layout under `~/Documents` and clones the repositories listed in `repos`. Pass `--no-dirs` to skip that part.
- `stow` reads `.stowrc`, which targets `~/.config` and skips `scripts/` and `_archive/`.
- After the first run, rebuild with `just mac` inside `nix/`, or the `rn` alias.

## PC setup

Installing NixOS on the PC is covered in [`nix/hosts/pc/README.md`](https://github.com/54L1M/nix/blob/master/hosts/pc/README.md).

There is no stow or `install.sh` step on the PC. Home Manager (`nix/hosts/pc/home.nix`) creates the same symlinks: the config directories into `~/.config`, the scripts into `~/.local/bin`, and the completions. The links point at this checkout, so edits still apply without a rebuild. Rebuild with `just pc` inside `nix/`, or the `rn` alias.

## What is installed

The package lists are the source of truth; this is only where to look.

| What | Where |
|---|---|
| Base tools on every machine (Neovim, git, ripgrep, fd, bat, eza) | `nix/modules/common/packages.nix` |
| Dev tools on the Mac and the PC (Go, Rust, language servers, formatters, yazi) | `nix/modules/desktop/packages.nix` |
| Mac apps and CLI tools from Homebrew (Ghostty, Firefox, Obsidian, Slack, tmux, starship) | `nix/hosts/mac/homebrew.nix` |
| PC desktop (Hyprland, Waybar, Ghostty, Firefox) | `nix/hosts/pc/default.nix` |

## Scripts

`scripts/bin/` holds the `p4*` tools (tmux sessions, project environments, repository sync, Cloud SQL proxy, VPS status), `shensync` (commit and push this repo's changes file by file) and the setup scripts. Each one is described in the [Scripts README](./scripts/README.md).
