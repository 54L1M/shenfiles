#!/usr/bin/env bash
# p4m - Development Environment Setup Script  
# Author: P4ndaF4ce
# Usage: p4m <session_name> [options]

set -e

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$BASE_DIR/lib"

# Source the color utilities
source "$LIB_DIR/colors/colors.sh"

# Configuration
CONFIG_FILE="$HOME/.config/p4m/sessions.yaml"

# Window mapping
declare -A WINDOW_NAMES=(
  [0]="code"
  [1]="shell"
  [2]="server"
  [3]="db"
)

# Display help message
function show_help() {
  p4_header "p4m - Development Environment Manager"
  p4_info "Usage: p4m <session_name> [options]"
  echo

  p4_title "Commands:"
  p4_cmd "p4m" "<session_name>" "Create and attach to development session"
  p4_cmd "p4m" "list" "List all configured sessions"
  p4_cmd "p4m" "sessions" "Show available sessions from config"
  p4_cmd "p4m" "edit" "Edit the configuration file"
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
# Each session defines a development environment
# Windows: 0=code, 1=shell, 2=server, 3=db

mapper:
  virtualenv: mapper_env      # Optional: Python virtual environment
  path: ~/projects/mapper     # Required: Working directory
  env_file: ~/projects/mapper/.env  # Optional: Environment file to source
  commands:
    global_commands:          # Commands that run on ALL windows
      - "echo 'Setting up mapper project...'"
      - "export PROJECT_NAME=mapper"
    0:                        # Code window (window 0)
      - "echo 'Code window ready'"
      - "git status"
    1:                        # Shell window (window 1)  
      - "npm install"
      - "echo 'Mapper setup complete!'"
    2:                        # Server window (window 2)
      - "echo 'Server window ready'"
      - "npm run dev"
    3:                        # DB window (window 3)
      - "echo 'Database window ready'"
      - "docker-compose up -d postgres"

dayjob:
  virtualenv: work_env
  path: ~/work/current-project
  env_file: ~/work/current-project/.env.local
  commands:
    global_commands:
      - "echo 'Initializing work environment...'"
      - "export WORK_MODE=development"
    0:                        # Code window
      - "git fetch origin"
      - "git status"
    1:                        # Shell window
      - "composer install"
      - "php artisan migrate:status"
    2:                        # Server window
      - "php artisan serve"

learning:
  path: ~/learning/current-topic
  commands:
    global_commands:
      - "echo 'Learning environment ready!'"
    0:                        # Code window
      - "git log --oneline -5"

# Minimal example - just path required
quickstart:
  path: ~/scratch
  commands:
    global_commands:
      - "echo 'Quick start environment loaded'"
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
  yq eval ".${session_name}.commands.global_commands // []" "$CONFIG_FILE" 2>/dev/null | yq eval '.[]' 2>/dev/null
}

# Get window-specific commands by index
function get_window_commands() {
  local session_name="$1"
  local window_index="$2"
  
  # Get window-specific commands by index
  yq eval ".${session_name}.commands.${window_index} // []" "$CONFIG_FILE" 2>/dev/null | yq eval '.[]' 2>/dev/null
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
  sessions=$(yq eval 'keys | .[]' "$CONFIG_FILE" 2>/dev/null)
  
  if [ -z "$sessions" ]; then
    p4_warn "No sessions configured"
    return 1
  fi

  while IFS= read -r session; do
    local venv path env_file global_commands_count
    venv=$(get_session_config "$session" "virtualenv")
    path=$(get_session_config "$session" "path")
    env_file=$(get_session_config "$session" "env_file")
    global_commands_count=$(yq eval ".${session}.commands.global_commands | length" "$CONFIG_FILE" 2>/dev/null || echo "0")
    
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
    
    # Show window-specific commands
    for window_index in "${!WINDOW_NAMES[@]}"; do
      local window_name="${WINDOW_NAMES[$window_index]}"
      local window_commands_count
      window_commands_count=$(yq eval ".${session}.commands.${window_index} | length" "$CONFIG_FILE" 2>/dev/null || echo "0")
      if [ "$window_commands_count" != "0" ] && [ "$window_commands_count" != "null" ]; then
        p4_info "  ├─ $window_name ($window_index): $window_commands_count commands"
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
    yq eval 'keys | .[]' "$CONFIG_FILE" 2>/dev/null | sed 's/^/  - /'
    return 1
  fi

  # Get session configuration
  local venv_name project_path env_file
  venv_name=$(get_session_config "$session_name" "virtualenv")
  project_path=$(get_session_config "$session_name" "path")
  env_file=$(get_session_config "$session_name" "env_file")

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

  # Create session and first window (code - index 0)
  tmux new-session -d -s "$session_name" -n "code" -c "$project_path"

  # Setup code window (with editor opening after commands)
  setup_complete_window "$session_name" "code" "0" "$venv_name" "$env_file" "true"

  # Create and setup other windows
  tmux new-window -t "$session_name" -n "shell" -c "$project_path"
  setup_complete_window "$session_name" "shell" "1" "$venv_name" "$env_file"

  tmux new-window -t "$session_name" -n "server" -c "$project_path"
  setup_complete_window "$session_name" "server" "2" "$venv_name" "$env_file"

  tmux new-window -t "$session_name" -n "db" -c "$project_path"
  setup_complete_window "$session_name" "db" "3" "$venv_name" "$env_file"

  # Switch back to code window
  tmux select-window -t "$session_name:code"

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
      list)
        command="list"
        shift
        ;;
      sessions)
        command="sessions"  
        shift
        ;;
      edit)
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
