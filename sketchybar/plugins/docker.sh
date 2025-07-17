#!/bin/bash

# Enhanced Docker Plugin with Centralized Icons
# Path: ~/.config/sketchybar/plugins/docker.sh

# Load colors and icons
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Function to check if Docker Desktop is running
check_docker_desktop() {
    pgrep -f "Docker Desktop" > /dev/null 2>&1 && echo "true" || echo "false"
}

# Function to check if Docker daemon is accessible
check_docker_daemon() {
    if command -v docker >/dev/null 2>&1; then
        docker info >/dev/null 2>&1 && echo "true" || echo "false"
    else
        echo "false"
    fi
}

# Function to get running containers count
get_running_containers() {
    if command -v docker >/dev/null 2>&1; then
        docker ps --format "table {{.ID}}" 2>/dev/null | tail -n +2 | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Function to get Docker Compose services (if any)
get_compose_services() {
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l | tr -d ' '
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose ps --services --filter "status=running" 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Function to get Docker system status
get_docker_status() {
    local desktop_running
    desktop_running=$(check_docker_desktop)
    local daemon_accessible
    daemon_accessible=$(check_docker_daemon)
    
    if [[ "$desktop_running" == "true" && "$daemon_accessible" == "true" ]]; then
        echo "running"
    elif [[ "$desktop_running" == "true" && "$daemon_accessible" == "false" ]]; then
        echo "starting"
    elif [[ "$desktop_running" == "false" ]]; then
        echo "stopped"
    else
        echo "error"
    fi
}

# Main logic
DOCKER_STATUS=$(get_docker_status)
RUNNING_CONTAINERS=$(get_running_containers)
COMPOSE_SERVICES=$(get_compose_services)

# Determine display based on status
case "$DOCKER_STATUS" in
    "running")
        ICON="$ICON_DOCKER"
        ICON_COLOR=$GREEN
        BACKGROUND_COLOR=$SURFACE1
        
        # Build label based on running services
        if [[ "$RUNNING_CONTAINERS" -gt 0 ]]; then
            if [[ "$COMPOSE_SERVICES" -gt 0 ]]; then
                LABEL="$RUNNING_CONTAINERS containers, $COMPOSE_SERVICES services"
                LABEL_COLOR=$GREEN
            else
                if [[ "$RUNNING_CONTAINERS" -eq 1 ]]; then
                    LABEL="1 container"
                else
                    LABEL="$RUNNING_CONTAINERS containers"
                fi
                LABEL_COLOR=$GREEN
            fi
        else
            LABEL="Running"
            LABEL_COLOR=$BLUE
        fi
        ;;
    "starting")
        ICON="$ICON_DOCKER"
        ICON_COLOR=$YELLOW
        LABEL_COLOR=$YELLOW
        BACKGROUND_COLOR=$SURFACE1
        LABEL="Starting..."
        ;;
    "stopped")
        ICON="$ICON_DOCKER"
        ICON_COLOR=$SUBTEXT0
        LABEL_COLOR=$SUBTEXT0
        BACKGROUND_COLOR=$SURFACE0
        LABEL="Docker"
        ;;
    "error")
        ICON="$ICON_DOCKER"
        ICON_COLOR=$RED
        LABEL_COLOR=$RED
        BACKGROUND_COLOR=$SURFACE1
        LABEL="Docker Error"
        ;;
esac

# Update sketchybar item
sketchybar --set "$NAME" \
           icon="$ICON" \
           icon.color="$ICON_COLOR" \
           icon.font="JetBrains Mono:Bold:16.0" \
           label="$LABEL" \
           label.color="$LABEL_COLOR" \
           label.font="JetBrains Mono:Bold:12.0" \
           background.color="$BACKGROUND_COLOR" \
           background.corner_radius=6 \
           background.height=24
