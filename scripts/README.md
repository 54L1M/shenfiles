# Custom Scripts

This directory contains a collection of custom scripts to automate and simplify various development and system management tasks.

| Directory | What it holds |
|---|---|
| `bin/` | The tools themselves. Installed into `~/.local/bin` without the `.sh` extension |
| `completions/` | Zsh completions, installed as `~/.zsh/completions/_<name>` |
| `lib/` | Shared shell libraries the tools source: colors and output helpers, general utilities |
| `tmux/` | Status-bar segments and popup menus, called from `tmux/tmux.conf` |
| `install.sh` | The installer for the Mac |

**Note on Configuration:** All `p4*` scripts store their configuration files in a central directory: `~/.config/p4/` (the `p4/` directory of this repo).

## Installation

**Mac.** Run the installer from the root of the repository:

```bash
./scripts/install.sh
```

It symlinks the executables from `bin/` into `~/.local/bin/`, the libraries from `lib/` into `~/.local/lib/`, and the completions into `~/.zsh/completions/`. It also has options for forcing updates and uninstalling scripts; see `./scripts/install.sh --help`.

**PC (NixOS).** There is no install step. Home Manager creates the same symlinks from the lists in `nix/hosts/pc/home.nix`. A new script, completion or library file must be added to those lists, or it will not be linked on the PC.

## Available Scripts

