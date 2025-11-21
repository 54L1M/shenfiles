# Custom Scripts

This directory contains a collection of custom scripts to automate and simplify various development and system management tasks.

The `install.sh` script handles the installation of these tools, making them available in your `PATH`. It symlinks the executables from `bin/` into `~/.local/bin/` and also installs their corresponding Zsh completions from the `completions/` directory.

## Installation

To install all scripts and their completions, run the installer from the root of the repository:

```bash
./scripts/install.sh
```

The installer also has options for forcing updates and uninstalling scripts. Use `./scripts/install.sh --help` for more details.

## Available Scripts

Here is a summary of the scripts located in the `bin/` directory:

---

### `mac_setup.sh`

**Master Bootstrap Script**

This is the main script for setting up a new macOS machine from scratch. It automates the entire process of installing the development environment as defined in this repository.

**What it does:**
- Installs [Nix](https://nixos.org).
- Configures Nix to use Flakes.
- Installs and applies the `nix-darwin` configuration from the `nix/` directory, which handles system settings and package installation.
- Executes `create_dirs.sh` to scaffold the user's home directory with project folders and clones necessary git repositories.

---

### `p4m.sh` (PandaMux)

**Tmux Development Session Manager**

A powerful script for creating and managing project-specific `tmux` sessions. It uses a YAML config file to define workspaces, automating the setup of windows, panes, and initial commands.

**Usage:**
- `p4m <session_name>`: Creates or attaches to a defined `tmux` session.
- `p4m sessions`: Lists all available sessions from the configuration.
- `p4m list`: Lists all currently running `tmux` sessions.

The configuration is located at `~/.config/p4m/sessions.yaml`. The script will generate an example config on first run.

---

### `p4e.sh` (PandaEnv)

**Project Environment Switcher**

A utility for managing `.env` files for different projects and deployment environments (e.g., dev, staging, prod).

**What it does:**
- Uses `fzf` for interactively selecting a project and an associated environment profile (e.g., `.env.dev`, `.env.prod`).
- Copies the selected profile to a standard `ENV/.env` file that can be sourced.
- Can automatically source the new environment file in the current `tmux` pane.
- Provides a `link` command to symlink the project's root `.env` to the active one in `ENV/.env`, which is useful for applications that expect it in the root.

---

### `shensync.sh`

**Dotfiles Repository Synchronizer**

A simple script to automate the process of committing and pushing changes to this dotfiles repository.

**What it does:**
- Checks for any modified, new, or deleted files in the git repository.
- Creates a unique commit for each change with a standardized message (e.g., "Update file.txt", "Add new_script.sh").
- Pushes all new commits to the `origin` remote.

---

### `create_dirs.sh`

**Directory Structure Initializer**

A personal script to create a predefined directory structure within `~/Documents` and clone frequently used git repositories into them. This is primarily called by `mac_setup.sh` during the initial bootstrap process.

---

### `black_box`

**File Encryption Utility**

A command-line tool for symmetrically encrypting and decrypting files using `openssl` and `argon2`.

**What it does:**
- Derives a strong encryption key from a password and salt using the Argon2 key derivation function.
- Encrypts/decrypts files using AES-256.
- Provides an option to securely shred the original file after encryption.
