#!/usr/bin/env bash
# p4e - Project Environment Switcher
# P4_DESC: Environment switcher — swap .env profiles per project with tmux integration
# Author: PF4
# Usage: p4e <command> [args]

set -e

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$BASE_DIR/lib"

# Source the color utilities
source "$LIB_DIR/colors/colors.sh"

# Configuration
CONFIG_FILE="$HOME/.config/p4/p4e.yaml"

# ==========================================
# CONSTANTS
# ==========================================

ENV_DIR_NAME="ENV"        # Sub-directory (per project) holding .env.<name> templates
ACTIVE_ENV_FILE=".env"    # The assembled, active env file — lives in ENV/ and root
LINK_TARGET="ENV/.env"    # Relative symlink written into the project root
HEADER_LINES=3            # Metadata lines p4e prepends to the assembled ENV/.env

# fzf --color string using the oshen palette (see scripts/tmux/menus.sh)
FZF_COLORS="bg+:${P4_OSHEN_MANTLE},bg:${P4_OSHEN_BASE},spinner:${P4_OSHEN_TEAL},hl:${P4_OSHEN_RED},fg:${P4_OSHEN_TEXT},header:${P4_OSHEN_TEAL},info:${P4_OSHEN_AMBER},pointer:${P4_OSHEN_PEACH},marker:${P4_OSHEN_PEACH},fg+:${P4_OSHEN_TEXT},prompt:${P4_OSHEN_AMBER},hl+:${P4_OSHEN_RED}"

# ==========================================
# HELP
# ==========================================

function show_help() {
  p4_header "p4e - Environment Profile Switcher"
  p4_info "Usage: p4e <command> [args]"
  echo

  p4_title "Commands:"
  p4_cmd "p4e" "" "Show the environment active in this pane"
  p4_cmd "p4e switch, s" "<proj>.<env>" "Switch to a profile (e.g. 'ats.dev')"
  p4_cmd "p4e switch, s" "[proj]" "Switch with interactive selection"
  p4_cmd "p4e link" "[proj]" "Symlink <proj>/.env -> $LINK_TARGET"
  p4_cmd "p4e list, ls" "" "List projects and their available profiles"
  p4_cmd "p4e edit, e" "" "Edit the configuration file"
  p4_cmd "p4e help" "" "Show this help message"
  echo

  p4_title "Options:"
  p4_cmd "-h, --help" "" "Show this help message"
  p4_cmd "-c, --config" "<file>" "Use an alternative config file"
  echo

  p4_title "Examples:"
  p4_example "p4e switch ats.dev" "Assemble & source the dev profile for 'ats'"
  p4_example "p4e s ats" "Pick a profile for 'ats' interactively"
  p4_example "p4e switch" "Pick both project and profile interactively"
  p4_example "p4e link ats" "Create the .env symlink in the project root"
  echo

  p4_title "Configuration:"
  p4_info "Config file: $(p4_highlight "$CONFIG_FILE")"
  p4_tip "Run 'p4e edit' to configure your projects"
}

# ==========================================
# PRE-FLIGHT
# ==========================================

