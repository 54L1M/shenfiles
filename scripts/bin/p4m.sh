#!/usr/bin/env bash
# p4m - Development Environment Setup Script
# P4_DESC: Session manager — create custom tmux dev layouts from YAML config
# Author: PF4
# Usage: p4m <session_name> [options]

set -e

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$BASE_DIR/lib"

# Source the color utilities
source "$LIB_DIR/colors/colors.sh"

# Configuration
CONFIG_FILE="$HOME/.config/p4/p4m.yaml"

# Display help message
function show_help() {
  p4_header "p4m - Development Environment Manager"
  p4_info "Usage: p4m <session_name> [options]"
  echo

  p4_title "Commands:"
  p4_cmd "p4m" "<session_name>" "Create and attach to development session"
  p4_cmd "p4m" "list | ls" "List all configured sessions"
  p4_cmd "p4m" "sessions | s" "Show available sessions from config"
  p4_cmd "p4m" "edit | e" "Edit the configuration file"
  p4_cmd "p4m" "help" "Show this help message"
  echo

  p4_title "Options:"
  p4_cmd "-h, --help" "" "Show help message"
  p4_cmd "-c, --config" "<file>" "Use alternative config file"
  p4_cmd "-k, --kill" "" "Kill session instead of attaching"
  echo

  p4_title "Examples:"
  p4_example "p4m mapper" "Start the 'mapper' development session"
  p4_example "p4m list" "List all active tmux sessions"
  p4_example "p4m sessions" "Show configured sessions"
  p4_example "p4m -k mapper" "Kill the 'mapper' session"
  echo

  p4_title "Configuration:"
  p4_info "Config file: $(p4_highlight "$CONFIG_FILE")"
  p4_tip "Run 'p4m edit' to configure your sessions"
}

