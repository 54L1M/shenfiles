#!/usr/bin/env bash
# tmux-layouts.sh - Definitions for tmux session layouts

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LIB_DIR="$BASE_DIR/lib"
source "$LIB_DIR/tmux/tmux_helpers.sh"


function layout_i2d() {
  # Creates a session with In2dialog structure
  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating In2Dialog layout"


  tmux new-session -d -s "$session_name" -c "$working_dir" -n "code"


  tmux new-window -t "$session_name" -c "$working_dir" -n "shell"
  tmux new-window -t "$session_name" -c "$working_dir" -n "server"
  tmux new-window -t "$session_name" -c "$working_dir" -n "db"
  tmux new-window -t "$session_name" -c "$working_dir" -n "misc"

  tmux_broadcast "$session_name" "source $HOME/Documents/Workstation/In2Dialog/I2D_ATS/.env"
  tmux send-keys -t "$session_name:db.0" 'export LESS="-SRXF"' C-m
  tmux_broadcast "$session_name" "clear"
  tmux send-keys -t "$session_name:code.0" "nvim ." C-m

  # Select the editor pane
  tmux select-window -t "$session_name:code"

  p4_debug "In2dialog layout created"
}


# Project layout with Git integration
# Creates a session with code editor, git status, and command terminal
function layout_project() {
  # Creates a session with code editor, git status, and command terminal

  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating Project layout with Git integration"

  # Start a new session with a window named 'project'
  tmux new-session -d -s "$session_name" -c "$working_dir" -n "code"

  # Split the window horizontally (creating right pane)
  tmux split-window -h -t "$session_name:code" -c "$working_dir"

  # Split the right pane vertically
  tmux split-window -v -t "$session_name:code.1" -c "$working_dir"

  # Set up the panes with appropriate commands
  tmux send-keys -t "$session_name:code.0" "nvim" C-m
  tmux send-keys -t "$session_name:code.1" "git status" C-m
  tmux send-keys -t "$session_name:code.2" "echo 'Ready for commands'" C-m

  # Add additional windows
  tmux new-window -t "$session_name" -c "$working_dir" -n "git"
  tmux send-keys -t "$session_name:git" "git log --graph --oneline --all --decorate" C-m

  tmux new-window -t "$session_name" -c "$working_dir" -n "build"
  tmux send-keys -t "$session_name:build" "echo 'Build/test window'" C-m

  # Go back to the first window
  tmux select-window -t "$session_name:code"

  # Set the main left pane to be larger (60%)
  tmux resize-pane -t "$session_name:code.0" -x "60%"

  # Select the editor pane
  tmux select-pane -t "$session_name:code.0"

  p4_debug "Project layout created with 3 panes and 2 additional windows"
}

# System monitoring layout
# Creates a session for system monitoring and logs
function layout_monitor() {
  # Creates a session for system monitoring and logs

  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating System Monitoring layout"

  # Start a new session with a window for system monitoring
  tmux new-session -d -s "$session_name" -c "$working_dir" -n "system"

  # Split the window into four panes
  tmux split-window -h -t "$session_name:system"
  tmux split-window -v -t "$session_name:system.0"
  tmux split-window -v -t "$session_name:system.1"

  # Set up the panes with monitoring commands
  tmux send-keys -t "$session_name:system.0" "htop" C-m
  tmux send-keys -t "$session_name:system.1" "watch -n 1 'df -h'" C-m
  tmux send-keys -t "$session_name:system.2" "watch -n 1 'free -h'" C-m
  tmux send-keys -t "$session_name:system.3" "tail -f /var/log/syslog 2>/dev/null || tail -f /var/log/messages 2>/dev/null || echo 'No system logs found'" C-m

  # Add a window for network monitoring
  tmux new-window -t "$session_name" -c "$working_dir" -n "network"
  tmux split-window -v -t "$session_name:network"
  tmux send-keys -t "$session_name:network.0" "watch -n 1 'netstat -tuln'" C-m
  tmux send-keys -t "$session_name:network.1" "ping 8.8.8.8" C-m

  # Add a window for docker/container monitoring if available
  if command_exists docker; then
    tmux new-window -t "$session_name" -c "$working_dir" -n "docker"
    tmux send-keys -t "$session_name:docker" "watch -n 2 'docker ps'" C-m
  fi

  # Go back to the first window
  tmux select-window -t "$session_name:system"

  p4_debug "System monitoring layout created"
}
