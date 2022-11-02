# Custom Scripts

This directory contains a collection of custom scripts to automate and simplify various development and system management tasks.

The `install.sh` script handles the installation of these tools, making them available in your `PATH`. It symlinks the executables from `bin/` into `~/.local/bin/` and also installs their corresponding Zsh completions from the `completions/` directory.

**Note on Configuration:** All `p4*` scripts store their configuration files in a central directory: `~/.config/p4/`.

## Installation

To install all scripts and their completions, run the installer from the root of the repository:

```bash
./scripts/install.sh
```

The installer also has options for forcing updates and uninstalling scripts. Use `./scripts/install.sh --help` for more details.

## Available Scripts

Here is a summary of the scripts located in the `bin/` directory:

---

### `setup.sh`

**Master Bootstrap Script**

This is the main script for setting up a new macOS machine from scratch. It automates the entire process of installing the development environment as defined in this repository.

**What it does:**

- Installs [Nix](https://nixos.org).
- Configures Nix to use Flakes.
- Installs and applies the `nix-darwin` configuration from the `nix/` directory, which handles system settings and package installation.
- Executes `create_dirs.sh` to scaffold the user's home directory with project folders and clones necessary git repositories.

---

### `p4m.sh`

**Tmux Development Session Manager**

A powerful script for creating and managing project-specific `tmux` sessions. It uses a YAML config file to define workspaces, automating the setup of windows, panes, and initial commands.

**Usage:**

- `p4m <session_name>`: Creates or attaches to a defined `tmux` session.
- `p4m sessions`: Lists all available sessions from the configuration.
- `p4m list`: Lists all currently running `tmux` sessions.

The configuration is located at `~/.config/p4/p4m.yaml`. The script will generate an example config on first run.

---

### `p4e.sh`

**Project Environment Switcher**

A utility for managing `.env` files for different projects and deployment environments (e.g., dev, staging, prod). Its configuration is located at `~/.config/p4/p4e.yaml`.

**What it does:**

- Uses `fzf` for interactively selecting a project and an associated environment profile (e.g., `.env.dev`, `.env.prod`).
- Copies the selected profile to a standard `ENV/.env` file that can be sourced.
- Can automatically source the new environment file in the current `tmux` pane.
- Provides a `link` command to symlink the project's root `.env` to the active one in `ENV/.env`, which is useful for applications that expect it in the root.

---

### `p4s.sh`

**Generalized Repository Synchronizer**

A flexible script to automate the process of staging, committing, and pushing changes for any git repository. It works by creating a separate commit for each changed file, similar to `shensync.sh`.

**What it does:**

- Iterates through each new, modified, or deleted file.
- Creates a unique commit for each file.
- Pushes all the new commits to the remote repository.

**Features:**

- **Config-driven Profiles:** Can be configured with profiles in `~/.config/p4/p4s.yaml`. Each profile can specify a repository path and a commit message template.
- **Interactive Mode:** When run without arguments (`p4s`), it provides an `fzf`-powered menu to choose a profile.
- **Manual Mode:** You can target an arbitrary repository using the `-d /path/to/repo` flag.
- **Custom Commit Messages:** A commit message _template_ can be provided with the `-m "your template with $file_name"` flag. This overrides any other settings.
- **Templating:** If a template is provided (via `-m` or the config file), the script will substitute `$file_name` with the name of the file being committed. If no template is given, it defaults to messages like "Update README.md" or "Add new_file.js".

---

### `p4p.sh`

**Cloud SQL Proxy Manager**

A utility for managing Google Cloud SQL Proxy instances. It simplifies starting and stopping proxy connections to various database profiles, utilizing `tmux` for session management and `fzf` for interactive profile selection.

**What it does:**

- Loads database connection configurations from `~/.config/p4/p4p`.
- Allows interactive selection of Cloud SQL profiles using `fzf`.
- Starts the Cloud SQL Proxy in a detached `tmux` session.
- Provides real-time log streaming of the proxy process.
- Facilitates stopping individual or all running proxy sessions.

**Example Configuration (`~/.config/p4/p4p`):**

```
# Profile: PROD
DB_INSTANCE_PROD="project:region:instance-name"
DB_PORT_PROD="5433"
```

**Usage:**

- `p4p start [profile_name]`: Start the proxy for a specific profile, or interactively select one.
- `p4p stop [profile_name]`: Stop the proxy for a specific profile, or interactively select a running one.

---

### `create_dirs.sh`

**Directory Structure Initializer**

A personal script to create a predefined directory structure within `~/Documents` and clone frequently used git repositories. Primarily called by `setup.sh` during initial bootstrap.

---