# Check dependencies
function check_dependencies() {
  local missing_deps=()

  if ! command -v tmux >/dev/null 2>&1; then
    missing_deps+=("tmux")
  fi

  if ! command -v yq >/dev/null 2>&1; then
    missing_deps+=("yq")
  fi

  if [ ${#missing_deps[@]} -gt 0 ]; then
    p4_error "Missing required dependencies: ${missing_deps[*]}"
    p4_tip "Please install missing tools and try again"
    exit 1
  fi
}

# Check if config file exists
function check_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    p4_error "Config file not found: $CONFIG_FILE"
    p4_step "Creating example configuration..."
    
    # Create config directory
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Create example config
    cat > "$CONFIG_FILE" << 'EOF'
# p4m Sessions Configuration
# Each session defines a development environment.
#
# Per-session keys:
#   path            (required) Working directory
#   env_file        (optional) Environment file to source in every window
#   virtualenv      (optional) Python virtualenv to `workon`
#   proxy           (optional) Cloud SQL proxy profile to auto-start (p4p)
#   global_commands (optional) Commands run in EVERY window
#   windows         (required) Ordered list of windows to create
#
# Each window entry:
#   name            (required) tmux window name
#   editor          (optional) If true, opens `nvim .` after commands
#   commands        (optional) Commands run only in this window
#
# Tip: reuse a layout with a YAML anchor (keys starting with `x-` are ignored).

x-layouts:
  full: &full
    - { name: code, editor: true }
    - { name: shell }
    - { name: server }
    - { name: db }

mapper:
  virtualenv: mapper_env             # Optional: Python virtual environment
  path: ~/projects/mapper            # Required: Working directory
  env_file: ~/projects/mapper/.env   # Optional: Environment file to source
  global_commands:                   # Commands that run on ALL windows
    - "echo 'Setting up mapper project...'"
    - "export PROJECT_NAME=mapper"
  windows:
    - name: code
      editor: true
      commands:
        - "git status"
    - name: shell
      commands:
        - "npm install"
    - name: server
      commands:
        - "npm run dev"
    - name: db
      commands:
        - "docker-compose up -d postgres"

# Reuse a shared layout via anchor
dayjob:
  virtualenv: work_env
  path: ~/work/current-project
  env_file: ~/work/current-project/.env.local
  windows: *full

# Minimal example - path + a single window
quickstart:
  path: ~/scratch
  windows:
    - name: code
      editor: true
EOF

    p4_success "Created example config at: $CONFIG_FILE"
    p4_tip "Edit the config to match your projects"
    return 1
  fi
  return 0
}

# Get session configuration using yq
function get_session_config() {
  local session_name="$1"
  local key="$2"
  
  if ! yq eval ".${session_name}.${key} // \"\"" "$CONFIG_FILE" 2>/dev/null; then
    echo ""
  fi
}

# Get global commands as array
function get_global_commands() {
  local session_name="$1"

  # Get global_commands as JSON array, then convert to bash array
  yq eval "explode(.) | .${session_name}.global_commands // []" "$CONFIG_FILE" 2>/dev/null | yq eval '.[]' 2>/dev/null
}

# Get the number of windows configured for a session
function get_window_count() {
  local session_name="$1"
  local count
  # explode(.) resolves YAML anchors/aliases so `length` sees the real list
  count=$(yq eval "explode(.) | (.${session_name}.windows // []) | length" "$CONFIG_FILE" 2>/dev/null)
  # Guard against null/empty output under `set -e`
  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
    count=0
  fi
  echo "$count"
}

# Get a window's name by list index
function get_window_name() {
  local session_name="$1"
  local window_index="$2"

  yq eval ".${session_name}.windows[${window_index}].name // \"\"" "$CONFIG_FILE" 2>/dev/null
}

# Get a window's editor flag by list index (true/false)
function get_window_editor() {
  local session_name="$1"
  local window_index="$2"

  yq eval ".${session_name}.windows[${window_index}].editor // false" "$CONFIG_FILE" 2>/dev/null
}

# Get window-specific commands by list index
function get_window_commands() {
  local session_name="$1"
  local window_index="$2"

  # Get window-specific commands by index into the windows list
  # explode(.) resolves anchors so commands defined in a shared layout still emit
  yq eval "explode(.) | .${session_name}.windows[${window_index}].commands // []" "$CONFIG_FILE" 2>/dev/null | yq eval '.[]' 2>/dev/null
}

# List configured session names (excludes helper keys prefixed with `x-`)
function list_session_names() {
  yq eval 'keys | .[]' "$CONFIG_FILE" 2>/dev/null | grep -v '^x-'
}

# Check if session exists in config
function session_exists_in_config() {
  local session_name="$1"
  
  yq eval "has(\"$session_name\")" "$CONFIG_FILE" 2>/dev/null | grep -q "true"
}

# List available sessions from config
function list_available_sessions() {
  p4_header "Available Sessions"
  
  if [ ! -f "$CONFIG_FILE" ]; then
    p4_warn "No configuration file found"
    p4_tip "Run 'p4m edit' to create one"
    return 1
  fi

  local sessions
  sessions=$(list_session_names)

  if [ -z "$sessions" ]; then
    p4_warn "No sessions configured"
    return 1
  fi

  while IFS= read -r session; do
    local venv path env_file global_commands_count window_count
    venv=$(get_session_config "$session" "virtualenv")
    path=$(get_session_config "$session" "path")
    env_file=$(get_session_config "$session" "env_file")
    global_commands_count=$(yq eval "explode(.) | (.${session}.global_commands // []) | length" "$CONFIG_FILE" 2>/dev/null || echo "0")
    window_count=$(get_window_count "$session")

    # Expand tilde in path for display
    path="${path/#\~/$HOME}"

    p4_item "$session" "path: $path"
    if [ -n "$venv" ]; then
      p4_info "  ├─ venv: $venv"
    fi
    if [ -n "$env_file" ]; then
      p4_info "  ├─ env: $env_file"
    fi
    if [ "$global_commands_count" != "0" ] && [ "$global_commands_count" != "null" ]; then
      p4_info "  ├─ global commands: $global_commands_count commands"
    fi

    # Show configured windows
    local window_index
    for ((window_index = 0; window_index < window_count; window_index++)); do
      local window_name window_commands_count
      window_name=$(get_window_name "$session" "$window_index")
      [ -z "$window_name" ] && window_name="window$window_index"
      window_commands_count=$(yq eval "explode(.) | (.${session}.windows[${window_index}].commands // []) | length" "$CONFIG_FILE" 2>/dev/null || echo "0")
      if [ "$window_commands_count" != "0" ] && [ "$window_commands_count" != "null" ]; then
        p4_info "  ├─ $window_name ($window_index): $window_commands_count commands"
      else
        p4_info "  ├─ $window_name ($window_index)"
      fi
    done

    echo "  └─"
  done <<< "$sessions"
}

# List active tmux sessions
function list_active_sessions() {
  p4_header "Active Tmux Sessions"

  if tmux list-sessions 2>/dev/null; then
    echo
  else
    p4_warn "No active tmux sessions"
  fi
}

# Setup window with environment
function setup_window() {
  local session_name="$1"
  local window_name="$2"
  local venv_name="$3"
  local env_file="$4"
  
  # Only activate virtualenv if specified
  if [ -n "$venv_name" ]; then
    tmux send-keys -t "$session_name:$window_name" "workon $venv_name" Enter
  fi
  
  # Source environment file if specified and exists
  if [ -n "$env_file" ] && [ -f "$env_file" ]; then
    tmux send-keys -t "$session_name:$window_name" "source $env_file" Enter
  else
    p4_debug "Env file not found or not specified: $env_file"
  fi
}

# Execute global commands in a window
function execute_global_commands() {
  local session_name="$1"
  local window_name="$2"
  
  # Get global commands for this session
  local commands
  mapfile -t commands < <(get_global_commands "$session_name")
  
  if [ ${#commands[@]} -gt 0 ]; then
    p4_debug "Executing ${#commands[@]} global commands in $window_name window..."
    
    for command in "${commands[@]}"; do
      if [ -n "$command" ] && [ "$command" != "null" ]; then
        p4_debug "Executing global: $command"
        tmux send-keys -t "$session_name:$window_name" "$command" Enter
        # Add a small delay between commands to ensure they complete
        sleep 0.5
      fi
    done
  fi
}

# Execute window-specific commands by index
function execute_window_commands() {
  local session_name="$1"
  local window_name="$2"
  local window_index="$3"
  
  # Get window-specific commands
  local commands
  mapfile -t commands < <(get_window_commands "$session_name" "$window_index")
  
  if [ ${#commands[@]} -gt 0 ]; then
    p4_debug "Executing ${#commands[@]} window-specific commands in $window_name ($window_index) window..."
    
    for command in "${commands[@]}"; do
      if [ -n "$command" ] && [ "$command" != "null" ]; then
        p4_debug "Executing window-specific: $command"
        tmux send-keys -t "$session_name:$window_name" "$command" Enter
        # Add a small delay between commands to ensure they complete
        sleep 0.5
      fi
    done
  fi
}

# Setup a complete window with all commands
function setup_complete_window() {
  local session_name="$1"
  local window_name="$2"
  local window_index="$3"
  local venv_name="$4"
  local env_file="$5"
  local open_editor="${6:-false}"
  
  p4_debug "Setting up $window_name window (index: $window_index)..."
  
  # Basic environment setup
  setup_window "$session_name" "$window_name" "$venv_name" "$env_file"
  
  # Clear 
  tmux send-keys -t "$session_name:$window_name" "clear" Enter

  # Execute global commands
  execute_global_commands "$session_name" "$window_name"
  
  # Execute window-specific commands
  execute_window_commands "$session_name" "$window_name" "$window_index"
  
  # Open editor if this is the code window
  if [ "$open_editor" = "true" ]; then
    tmux send-keys -t "$session_name:$window_name" "nvim ." Enter
  fi
}

# Create development session
function create_session() {
  local session_name="$1"
  
  # Check if session already exists
  if tmux has-session -t "$session_name" 2>/dev/null; then
    p4_info "Session '$(p4_highlight "$session_name")' already exists. Attaching..."
    attach_to_session "$session_name"
    return 0
  fi

  # Check if session exists in config
  if ! session_exists_in_config "$session_name"; then
    p4_error "Session '$session_name' not found in configuration"
    p4_tip "Available sessions:"
    list_session_names | sed 's/^/  - /'
    return 1
  fi

  # Get session configuration
  local venv_name project_path env_file proxy_profile
  venv_name=$(get_session_config "$session_name" "virtualenv")
  project_path=$(get_session_config "$session_name" "path")
  env_file=$(get_session_config "$session_name" "env_file")
  proxy_profile=$(get_session_config "$session_name" "proxy")

  # Validate required fields (only path is required now)
  if [ -z "$project_path" ]; then
    p4_error "Session '$session_name' missing required field: path"
    return 1
  fi

  # Expand tilde in paths
  project_path="${project_path/#\~/$HOME}"
  if [ -n "$env_file" ]; then
    env_file="${env_file/#\~/$HOME}"
  fi

  # Validate project path
  if [ ! -d "$project_path" ]; then
    p4_error "Project path does not exist: $project_path"
    return 1
  fi

  # Resolve the window layout from config
  local window_count
  window_count=$(get_window_count "$session_name")
  if [ "$window_count" -eq 0 ]; then
    p4_error "Session '$session_name' defines no windows"
    p4_tip "Add a 'windows:' list to the session config"
    return 1
  fi

  # Create session
  p4_step "Creating session '$(p4_highlight "$session_name")'"
  if [ -n "$venv_name" ]; then
    p4_info "Virtualenv: $venv_name"
  else
    p4_info "Virtualenv: None (using system Python)"
  fi
  p4_info "Path: $project_path"
  if [ -n "$env_file" ]; then
    p4_info "Env file: $env_file"
  fi
  p4_info "Windows: $window_count"

  # Create windows from config (first via new-session, rest via new-window)
  local window_index first_window=""
  for ((window_index = 0; window_index < window_count; window_index++)); do
    local window_name open_editor
    window_name=$(get_window_name "$session_name" "$window_index")
    if [ -z "$window_name" ] || [ "$window_name" = "null" ]; then
      window_name="window$window_index"
    fi
    open_editor=$(get_window_editor "$session_name" "$window_index")

    if [ "$window_index" -eq 0 ]; then
      tmux new-session -d -s "$session_name" -n "$window_name" -c "$project_path"
      first_window="$window_name"
    else
      tmux new-window -t "$session_name" -n "$window_name" -c "$project_path"
    fi

    setup_complete_window "$session_name" "$window_name" "$window_index" "$venv_name" "$env_file" "$open_editor"
  done

  # Switch back to the first window.
  # Note: a plugin hook (after-select-window -> refresh-client -S) fails with
  # "no current client" when the session is still detached, which under `set -e`
  # would abort before we ever attach. Swallow it — selecting is best-effort here.
  tmux select-window -t "$session_name:$first_window" 2>/dev/null || true

  # Auto-start Cloud SQL proxy if configured
  if [[ -n "$proxy_profile" ]]; then
    local p4p_script="$SCRIPT_DIR/p4p.sh"
    if [[ -x "$p4p_script" ]]; then
      p4_step "Starting Cloud SQL proxy: $proxy_profile"
      "$p4p_script" start "$proxy_profile" >/dev/null 2>&1 || p4_warn "Could not start proxy: $proxy_profile"
    fi
  fi

  p4_success "Session created successfully!"

  # Attach to session
  attach_to_session "$session_name"
}

# Attach to session
function attach_to_session() {
  local session_name="$1"
  
  p4_step "Attaching to session '$(p4_highlight "$session_name")'..."
  
  if [ -z "$TMUX" ]; then
    tmux attach-session -t "$session_name"
  else
    tmux switch-client -t "$session_name"
  fi
}

# Kill session
function kill_session() {
  local session_name="$1"

  # Check if session exists
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    p4_error "Session '$session_name' does not exist"
    return 1
  fi

  # Ask for confirmation
  p4_warn "Kill session '$(p4_highlight "$session_name")'? [y/N] "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    p4_info "Operation cancelled"
    return 0
  fi

  # Kill the session
  tmux kill-session -t "$session_name"
  p4_success "Session '$(p4_highlight "$session_name")' killed"
}

# Edit configuration file
function edit_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    p4_step "Creating config directory..."
    mkdir -p "$(dirname "$CONFIG_FILE")"
  fi

  # Use user's preferred editor
  local editor="${EDITOR:-nvim}"
  if ! command -v "$editor" >/dev/null 2>&1; then
    editor="vi"
  fi

  p4_info "Opening config with: $editor"
  "$editor" "$CONFIG_FILE"
}

# Parse command line arguments
function parse_args() {
  local kill_mode=false
  local command=""
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      -c|--config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      -k|--kill)
        kill_mode=true
        shift
        ;;
      list|ls)
        command="list"
        shift
        ;;
      sessions|s)
        command="sessions"  
        shift
        ;;
      edit|e)
        command="edit"
        shift
        ;;
      help)
        command="help"
        shift
        ;;
      -*)
        p4_error "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        if [ -z "$command" ]; then
          command="create"
          SESSION_NAME="$1"
        fi
        shift
        ;;
    esac
  done

  # Execute command
  case "$command" in
    create)
      if [ -z "$SESSION_NAME" ]; then
        p4_error "Session name required"
        show_help
        exit 1
      fi
      
      if [ "$kill_mode" = true ]; then
        kill_session "$SESSION_NAME"
      else
        create_session "$SESSION_NAME"
      fi
      ;;
    list)
      list_active_sessions
      ;;
    sessions)
      list_available_sessions
      ;;
    edit)
      edit_config
      ;;
    help|"")
      show_help
      ;;
    *)
      p4_error "Unknown command: $command"
      show_help
      exit 1
      ;;
  esac
}

# Main function
function main() {
  # Check dependencies first
  check_dependencies

  # If no arguments, show help
  if [ $# -eq 0 ]; then
    show_help
    exit 0
  fi

  # Check/create config (except for help commands)
  if [[ "$1" != "help" && "$1" != "-h" && "$1" != "--help" ]]; then
    if ! check_config; then
      exit 1
    fi
  fi

  # Parse arguments and execute
  parse_args "$@"
}

# Run main function with all arguments
main "$@"
