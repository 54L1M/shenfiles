#!/usr/bin/env bash
# tmux_helpers.sh - Utility functions for tmux operations

# ====================================
# Tmux Utility Functions
# ====================================

# Check if a command exists
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if we're inside a tmux session
function is_in_tmux() {
  [ -n "$TMUX" ]
}

# Get the current tmux session name (if any)
function get_current_tmux_session() {
  if is_in_tmux; then
    tmux display-message -p '#S'
  else
    echo ""
  fi
}

# Check if a tmux session exists
function session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

# Get all tmux sessions
function get_all_sessions() {
  tmux list-sessions -F "#{session_name}" 2>/dev/null || echo ""
}

# Create a directory if it doesn't exist
function ensure_directory() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    p4_debug "Created directory: $1"
  else
    p4_debug "Directory already exists: $1"
  fi
}

# Function to safely send keys to a tmux pane
# This prevents the script from failing if the pane doesn't exist
function safe_send_keys() {
  local target="$1"
  shift

  if tmux has-session -t "$target" 2>/dev/null; then
    tmux send-keys -t "$target" "$@"
    return 0
  else
    p4_debug "Target pane doesn't exist: $target"
    return 1
  fi
}

# Function to safely resize a tmux pane
function safe_resize_pane() {
  local target="$1"
  local dimension="$2"
  local size="$3"

  if tmux has-session -t "$target" 2>/dev/null; then
    tmux resize-pane -t "$target" "$dimension" "$size"
    return 0
  else
    p4_debug "Target pane doesn't exist: $target"
    return 1
  fi
}

# Function to detach all clients from a session
function detach_all_clients() {
  local session_name="$1"

  if session_exists "$session_name"; then
    tmux list-clients -t "$session_name" -F "#{client_name}" 2>/dev/null |
      while read -r client; do
        tmux detach-client -c "$client"
      done
  fi
}

# Function to get a list of windows in a session
function get_session_windows() {
  local session_name="$1"

  if session_exists "$session_name"; then
    tmux list-windows -t "$session_name" -F "#{window_index}:#{window_name}" 2>/dev/null
  fi
}

# Function to get a list of panes in a window
function get_window_panes() {
  local target="$1"

  if tmux has-session -t "$target" 2>/dev/null; then
    tmux list-panes -t "$target" -F "#{pane_index}" 2>/dev/null
  fi
}

# Function to check if a pane is running a command
function is_pane_running_command() {
  local target="$1"

  if tmux has-session -t "$target" 2>/dev/null; then
    local pane_pid=$(tmux display-message -p -t "$target" "#{pane_pid}" 2>/dev/null)
    if [ -n "$pane_pid" ]; then
      # Check if any child processes are running (excluding shell)
      local child_processes=$(ps --ppid "$pane_pid" -o comm= | grep -v "^-\?sh$" | grep -v "^-\?bash$" | grep -v "^-\?zsh$")
      [ -n "$child_processes" ]
    else
      return 1
    fi
  else
    return 1
  fi
}

# Function to capture pane content
function capture_pane_content() {
  local target="$1"
  local output_file="$2"
  local start_line="${3:--}"
  local end_line="${4:--}"

  if tmux has-session -t "$target" 2>/dev/null; then
    tmux capture-pane -t "$target" -p -S "$start_line" -E "$end_line" >"$output_file"
    return 0
  else
    p4_debug "Target pane doesn't exist: $target"
    return 1
  fi
}
