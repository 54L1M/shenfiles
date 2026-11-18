#!/usr/bin/env bash
# P4_DESC: Git synchronizer — per-file commits with message templates
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
  p4_example  "Pulls remote changes, creates a separate commit for each changed file,"
  p4_example   "and pushes to the remote repository for a specified git directory."
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

# Bring in remote commits before committing local work. Uncommitted edits are
# stashed around the rebase (autostash), so a dirty tree is fine.
pull_remote() {
  if ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    p4_warn "No upstream branch; skipping pull."
    return 0
  fi

  if [ "$(git rev-list --count 'HEAD..@{u}')" -eq 0 ]; then
    p4_success "Already up to date with remote."
    return 0
  fi

  p4_step "Pulling remote changes..."
  if ! git rebase --autostash '@{u}'; then
    # Unpushed local commits clash with the remote: go back to where we were.
    if [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
      git rebase --abort || true
    fi
    p4_error "Pull failed; nothing was changed. Resolve by hand in $(pwd)"
    exit 1
  fi

  # The pull worked but re-applying the uncommitted edits did not.
  local conflicted
  conflicted=$(git diff --name-only --diff-filter=U)
  if [ -n "$conflicted" ]; then
    p4_error "Your uncommitted edits conflict with pulled changes in:"
    echo "$conflicted"
    p4_tip "Fix the conflict markers, then run p4s again. The original edits are also in 'git stash list'."
    exit 1
  fi
}

# The main sync logic: pull, commit each changed file, push
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

  p4_step "Fetching from remote..."
  git fetch origin

  pull_remote

  # Check for changes
  p4_info "Checking for local changes..."
  local changes
  changes=$(git status --porcelain)

  if [ -z "$changes" ]; then
    p4_success "No local changes to commit."
  else
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
        " M") action="Update"; git add "$file" ;;
        "A ") action="Add"; git add "$file" ;;
        " D" | "D ") action="Remove"; git rm "$file" ;;
        "??") action="Add"; git add "$file" ;;
        *) p4_warn "Skipping unhandled status '$status' for file '$file'"; continue ;;
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
  fi

  # Push only when there is something the remote does not have
  if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1 \
     && [ "$(git rev-list --count '@{u}..HEAD')" -eq 0 ]; then
    p4_success "Nothing to push."
  else
    p4_step "Pushing changes to remote..."
    git push origin "$(git_current_branch)"
  fi

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

  # --- Determine submodules ---
  local submodules=()
  if [ -n "$profile_name" ] && [ -f "$CONFIG_FILE" ]; then
    # Read the submodules array line-by-line, ignoring null outputs or missing keys
    while IFS= read -r sub; do
        if [ -n "$sub" ] && [ "$sub" != "null" ]; then
            submodules+=("$sub")
        fi
    done < <(yq eval ".${profile_name}.submodules[]" "$CONFIG_FILE" 2>/dev/null || true)
  fi

  # --- Execute Sync for Submodules First ---
  for sub in "${submodules[@]}"; do
    echo ""
    p4_info "--- Syncing Submodule: $sub ---"
    
    local expanded_base="${repo_path/#\~/$HOME}"
    local sub_path="$expanded_base/$sub"
    
    # Run in a subshell `(...)` so the directory changes and `exit 0`
    # inside run_sync don't prematurely terminate the whole script.
    if ! ( run_sync "$sub_path" "$message_template" ); then
        p4_error "Failed to sync submodule: $sub"
        exit 1
    fi
  done

  # --- Execute Sync for Main Repository ---
  if [ ${#submodules[@]} -gt 0 ]; then
    echo ""
    p4_info "--- Syncing Main Repository ---"
  fi

  # Run main repo logic in a subshell as well to maintain consistency
  ( run_sync "$repo_path" "$message_template" )
}

main "$@"