| Tool | What it does |
|---|---|
| [`p4`](#p4) | Root command: lists the other tools and dispatches to them |
| [`p4m`](#p4msh) | tmux development sessions from a YAML config |
| [`p4e`](#p4esh) | Switch `.env` profiles per project |
| [`p4s`](#p4ssh) | Commit each changed file separately and push |
| [`p4g`](#p4gsh) | Switch gcloud project and account |
| [`p4k`](#p4ksh) | Switch Kubernetes context and namespace, browse pods |
| [`p4p`](#p4psh) | Start and stop Cloud SQL proxies |
| [`p4l`](#p4lsh) | Tail logs from proxies, pods and tmux server windows |
| [`p4v`](#p4vsh) | Read-only status dashboard for a VPS |
| [`p4n`](#p4nsh) | Scaffold a new project with a Nix flake and direnv |
| [`bbox`](#bboxsh) | Encrypt and decrypt a file with a passphrase |
| [`shensync`](#shensyncsh) | Older dotfiles-only version of `p4s` |
| [`setup.sh`](#setupsh), [`create_dirs.sh`](#create_dirssh) | New-machine bootstrap |
| [`tmux/`](#tmuxmenussh) | Menus, pickers and status-bar segments |

Every tool accepts `-h` / `--help`.

---

### `p4`

**Root Command**

Lists every `p4*` tool with its one-line description, and runs one by its suffix. The description comes from the `# P4_DESC:` comment at the top of each script, so a new script shows up here without further wiring.

**Usage:**

- `p4` or `p4 list`: show all tools.
- `p4 <suffix> [args]`: run a tool, e.g. `p4 m mapper` is `p4m mapper`.
- `p4 fzf`: pick a tool interactively, with its source as the preview.
- `p4 edit`: open `~/.config/p4/` in `$EDITOR`.
- `p4 update`: sync the dotfiles (runs `p4s shen`).

---

### `setup.sh`

**Master Bootstrap Script**

This is the main script for setting up a new macOS machine from scratch. It automates the entire process of installing the development environment as defined in this repository. The PC does not use it; NixOS is installed following `nix/hosts/pc/README.md`.

**What it does:**

- Installs [Nix](https://nixos.org).
- Configures Nix to use Flakes.
- Fetches the `nix/` submodule if the clone was not recursive, then installs and applies its `nix-darwin` configuration, which handles system settings and package installation.
- Executes `create_dirs.sh` to scaffold the user's home directory with project folders and clones necessary git repositories. Skip this with `--no-dirs`.

---

### `p4m.sh`

**Tmux Development Session Manager**

A powerful script for creating and managing project-specific `tmux` sessions. It uses a YAML config file to define workspaces, automating the setup of windows, panes, and initial commands.

**Usage:**

- `p4m <session_name>`: Creates or attaches to a defined `tmux` session.
- `p4m sessions` (alias `s`): Lists all available sessions from the configuration.
- `p4m list` (alias `ls`): Lists all currently running `tmux` sessions.
- `p4m edit` (alias `e`): Opens the configuration file.
- `p4m -k <session_name>`: Kills the session instead of attaching.
- `p4m -c <file>`: Uses an alternative config file.

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
- For a profile that lists `submodules`, syncs each submodule first, then the parent repository.

Only plain states are handled: modified, deleted, untracked (new) and fully staged new files. Anything else, such as a file marked with `git add -N` or one with both staged and unstaged changes, is skipped with a warning and stays uncommitted.

This repo has one profile, `shen`, in `p4/p4s.yaml`. It syncs `~/shenfiles` and its `nix` submodule with messages like `chore(dotfiles): sync <file>`. `p4 update` runs it.

**Features:**

- **Config-driven Profiles:** Can be configured with profiles in `~/.config/p4/p4s.yaml`. Each profile can specify a repository path and a commit message template.
- **Interactive Mode:** When run without arguments (`p4s`), it provides an `fzf`-powered menu to choose a profile.
- **Manual Mode:** You can target an arbitrary repository using the `-d /path/to/repo` flag.
- **Custom Commit Messages:** A commit message _template_ can be provided with the `-m "your template with $file_name"` flag. This overrides any other settings.
- **Templating:** If a template is provided (via `-m` or the config file), the script will substitute `$file_name` with the name of the file being committed. If no template is given, it defaults to messages like "Update README.md" or "Add new_file.js".

---

### `p4g.sh`

**GCloud Project & Account Switcher**

Switches the active gcloud project, and the account that goes with it, from an `fzf` list of aliases. Refreshes the `tmux` status bar afterwards.

**Usage:**

- `p4g` or `p4g proj`: pick a project alias and switch to it.
- `p4g acct`: pick one of the authenticated gcloud accounts.
- `p4g login`: run `gcloud auth login` and the application-default login.
- `p4g status` (alias `s`): show the current project and account.

**Configuration (`~/.config/p4/p4g`):** one line per alias. A starter file is created on first run.

```
P4G_PROJECT_<ALIAS>="<gcp-project-id>"
P4G_ACCOUNT_<ALIAS>="<email>"        # optional, per project
P4G_DEFAULT_ACCOUNT="<email>"        # used when a project has no account
```

---

### `p4k.sh`

**Kubernetes Context & Namespace Switcher**

`fzf` pickers over the kubeconfig. Refreshes the `tmux` status bar afterwards.

**Usage:**

- `p4k` or `p4k ctx`: switch the active context.
- `p4k ns`: switch the namespace of the current context, with a pod preview.
- `p4k pods [namespace]`: browse pods with a status and `describe` preview. `Enter` opens a shell in the pod, `C-w` does it in a new `tmux` window, `C-r` shows running pods only, `C-a` shows all.
- `p4k status` (alias `s`): print the current context and namespace.

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

### `p4l.sh`

**Unified Log Viewer**

One picker over every log source it can find: Cloud SQL proxy logs written by `p4p` (`/tmp/cloud-sql-proxy-<profile>.log`), Kubernetes pods in the current namespace, and the `server` window of any running `p4m` session.

**Usage:**

- `p4l`: pick a source with `fzf`, with the last lines as the preview.
- `p4l proxy [profile]`: tail a proxy log.
- `p4l pod [pod-name]`: stream a pod's logs.

**Options:** `-n, --lines <N>` history lines (default 50); `--since <duration>` for pods, e.g. `5m`; `--ns <namespace>`.

---

### `p4v.sh`

**VPS Status Dashboard**

A read-only health dashboard for remote VPS servers, gathered over a single SSH connection and rendered with the oshen palette.

**What it does:**

- Checks reachability, then reports: host/uptime, system health (CPU load, memory, swap, disk), updates and whether a reboot is needed, firewall rules, fail2ban jails (banned/failed counts), recent logins and failed SSH attempts, TLS certificate expiry, key systemd services plus any failed units, and all Docker containers with status.
- Works on NixOS and on Debian/Ubuntu, and picks the right checks per server (table below).
- Firewall rules, fail2ban jails and failed logins require root: the sudo password is **prompted (hidden) each run** and never stored. Sections that can't get sudo degrade to a warning instead of failing.
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
- `p4v certs [alias]` (alias `renew`): Renew TLS certificates that are expired or expire within 30 days, through certbot.
- `p4v ssh [alias]`: Open an interactive SSH session to the server.
- `p4v ls`: List configured servers.

**What differs per system:**

| Section | NixOS | Debian/Ubuntu |
|---|---|---|
| Updates | NixOS version, age of the nixpkgs revision it was built from, generation number and deploy time | Pending apt updates, security updates |
| Reboot | Required when the running kernel differs from the deployed one | `/var/run/reboot-required` |
| Firewall | `firewall.service` state and the open ports from the `nixos-fw` chain | `ufw status verbose` |
| TLS certificates | Asks the local web server what it serves for each name under `/var/lib/acme`; no root needed | `certbot certificates` |
| `p4v certs` | Starts the certificate's ACME renewal service | `certbot renew`, stopping a container on port 80 if needed |

On NixOS, renewal already runs from systemd timers, so `p4v certs` is only for forcing a check.

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

### `tmux/fzf-git.sh`

**Git Pickers in a Popup**

Runs the fzf-git pickers (files, branches, tags, remotes, hashes, stashes, reflogs, worktrees) in a `tmux` popup and pastes the selection into the pane it was opened from.

- `prefix + g`: open the picker menu.

It exists because `vim-tmux-navigator` captures `C-h` and `C-l`, which collide with the `C-g` chords of `zsh/fzf-git.sh`.

---

### `tmux/` status-bar segments

Small scripts that `tmux.conf` calls to fill the status bar. They print nothing when there is nothing to show.

| Script | Shows |
|---|---|
| `tmux/pods.sh` | Current Kubernetes namespace and its pod count |
| `tmux/gcloud.sh` | Whether gcloud is authenticated (run `p4g login` if not) |
| `tmux/cloud-sql.sh` | Cloud SQL proxies started by `p4p` |
| `tmux/p4e.sh` | The `p4e` environment active in the current pane |

---

### `p4n.sh`

**Nix Project Initializer**

Creates a new project directory with a `flake.nix` dev shell, an `.envrc` for direnv, a `.gitignore`, and an initial git commit.

**Usage:** `p4n <project-name> [lang]`

| `lang` | Dev shell contains |
|---|---|
| `go` | go, gopls, gotools, go-tools, delve |
| `python`, `py` | python3, uv, ruff. Also writes a `pyproject.toml` and creates a uv-managed `.venv` on first entry |
| `ts`, `typescript` | nodejs, pnpm, typescript, typescript-language-server |
| (none) | An empty dev shell to fill in |

---

### `bbox.sh`

**File Encryption**

Encrypts or decrypts a single file with a passphrase, using `openssl` (AES-256-CBC, key derived with PBKDF2 at 600,000 iterations). The passphrase is prompted and never stored. Output files are created with mode `600`.

**Usage:**

- `bbox e <file>`: encrypt to `<file>.bbox`.
- `bbox d <file>.bbox`: decrypt, stripping the `.bbox` extension.
- `-o <output>`: override the output path.

A wrong passphrase fails cleanly and leaves no partial output file.

---

### `shensync.sh`

**Dotfiles Sync (older)**

The original version of `p4s`, fixed to this repository: one commit per changed file (`Update <file>`, `Add <file>`, `Remove <file>`), then a push. It does not handle the `nix` submodule. Prefer `p4 update`.

---

### `create_dirs.sh`

**Directory Structure Initializer**

A personal script to create a predefined directory structure within `~/Documents` and clone the git repositories listed in the `repos` file at the repository root. Primarily called by `setup.sh` during initial bootstrap.

---

## Shared libraries

The tools source two files from `lib/`:

- `lib/colors/colors.sh`: the oshen color palette and the output helpers every script uses (`p4_header`, `p4_info`, `p4_success`, `p4_warn`, `p4_error`, `p4_step`, `p4_cmd`, `p4_die`, `p4_confirm`).
- `lib/utils/utils.sh`: general helpers for git state, files and paths, strings, processes, network checks and dates.

## Adding a script

1. Put it in `bin/` as `p4<letter>.sh`, make it executable, and source `lib/colors/colors.sh`.
2. Add a `# P4_DESC: ...` comment near the top so `p4` lists it.
3. Optionally add a completion file in `completions/` with the tool's name.
4. Mac: run `./scripts/install.sh`. PC: add the script, and the completion if there is one, to the lists in `nix/hosts/pc/home.nix` and rebuild.
