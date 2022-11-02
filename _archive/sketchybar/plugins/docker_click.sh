#!/bin/bash

# Docker Click Script
# Path: ~/.config/sketchybar/plugins/docker_click.sh

# Explicitly set PATH to include common Docker locations
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# Find docker command in common locations
DOCKER_CMD=""
DOCKER_LOCATIONS=(
    "/usr/local/bin/docker"
    "/opt/homebrew/bin/docker"
    "/usr/bin/docker"
    "$(command -v docker 2>/dev/null)"
)

for docker_path in "${DOCKER_LOCATIONS[@]}"; do
    if [[ -n "$docker_path" && -x "$docker_path" ]]; then
        DOCKER_CMD="$docker_path"
        break
    fi
done



# Function to check Docker status
check_docker_status() {
    if pgrep -f "Docker Desktop" > /dev/null 2>&1; then
        if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
            echo "running"
        else
            echo "starting"
        fi
    else
        echo "stopped"
    fi
}
# Function to check Docker daemon status
check_docker_daemon_status() {
    if [[ -z "$DOCKER_CMD" ]]; then
        echo "no_command"
        return
    fi
    
    # Check docker info for detailed status
    local docker_info_output
    docker_info_output=$("$DOCKER_CMD" info 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "running"
    elif echo "$docker_info_output" | grep -q "manually paused"; then
        echo "paused"
    else
        echo "error"
    fi
}
# Get current Docker status
DOCKER_STATUS=$(check_docker_daemon_status)

case "$DOCKER_STATUS" in
    "running")
        # Docker is running - open Docker Desktop
        open -a "Docker Desktop"
        ;;
    "paused")
        
        open -a "Docker Desktop"

        ;;
    "error")
        open -a "Docker Desktop"
        ;;
esac

# Force update the docker item immediately
~/.config/sketchybar/plugins/docker.sh
