#!/usr/bin/env bash
# tmux-layouts.sh - Definitions for tmux session layouts

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LIB_DIR="$BASE_DIR/lib"
source "$LIB_DIR/tmux/tmux_helpers.sh"

# Python development layout
# Creates a session with a code editor, Python shell, and terminal
function layout_python() {
  # Creates a session with a code editor, Python shell, and terminal
  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating Python development layout"

  # Start a new session with a window named 'dev'
  tmux new-session -d -s "$session_name" -c "$working_dir" -n "dev"

  # Split the window horizontally (creating right pane)
  tmux split-window -h -t "$session_name:dev" -c "$working_dir"

  # Split the right pane vertically
  tmux split-window -v -t "$session_name:dev.1" -c "$working_dir"

  # Set up the panes with appropriate commands
  tmux send-keys -t "$session_name:dev.0" "nvim" C-m
  tmux send-keys -t "$session_name:dev.1" "python" C-m
  tmux send-keys -t "$session_name:dev.2" "echo 'Ready for tests/commands'" C-m

  # Set the main left pane to be larger (60%)
  tmux resize-pane -t "$session_name:dev.0" -x "60%"

  # Select the editor pane
  tmux select-pane -t "$session_name:dev.0"

  p4_debug "Python session layout created with 3 panes"
}

# Go development layout
# Creates a session with a code editor, output window, and test terminal
function layout_golang() {
  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating Go development layout"

  # Start a new session with a window named 'go'
  tmux new-session -d -s "$session_name" -c "$working_dir" -n "go"

  # Split the window horizontally (creating right pane)
  tmux split-window -h -t "$session_name:go" -c "$working_dir"

  # Split the right pane vertically
  tmux split-window -v -t "$session_name:go.1" -c "$working_dir"

  # Set up the panes with appropriate commands
  tmux send-keys -t "$session_name:go.0" "nvim" C-m
  tmux send-keys -t "$session_name:go.1" "echo 'Ready for go run'" C-m
  tmux send-keys -t "$session_name:go.2" "echo 'Ready for go test'" C-m

  # Set the main left pane to be larger (60%)
  tmux resize-pane -t "$session_name:go.0" -x "60%"

  # Select the editor pane
  tmux select-pane -t "$session_name:go.0"

  p4_debug "Go session layout created with 3 panes"
}

# Web development layout (JS, HTML, CSS)
# Creates a session with a code editor, server/preview, and build terminal
function layout_web() {
  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating Web development layout"

  # Start a new session with a window named 'web'
  tmux new-session -d -s "$session_name" -c "$working_dir" -n "web"

  # Split the window horizontally (creating right pane)
  tmux split-window -h -t "$session_name:web" -c "$working_dir"

  # Split the right pane vertically
  tmux split-window -v -t "$session_name:web.1" -c "$working_dir"

  # Set up the panes with appropriate commands
  tmux send-keys -t "$session_name:web.0" "nvim" C-m
  tmux send-keys -t "$session_name:web.1" "echo 'Ready for server'" C-m
  tmux send-keys -t "$session_name:web.2" "echo 'Ready for npm commands'" C-m

  # Set the main left pane to be larger (60%)
  tmux resize-pane -t "$session_name:web.0" -x "60%"

  # Add a second window for browser preview (if needed)
  tmux new-window -t "$session_name" -c "$working_dir" -n "preview"
  tmux send-keys -t "$session_name:preview" "echo 'Browser preview window'" C-m

  # Go back to the first window
  tmux select-window -t "$session_name:web"
  tmux select-pane -t "$session_name:web.0"

  p4_debug "Web session layout created with 3 panes and preview window"
}

# Django development layout
# Creates a session with code editor, Django shell, server, and command terminal
function layout_django() {
  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating Django development layout"

  # Start a new session with a window named 'django'
  tmux new-session -d -s "$session_name" -c "$working_dir" -n "django"

  # Split the window horizontally (creating right pane)
  tmux split-window -h -t "$session_name:django" -c "$working_dir"

  # Split both panes vertically
  tmux split-window -v -t "$session_name:django.0" -c "$working_dir"
  tmux split-window -v -t "$session_name:django.1" -c "$working_dir"

  # Set up the panes with appropriate commands
  tmux send-keys -t "$session_name:django.0" "nvim" C-m
  tmux send-keys -t "$session_name:django.1" "echo 'Ready for Django server (python manage.py runserver)'" C-m
  tmux send-keys -t "$session_name:django.2" "python manage.py shell" C-m
  tmux send-keys -t "$session_name:django.3" "echo 'Ready for Django commands (migrations, tests, etc.)'" C-m

  # Adjust the pane sizes (50/50 horizontal split)
  tmux resize-pane -t "$session_name:django.0" -x "50%"

  # Add a window for database
  tmux new-window -t "$session_name" -c "$working_dir" -n "db"
  tmux send-keys -t "$session_name:db" "echo 'Database window (sqlite, psql, etc.)'" C-m

  # Go back to the first window
  tmux select-window -t "$session_name:django"
  tmux select-pane -t "$session_name:django.0"

  p4_debug "Django session layout created with 4 panes and database window"
}

# Bash scripting layout
# Creates a session with a script editor and test terminal
function layout_bash() {
  local session_name="$1"
  local working_dir="${2:-$(pwd)}"

  p4_step "Creating Bash scripting layout"

  # Start a new session with a window named 'bash'
  tmux new-session -d -s "$session_name" -c "$working_dir" -n "bash"

  # Split the window horizontally (creating right pane)
  tmux split-window -h -t "$session_name:bash" -c "$working_dir"

  # Set up the panes with appropriate commands
  tmux send-keys -t "$session_name:bash.0" "nvim" C-m
  tmux send-keys -t "$session_name:bash.1" "echo 'Ready to test scripts'" C-m

  # Add a second window for documentation/reference
  tmux new-window -t "$session_name" -c "$working_dir" -n "docs"
  tmux send-keys -t "$session_name:docs" "echo 'Documentation window (man pages, help, etc.)'" C-m

  # Go back to the first window
  tmux select-window -t "$session_name:bash"

  # Set the main left pane to be larger (50%)
  tmux resize-pane -t "$session_name:bash.0" -x "50%"

  # Select the editor pane
  tmux select-pane -t "$session_name:bash.0"

  p4_debug "Bash scripting layout created with 2 panes and docs window"
}

# Project layout with Git integration
# Creates a session with code editor, git status, and command terminal
function layout_project() {
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
