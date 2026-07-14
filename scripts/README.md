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

Here is a summary of the scripts in `bin/` (installed to your `PATH`) and the `tmux/` integration hub:

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

A utility for swapping `.env` profiles per project across deployment environments (e.g. dev, staging, prod). Configuration lives at `~/.config/p4/p4e.yaml` and is auto-created with a commented example on first run.

**Layout it expects:** each project has an `ENV/` folder holding profile templates (`.env.dev`, `.env.staging`, …). `p4e` assembles the chosen template — plus a small metadata header — into `ENV/.env`, then sources it in the current `tmux` pane.

**Commands:**

- `p4e` — show the environment active in this pane.
- `p4e switch <proj>.<env>` (alias `s`) — assemble and source a specific profile, e.g. `p4e switch ats.dev`.
- `p4e switch <proj>` — pick the profile interactively (`fzf`).
- `p4e switch` — pick both project and profile interactively.
- `p4e clear` (alias `c`) — unset the active profile's variables in the current pane and reset the status flag. See the note below.
- `p4e list` (alias `ls`) — list projects and their available profiles, marking the active one.
- `p4e link [proj]` — symlink the project-root `.env` → `ENV/.env`, for apps that expect `.env` in the root.
- `p4e edit` (alias `e`) — open the config file.

**Options:** `-c, --config <file>` to use an alternative config; `-h, --help` for usage.

**Notes:**

- Re-switching to the already-active profile is a no-op unless the underlying template changed, in which case the active file is rebuilt.
- Inside `tmux`, the active `project:env` is written to a per-pane option consumed by the status bar (`scripts/tmux/p4e.sh`), and is also reachable from the `prefix + Space` menu → **Environment**.
- `clear` parses the variable names out of the active `ENV/.env` (the file that was sourced) and sends an `unset` for each — plus `P4E_CURRENT_ENV` — into the pane, then unsets the status flag. It is manual by design (`switch` never auto-clears). Two limits: it only unsets keys defined in the *current* profile (stale keys left by an earlier profile aren't touched), and it cannot restore a variable's pre-source value. Outside `tmux` it prints the `unset` command for you to run.

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

### `p4v.sh`

**VPS Status Dashboard**

A read-only health dashboard for remote VPS servers, gathered over a single SSH connection and rendered with the oshen palette.

**What it does:**

- Checks reachability, then reports: host/uptime, system health (CPU load, memory, swap, disk), pending apt updates + reboot-required, firewall (UFW) rules, fail2ban jails (banned/failed counts), recent logins and failed SSH attempts, TLS certificate expiry (via certbot), key systemd services, and all Docker containers with status.
- Firewall and fail2ban require root: the sudo password is **prompted (hidden) each run** and never stored. Sections that can't get sudo degrade to a warning instead of failing.
- Supports multiple servers via UPPERCASE alias suffixes (`P4V_HOST_<ALIAS>`); `fzf`-selects when more than one is configured.

**Example Configuration (`~/.config/p4/p4v` — gitignored):**

```
P4V_HOST="203.0.113.10"
P4V_USER="salim"
# P4V_SUDO_PASS=""   # optional; unset = prompt each run

# extra server, alias WEB:
# P4V_HOST_WEB="198.51.100.5"
# P4V_USER_WEB="salim"
```

> The config file holds the server IP (and optionally the sudo password), so it is gitignored (`p4/p4v`) even though it lives inside the stow-managed `p4/` directory.

**Usage:**

- `p4v` / `p4v status [alias]`: Show the full dashboard (default).
- `p4v ssh [alias]`: Open an interactive SSH session to the server.
- `p4v ls`: List configured servers.

---

### `tmux/menus.sh`

**Tmux Popup & Menu Hub**

Centralized handler for the themed `tmux` popups and menus. Everything is styled with the oshen palette (shared `FZF_COLORS`) and wired to the `p4*` tools. It is invoked from keybindings defined in `tmux/tmux.conf`.

**Keybindings:**

- `prefix + Space` — open the **p4 Manager** menu: a single hub linking the Session Manager, Window Manager, Cloud SQL proxy start/stop, K8s context, GCloud project, environment switcher (`p4e`), logs, and dotfiles quick-edit.
- `prefix + s` — jump straight to the **Session Manager**.
- `prefix + w` — jump straight to the **Window Manager** (replaces the native window tree with a floated, themed one).

**Session Manager:** an `fzf` popup listing live `tmux` sessions and configured `p4m` layouts that aren't running yet. `enter` switches to (or launches, via `p4m`) the selection; `C-x` kills the highlighted session; `C-n` creates a new ad-hoc session. For a live session the preview shows its window list plus a live capture of the active window's content; for a not-yet-running `p4m` layout it shows the configured path and windows.

**Window Manager:** an `fzf` popup listing the current session's windows (active window marked). `enter` switches to a window; `C-x` kills it; `C-n` creates a new window. The preview shows a live capture of each pane in the highlighted window, so it mirrors the window's real state.

---

### `create_dirs.sh`

**Directory Structure Initializer**

A personal script to create a predefined directory structure within `~/Documents` and clone frequently used git repositories. Primarily called by `setup.sh` during initial bootstrap.

---
