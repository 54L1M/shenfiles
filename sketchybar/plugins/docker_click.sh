#!/bin/bash

# Docker Click Script
# Path: ~/.config/sketchybar/plugins/docker_click.sh

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

# Get current Docker status
DOCKER_STATUS=$(check_docker_status)

case "$DOCKER_STATUS" in
    "running")
        # Docker is running - open Docker Desktop
        open -a "Docker Desktop"
        ;;
    "starting")
        # Docker is starting - just wait and update status
        echo "Docker is starting up..."
        ;;
    "stopped")
        # Docker is not running - launch it
        echo "Starting Docker Desktop..."
        open -a "Docker Desktop"
        
        # Optional: Show a notification
        if command -v osascript >/dev/null 2>&1; then
            osascript -e 'display notification "Starting Docker Desktop..." with title "Docker"'
        fi
        ;;
esac

# Force update the docker item immediately
~/.config/sketchybar/plugins/docker.sh
