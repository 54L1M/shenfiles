#!/usr/bin/env bash
# utils.sh - Common utility functions for P4nda scripts

# ====================================
# Git Utilities
# ====================================

# Get current git branch
git_current_branch() {
    git branch --show-current 2>/dev/null || echo "main"
}

# Check if git working directory is clean
git_is_clean() {
    [[ -z "$(git status --porcelain)" ]]
}

# Check if git working directory has changes
git_has_changes() {
    [[ -n "$(git status --porcelain)" ]]
}

# Get git remote URL
git_remote_url() {
    git remote get-url origin 2>/dev/null
}

# Check if we're in a git repository
git_is_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Get the number of commits ahead of remote
git_commits_ahead() {
    local branch="${1:-$(git_current_branch)}"
    git rev-list --count "origin/$branch..$branch" 2>/dev/null || echo "0"
}

# Get the number of commits behind remote
git_commits_behind() {
    local branch="${1:-$(git_current_branch)}"
    git rev-list --count "$branch..origin/$branch" 2>/dev/null || echo "0"
}

# ====================================
# File System Utilities
# ====================================

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Check if path exists (file or directory)
path_exists() {
    [[ -e "$1" ]]
}

# Check if file is executable
is_executable() {
    [[ -x "$1" ]]
}

# Check if file is readable
is_readable() {
    [[ -r "$1" ]]
}

# Check if file is writable
is_writable() {
    [[ -w "$1" ]]
}

# Get file size in bytes
file_size() {
    [[ -f "$1" ]] && stat -c%s "$1" 2>/dev/null || echo "0"
}

# Get file modification time
file_mtime() {
    [[ -f "$1" ]] && stat -c%Y "$1" 2>/dev/null
}

# Create directory if it doesn't exist
ensure_dir() {
    [[ ! -d "$1" ]] && mkdir -p "$1"
}

# Get absolute path
get_abs_path() {
    readlink -f "$1" 2>/dev/null || realpath "$1" 2>/dev/null
}

# ====================================
# Command Utilities
# ====================================

# Check if command is available
is_command_available() {
    command -v "$1" >/dev/null 2>&1
}

# Check if command is available and executable
command_exists() {
    is_command_available "$1"
}

# Run command with timeout
run_with_timeout() {
    local timeout="$1"
    shift
    timeout "$timeout" "$@"
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Get current user
current_user() {
    whoami
}

# ====================================
# String Utilities
# ====================================

# Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Trim whitespace from string
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# Check if string contains substring
contains() {
    [[ "$1" == *"$2"* ]]
}

# Check if string starts with prefix
starts_with() {
    [[ "$1" == "$2"* ]]
}

# Check if string ends with suffix
ends_with() {
    [[ "$1" == *"$2" ]]
}

# ====================================
# Process Utilities
# ====================================

# Check if process is running by PID
is_process_running() {
    kill -0 "$1" 2>/dev/null
}

# Get process ID by name
get_pid_by_name() {
    pgrep -f "$1" 2>/dev/null
}

# Kill process by name
kill_by_name() {
    pkill -f "$1" 2>/dev/null
}

# Wait for process to finish
wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    local count=0
    
    while is_process_running "$pid" && [[ $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done
    
    ! is_process_running "$pid"
}

# ====================================
# Network Utilities
# ====================================

# Check if port is open
is_port_open() {
    local host="${1:-localhost}"
    local port="$2"
    timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null
}

# Check if URL is reachable
is_url_reachable() {
    curl -sSf "$1" >/dev/null 2>&1
}

# Get public IP address
get_public_ip() {
    curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null
}

# ====================================
# Date/Time Utilities
# ====================================

# Get current timestamp
timestamp() {
    date +%s
}

# Get current date in ISO format
date_iso() {
    date -Iseconds
}

# Get current date in custom format
date_format() {
    local format="${1:-%Y-%m-%d %H:%M:%S}"
    date +"$format"
}

# Calculate time difference in seconds
time_diff() {
    local start="$1"
    local end="${2:-$(timestamp)}"
    echo $((end - start))
}

# ====================================
# Array Utilities
# ====================================

# Check if array contains element
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        [[ "$item" == "$element" ]] && return 0
    done
    return 1
}

# Join array elements with delimiter
array_join() {
    local delimiter="$1"
    shift
    local array=("$@")
    
    printf "%s" "${array[0]}"
    printf "%s%s" "${array[@]:1/#/$delimiter}"
}

# ====================================
# Validation Utilities
# ====================================

# Check if string is a valid email
is_email() {
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

# Check if string is a valid URL
is_url() {
    [[ "$1" =~ ^https?://[A-Za-z0-9.-]+\.[A-Za-z]{2,}(/.*)?$ ]]
}

# Check if string is a number
is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Check if string is a valid IP address
is_ip() {
    [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}