# Check required tools are installed
function check_dependencies() {
  local missing_deps=()

  command -v yq  >/dev/null 2>&1 || missing_deps+=("yq")
  command -v fzf >/dev/null 2>&1 || missing_deps+=("fzf")

  if [ ${#missing_deps[@]} -gt 0 ]; then
    p4_error "Missing required dependencies: ${missing_deps[*]}"
    p4_tip "Please install missing tools and try again"
    exit 1
  fi
}

# Write a commented example config to CONFIG_FILE
function create_example_config() {
  mkdir -p "$(dirname "$CONFIG_FILE")"

  cat > "$CONFIG_FILE" << 'EOF'
# p4e Projects Configuration
# Each key maps a project name to its root directory. p4e expects an
# `ENV/` folder inside that path holding your profile templates:
#
#   <project>/
#   └── ENV/
#       ├── .env.dev      # profile templates you maintain
#       ├── .env.staging
#       ├── .env.prod
#       └── .env          # assembled active file (managed by p4e)
#
# `p4e switch <project>.<env>` assembles ENV/.env from the chosen template
# (plus a small metadata header), then sources it in the current tmux pane.
# `p4e link <project>` symlinks <project>/.env -> ENV/.env so your app finds it.

ats:
  path: ~/projects/ats

bot:
  path: ~/projects/bot
EOF

  p4_success "Created example config at: $CONFIG_FILE"
}

# Ensure a config exists; create an example one if it doesn't.
# Returns 1 when it had to create one, so callers can stop and let the user edit.
function check_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    p4_warn "Config file not found: $CONFIG_FILE"
    p4_step "Creating example configuration..."
    create_example_config
    p4_tip "Edit it to match your projects, then re-run."
    return 1
  fi
  return 0
}

# ==========================================
# CONFIG / FILESYSTEM HELPERS
# ==========================================

# List configured project names (excludes helper keys prefixed with `x-`)
function list_project_names() {
  yq eval 'keys | .[]' "$CONFIG_FILE" 2>/dev/null | grep -v '^x-' || true
}

# Resolve a project's root path: expand ~, strip trailing slash, verify it
# exists. Echoes the path on success; on failure emits a p4_error (stderr, so
# it's safe inside $()) and returns 1.
function resolve_project_path() {
  local project="$1" path
  path=$(yq eval -r ".${project}.path // \"\"" "$CONFIG_FILE" 2>/dev/null)

  if [ -z "$path" ] || [ "$path" = "null" ]; then
    p4_error "Project '$project' not found in configuration."
    return 1
  fi

  path="${path/#\~/$HOME}"   # expand leading tilde
  path="${path%/}"           # strip trailing slash

  if [ ! -d "$path" ]; then
    p4_error "Project directory not found: $path"
    return 1
  fi

  echo "$path"
}

# List a project's available profiles (short names, e.g. dev/staging/prod),
# one per line, given its ENV/ directory.
function list_env_profiles() {
  local env_dir="$1" file name
  for file in "$env_dir"/.env.*; do
    [ -e "$file" ] || continue          # nullglob-safe
    name="${file##*/}"                  # .env.dev
    name="${name#.env.}"                # dev
    [ -n "$name" ] && echo "$name"
  done
}

# Echo the profile currently assembled into ENV/.env (read from the metadata
# header p4e writes). Prints nothing if no active file / marker.
function get_active_profile() {
  local env_dir="$1" active="$1/$ACTIVE_ENV_FILE" source_line
  [ -f "$active" ] || return 0
  source_line=$(grep -m1 "^# p4e_source:" "$active" | cut -d':' -f2 | xargs)
  echo "${source_line#.env.}"
}

# fzf picker with the shared oshen theme; reads candidates on stdin.
function fzf_pick() {
  local header="$1"
  fzf --height=40% --reverse --header="$header" --color="$FZF_COLORS"
}

# ==========================================
# COMMANDS
# ==========================================

# Show the environment active in the current shell/pane
function show_active() {
  if [ -n "${P4E_CURRENT_ENV:-}" ]; then
    p4_info "Active environment: $(p4_highlight "$P4E_CURRENT_ENV")"
  else
    p4_warn "No environment active in this shell (P4E_CURRENT_ENV not set)"
    p4_tip "Run 'p4e switch <proj>.<env>' to activate one"
  fi
}

# List all configured projects with their profiles; mark the active profile.
function list_projects() {
  p4_header "Configured Projects"

  local projects
  projects=$(list_project_names)
  if [ -z "$projects" ]; then
    p4_warn "No projects configured"
    p4_tip "Run 'p4e edit' to add one"
    return 0
  fi

  local project
  while IFS= read -r project; do
    local raw_path path env_dir active profiles p
    raw_path=$(yq eval -r ".${project}.path // \"\"" "$CONFIG_FILE" 2>/dev/null)
    path="${raw_path/#\~/$HOME}"
    path="${path%/}"
    env_dir="$path/$ENV_DIR_NAME"

    p4_item "$project" "path: $path"

    if [ ! -d "$env_dir" ]; then
      p4_warn "  └─ no $ENV_DIR_NAME/ directory"
      continue
    fi

    profiles=$(list_env_profiles "$env_dir")
    if [ -z "$profiles" ]; then
      p4_info "  └─ no $ACTIVE_ENV_FILE.* profiles"
      continue
    fi

    active=$(get_active_profile "$env_dir")
    while IFS= read -r p; do
      if [ "$p" = "$active" ]; then
        p4_success "  ├─ $p (active)"
      else
        p4_info "  ├─ $p"
      fi
    done <<< "$profiles"
    echo "  └─"
  done <<< "$projects"
}

# Assemble ENV/.env from ENV/.env.<env> with a p4e metadata header. Skips the
# rewrite when this profile is already active and its template is unchanged.
function apply_profile() {
  local project="$1" env="$2" env_dir="$3"
  local source_path="$env_dir/.env.$env"
  local target="$env_dir/$ACTIVE_ENV_FILE"
  local active_profile
  active_profile=$(get_active_profile "$env_dir")

  # Same profile already active — rewrite only if the template drifted.
  if [ "$active_profile" = "$env" ] && [ -f "$target" ]; then
    if tail -n +$((HEADER_LINES + 1)) "$target" | cmp -s - "$source_path"; then
      p4_info "Already using $(p4_highlight "$env") (no changes detected)."
      return 0
    fi
    p4_warn "Template for $(p4_highlight "$env") changed — updating active environment."
  fi

  p4_step "Applying $(p4_highlight ".env.$env") -> $(p4_highlight "$target")"

  # Assemble atomically via a temp file. Keep the header exactly HEADER_LINES long.
  local tmp="$target.tmp"
  {
    echo "# p4e_project: $project"
    echo "# p4e_source: .env.$env"
    echo "export P4E_CURRENT_ENV=$project:$env"
    cat "$source_path"
  } > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$target"

  p4_success "Updated $target"
}

# Source the assembled env in the current pane and update the tmux status flag.
function activate_in_tmux() {
  local project="$1" env="$2" project_path="$3"
  local target="$project_path/$ENV_DIR_NAME/$ACTIVE_ENV_FILE"

  # The app expects .env in the project root — nudge if the symlink is missing.
  if [ ! -e "$project_path/$ACTIVE_ENV_FILE" ]; then
    p4_warn "No .env symlink in project root."
    p4_tip "Run '$(p4_highlight "p4e link $project")' so your app picks it up."
  fi

  if [ -n "${TMUX:-}" ]; then
    p4_step "Sourcing in current pane..."
    tmux send-keys -t "$TMUX_PANE" "source $target" Enter
    # Per-pane option consumed by scripts/tmux/p4e.sh for the status bar.
    tmux set-option -p -t "$TMUX_PANE" @p4e_env "$project:$env"
  else
    p4_warn "Not in tmux. Run 'source $target' to apply changes."
  fi
}

# Switch a project to a profile. Empty project/env fall back to interactive fzf.
function switch_environment() {
  local project="$1" env="$2"
  local project_path env_dir active

  # 1. Resolve the project
  if [ -z "$project" ]; then
    project=$(list_project_names | fzf_pick "Select Project") || true
    if [ -z "$project" ]; then
      p4_info "No project selected."
      return 0
    fi
  fi

  project_path=$(resolve_project_path "$project") || return 1
  env_dir="$project_path/$ENV_DIR_NAME"

  if [ ! -d "$env_dir" ]; then
    p4_error "$ENV_DIR_NAME directory not found: $env_dir"
    p4_tip "Create it and add .env.<name> profile templates."
    return 1
  fi

  # 2. Resolve the profile
  if [ -z "$env" ]; then
    active=$(get_active_profile "$env_dir")
    env=$(list_env_profiles "$env_dir" \
      | fzf_pick "Select Environment ($project) | active: ${active:-none}") || true
    if [ -z "$env" ]; then
      p4_info "Selection cancelled."
      return 0
    fi
  elif [ ! -f "$env_dir/.env.$env" ]; then
    p4_error "Environment '$env' not found in $env_dir"
    p4_tip "Available profiles:"
    list_env_profiles "$env_dir" | sed 's/^/  - /'
    return 1
  fi

  # 3. Assemble & 4. activate
  apply_profile "$project" "$env" "$env_dir"
  activate_in_tmux "$project" "$env" "$project_path"
}

# Parse the `switch` argument: <proj>.<env>, <proj> (interactive env),
# or nothing (fully interactive).
function switch_target() {
  local spec="${1:-}"
  local project="" env=""

  if [ -n "$spec" ]; then
    if [[ "$spec" == *.* ]]; then
      project="${spec%.*}"
      env="${spec##*.}"
      if [ -z "$project" ] || [ -z "$env" ]; then
        p4_error "Invalid format: '$spec'. Use <project>.<env> (e.g. ats.dev)"
        return 1
      fi
    else
      project="$spec"   # project only -> pick the profile interactively
    fi
  fi

  switch_environment "$project" "$env"
}

# Create (or update) the project-root .env symlink -> ENV/.env
function link_project() {
  local project="$1" project_path target current_link

  if [ -z "$project" ]; then
    project=$(list_project_names | fzf_pick "Select Project to Link") || true
    if [ -z "$project" ]; then
      p4_info "No project selected."
      return 0
    fi
  fi

  project_path=$(resolve_project_path "$project") || return 1
  target="$project_path/$ACTIVE_ENV_FILE"

  if [ -L "$target" ]; then
    current_link=$(readlink "$target")
    if [ "$current_link" = "$LINK_TARGET" ]; then
      p4_success "Symlink already correct for $project."
      return 0
    fi
    p4_warn "Symlink exists but points to: $current_link"
    p4_confirm "Update it to $LINK_TARGET?" || return 0
  elif [ -f "$target" ]; then
    p4_warn "A regular .env file exists at $target"
    p4_confirm "Back up and replace it with a symlink?" || return 0
    mv "$target" "$target.bak.$(date +%s)"
    p4_success "Backed up original .env"
  fi

  mkdir -p "$project_path/$ENV_DIR_NAME"
  ln -sf "$LINK_TARGET" "$target"
  p4_success "Linked $ACTIVE_ENV_FILE -> $LINK_TARGET in $project_path"
}

# Edit the configuration file (creating an example first if missing)
function edit_config() {
  [ -f "$CONFIG_FILE" ] || create_example_config

  local editor="${EDITOR:-nvim}"
  command -v "$editor" >/dev/null 2>&1 || editor="vi"

  p4_info "Opening config with: $editor"
  "$editor" "$CONFIG_FILE"
}

# ==========================================
# DISPATCH
# ==========================================

function parse_args() {
  # Consume global options (must precede the command)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -c|--config)
        [ -z "${2:-}" ] && p4_die "Option '$1' requires an argument."
        CONFIG_FILE="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        p4_error "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done

  local command="${1:-}"
  [ $# -gt 0 ] && shift

  case "$command" in
    "")
      show_active
      ;;
    help)
      show_help
      ;;
    edit|e)
      edit_config
      ;;
    s|switch)
      check_config || exit 1
      switch_target "${1:-}"
      ;;
    link)
      check_config || exit 1
      link_project "${1:-}"
      ;;
    list|ls)
      check_config || exit 1
      list_projects
      ;;
    *)
      p4_error "Unknown command: $command"
      show_help
      exit 1
      ;;
  esac
}

function main() {
  check_dependencies
  parse_args "$@"
}

main "$@"
