#!/usr/bin/env bash
# P4ndaMux - Tmux session manager with colorful output
# Usage: p4m [create|list|attach|kill] [session_name] [layout_name]

set -e

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LIB_DIR="$BASE_DIR/lib"
source "$LIB_DIR/colors/colors.sh"
source "$LIB_DIR/tmux/tmux_helpers.sh"
source "$LIB_DIR/tmux/tmux_layouts.sh"

# Display help message
function show_help() {
  p4_header "P4ndaMux Session Manager"
  p4_info "Usage: p4m [command] [session_name] [layout_name]"
  echo

  p4_title "Commands:"
  p4_cmd "create" "[session_name] [layout_name]" "Create a new tmux session with specified layout"
  p4_cmd "list" "" "List all available tmux sessions"
  p4_cmd "attach" "[session_name]" "Attach to an existing tmux session"
  p4_cmd "kill" "[session_name]" "Kill a tmux session"
  p4_cmd "layouts" "" "List available layouts"
  p4_cmd "help" "" "Show this help message"
  echo

  p4_title "Examples:"
  p4_example "p4m create dev python" "Create a new 'dev' session with 'python' layout"
  p4_example "p4m attach dev" "Attach to the 'dev' session"
  p4_example "p4m list" "List all sessions"
  p4_example "p4m layouts" "Show available layout templates"
}

# List available sessions
function list_sessions() {
  p4_header "Tmux Sessions"

  if tmux list-sessions 2>/dev/null; then
    echo
  else
    p4_warn "No active tmux sessions"
  fi
}

# List available layouts
function list_layouts() {
  p4_header "Available Layouts"

  grep -E "^function layout_" "$LIB_DIR/tmux/tmux_layouts.sh" | cut -d'_' -f2 | cut -d'(' -f1 | sort | while read -r layout; do
    local description=$(grep -A 1 "function layout_${layout}" "$LIB_DIR/tmux/tmux_layouts.sh" | grep "#" | sed 's/# //')
    p4_item "$layout" "${description:-No description available}"
  done
}

# Create a new session with the specified layout
function create_session() {
  local session_name="$1"
  local layout_name="$2"

  # Check if session already exists
  if tmux has-session -t "$session_name" 2>/dev/null; then
    p4_error "Session '$session_name' already exists."
    p4_tip "Use 'p4m attach $session_name' to connect to it."
    return 1
  fi

  # Check if layout function exists
  local layout_function="layout_${layout_name}"
  if ! type -t "$layout_function" &>/dev/null; then
    p4_error "Layout '$layout_name' not found."
    p4_tip "Use 'p4m layouts' to see available layouts."
    return 1
  fi

  # Create the session with the specified layout
  p4_info "Creating session '$(p4_highlight "$session_name")' with layout '$(p4_highlight "$layout_name")'..."
  $layout_function "$session_name"

  # Attach to the session if we're not already in tmux
  if [ -z "$TMUX" ]; then
    p4_success "Session created. Attaching..."
    tmux attach-session -t "$session_name"
  else
    p4_success "Session created."
    p4_tip "Use 'p4m attach $session_name' to connect to it."
  fi
}

# Attach to an existing session
function attach_session() {
  local session_name="$1"

  # Check if session exists
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    p4_error "Session '$session_name' does not exist."
    p4_tip "Use 'p4m create $session_name [layout]' to create it."
    return 1
  fi

  # Attach to the session
  p4_info "Attaching to session '$(p4_highlight "$session_name")'..."
  if [ -z "$TMUX" ]; then
    tmux attach-session -t "$session_name"
  else
    tmux switch-client -t "$session_name"
  fi
}

# Kill a session
function kill_session() {
  local session_name="$1"

  # Check if session exists
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    p4_error "Session '$session_name' does not exist."
    return 1
  fi

  # Ask for confirmation
  p4_warn "Are you sure you want to kill session '$(p4_highlight "$session_name")'? [y/N] "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    p4_info "Operation cancelled."
    return 0
  fi

  # Kill the session
  tmux kill-session -t "$session_name"
  p4_success "Session '$(p4_highlight "$session_name")' killed."
}

# Main command dispatcher
function main() {
  local command="$1"
  local session_name="$2"
  local layout_name="$3"

  # Check if tmux is installed
  if ! command_exists tmux; then
    p4_error "tmux is not installed."
    p4_tip "Please install tmux to use this script."
    return 1
  fi

  case "$command" in
  create)
    if [ -z "$session_name" ]; then
      p4_error "Session name required."
      show_help
      return 1
    fi
    if [ -z "$layout_name" ]; then
      p4_error "Layout name required."
      p4_tip "Use 'p4m layouts' to see available layouts."
      return 1
    fi
    create_session "$session_name" "$layout_name"
    ;;
  list)
    list_sessions
    ;;
  attach)
    if [ -z "$session_name" ]; then
      p4_error "Session name required."
      show_help
      return 1
    fi
    attach_session "$session_name"
    ;;
  kill)
    if [ -z "$session_name" ]; then
      p4_error "Session name required."
      show_help
      return 1
    fi
    kill_session "$session_name"
    ;;
  layouts)
    list_layouts
    ;;
  help | "")
    show_help
    ;;
  *)
    p4_error "Unknown command: $command"
    show_help
    return 1
    ;;
  esac
}

# Run main function with all arguments
main "$@"
