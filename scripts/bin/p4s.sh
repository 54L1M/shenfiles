#!/usr/bin/env bash
set -euo pipefail

# p4s - A generalized git repository synchronizer

# Source helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"
source "$SCRIPT_DIR/../lib/utils/utils.sh"

# Default configuration
CONFIG_FILE="$HOME/.config/p4/p4s.yaml"

# Display help message
show_help() {
  p4_header "p4s - Git Repository Synchronizer"
  p4_info "Usage: p4s [profile] [options]"
  echo
  p4_title "Description:"
  p4_example  "This script creates a separate commit for each changed file and pushes"
  p4_example   "to the remote repository for a specified git directory."
  echo
  p4_title "Modes:"
  p4_cmd "p4s" "" "Run in interactive mode, using fzf to select a profile."
  p4_cmd "p4s" "<profile>" "Run for a specific profile defined in the config file."
  p4_cmd "p4s" "-d <path>" "Run for a specific directory path."
  echo
  p4_title "Options:"
  p4_cmd "-m, --message" "<template>" "Use a custom commit message template. Use '\$file_name'."
  p4_cmd "-d, --dir" "<path>" "Specify the repository path directly."
  p4_cmd "-c, --config" "<file>" "Use an alternative config file."
  p4_cmd "-h, --help" "" "Show this help message."
  echo
  p4_title "Templating:"
  p4_info "Commit messages can be templated using the '\$file_name' variable."
  p4_example "p4s dotfiles -m \"feat(dotfiles): update \$file_name\""
  p4_info "If no template is provided, a default (e.g., 'Update <filename>') is used."
  echo
  p4_title "Configuration:"
  p4_info "Config file is located at: $(p4_highlight "$CONFIG_FILE")"
}

# Check dependencies
check_dependencies() {
  local missing_deps=()
  command -v yq >/dev/null 2>&1 || missing_deps+=("yq")
  command -v fzf >/dev/null 2>&1 || missing_deps+=("fzf")
  if [ ${#missing_deps[@]} -gt 0 ]; then
    p4_error "Missing required dependencies: ${missing_deps[*]}"
    p4_tip "Please install them to continue."
    exit 1
  fi
}

# The main sync logic
run_sync() {
  local repo_path="$1"
  local message_template="$2" # This can be empty

  # Expand tilde
  repo_path="${repo_path/#\~/$HOME}"

  p4_step "Syncing repository: $(p4_highlight "$repo_path")"

  # Validate path
  if [ ! -d "$repo_path" ]; then
    p4_error "Directory not found: $repo_path"
    exit 1
  fi

  cd "$repo_path"

  # Validate git repository
  if ! git_is_repo; then
    p4_error "Not a git repository: $repo_path"
    exit 1
  fi

  # Check for changes
  p4_info "Checking for local changes..."
  local changes
  changes=$(git status --porcelain)

  if [ -z "$changes" ]; then
    p4_success "Repository is clean. Nothing to sync."
    # Optional: also check if local is behind remote
    p4_info "Checking remote status..."
    git fetch origin
    if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
        p4_success "Local branch is up-to-date with remote."
    else
        p4_warn "Local branch is not in sync with remote. Consider pulling."
    fi
    exit 0
  fi
  
  # Fetch from remote
  p4_step "Fetching from remote..."
  git fetch origin

  # Per-file commit logic
  p4_step "Committing changes file-by-file..."
  while IFS= read -r line; do
    local status
    local file
    local commit_message
    
    status=${line:0:2}
    file=${line:3}
    
    # Determine action and stage file
    local action
    case "$status" in
      " M" | " M") action="Update"; git add "$file" ;;
      "A " | "A ") action="Add"; git add "$file" ;;
      " D" | "D ") action="Remove"; git rm "$file" ;;
      "??" ) action="Add"; git add "$file" ;;
      * ) p4_warn "Skipping unhandled status '$status' for file '$file'"; continue ;;
    esac

    # Generate commit message
    if [ -n "$message_template" ]; then
        commit_message="${message_template//\$file_name/$file}"
    else
        commit_message="$action $file"
    fi
    
    p4_info "Committing: $(p4_highlight "$commit_message")"
    git commit -m "$commit_message"
  done <<< "$changes"

  p4_step "Pushing changes to remote..."
  git push origin "$(git_current_branch)"

  p4_success "Successfully synced repository!"
}

main() {
  check_dependencies

  local repo_path=""
  local message_template=""
  local profile_name=""

  # Argument parsing
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      -m|--message)
        message_template="$2"
        shift 2
        ;;
      -d|--dir)
        repo_path="$2"
        shift 2
        ;;
      -c|--config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      -*)
        p4_error "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        # Positional argument is the profile name
        if [ -z "$profile_name" ]; then
            profile_name="$1"
        else
            p4_error "Too many arguments. Expected a single profile name."
            show_help
            exit 1
        fi
        shift
        ;;
    esac
  done

  # --- Determine repository path ---
  if [ -n "$repo_path" ]; then
    # Path was given with -d, do nothing
    p4_info "Using manual directory: $(p4_highlight "$repo_path")"
  elif [ -n "$profile_name" ]; then
    # Profile name was given
    p4_info "Using profile: $(p4_highlight "$profile_name")"
    repo_path=$(yq eval ".${profile_name}.path" "$CONFIG_FILE" 2>/dev/null)
    if [ -z "$repo_path" ] || [ "$repo_path" == "null" ]; then
        p4_error "Profile '$profile_name' not found in $CONFIG_FILE"
        exit 1
    fi
  else
    # Interactive mode
    if [ ! -f "$CONFIG_FILE" ]; then
        p4_error "Config file not found for interactive mode: $CONFIG_FILE"
        p4_tip "Create the config file or use the -d flag."
        exit 1
    fi
    p4_info "Running in interactive mode..."
    profile_name=$(yq eval 'keys | .[]' "$CONFIG_FILE" | fzf --height=20% --reverse --header="Select a Sync Profile")
    if [ -z "$profile_name" ]; then
        p4_info "No profile selected. Exiting."
        exit 0
    fi
    repo_path=$(yq eval ".${profile_name}.path" "$CONFIG_FILE")
  fi

  # --- Determine commit message template ---
  if [ -z "$message_template" ] && [ -n "$profile_name" ]; then
    # No -m flag, check config if a profile was used
    message_template=$(yq eval ".${profile_name}.template // \"\"" "$CONFIG_FILE")
  fi
  
  # Run the main logic
  run_sync "$repo_path" "$message_template"
}

main "$@"

