#!/bin/bash

# Enhanced Docker Plugin with Engine Paused Detection
# Path: ~/.config/sketchybar/plugins/docker.sh

# Load colors and icons
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Set default NAME if not provided
NAME=${NAME:-docker}

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

# Function to check if Docker Desktop app is running
check_docker_desktop_app() {
    if pgrep -f "Docker Desktop" > /dev/null 2>&1; then
        echo "true"
    elif osascript -e 'tell application "System Events" to get name of every process' 2>/dev/null | grep -q "Docker Desktop"; then
        echo "true"
    else
        echo "false"
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

# Function to get running containers count
get_running_containers() {
    if [[ -n "$DOCKER_CMD" ]]; then
        local containers
        containers=$("$DOCKER_CMD" ps -q 2>/dev/null | wc -l | tr -d ' ')
        echo "${containers:-0}"
    else
        echo "0"
    fi
}

# Function to get Docker Compose services
get_compose_services() {
    local compose_count=0
    
    if [[ -n "$DOCKER_CMD" ]]; then
        # Try docker compose (new syntax)
        if "$DOCKER_CMD" compose version >/dev/null 2>&1; then
            compose_count=$("$DOCKER_CMD" compose ps --services --filter "status=running" 2>/dev/null | wc -l | tr -d ' ')
        fi
        
        # Fallback to docker-compose if available and count is still 0
        if [[ "$compose_count" -eq 0 ]] && command -v docker-compose >/dev/null 2>&1; then
            compose_count=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l | tr -d ' ')
        fi
    fi
    
    echo "${compose_count:-0}"
}

# Function to determine Docker status
get_docker_status() {
    local desktop_running daemon_status
    
    desktop_running=$(check_docker_desktop_app)
    
    if [[ "$desktop_running" == "false" ]]; then
        echo "stopped"
        return
    fi
    
    daemon_status=$(check_docker_daemon_status)
    echo "$daemon_status"
}

# Main logic
DOCKER_STATUS=$(get_docker_status)
RUNNING_CONTAINERS="0"
COMPOSE_SERVICES="0"

if [[ "$DOCKER_STATUS" == "running" ]]; then
    RUNNING_CONTAINERS=$(get_running_containers)
    COMPOSE_SERVICES=$(get_compose_services)
fi

# Determine display based on status
case "$DOCKER_STATUS" in
    "running")
        ICON="$ICON_DOCKER"
        ICON_COLOR="$GREEN"
        BACKGROUND_COLOR="$SURFACE1"
        
        if [[ "$RUNNING_CONTAINERS" -gt 0 ]]; then
            if [[ "$COMPOSE_SERVICES" -gt 0 ]]; then
                LABEL="$RUNNING_CONTAINERS containers, $COMPOSE_SERVICES services"
                LABEL_COLOR="$GREEN"
            else
                if [[ "$RUNNING_CONTAINERS" -eq 1 ]]; then
                    LABEL="1 container"
                else
                    LABEL="$RUNNING_CONTAINERS containers"
                fi
                LABEL_COLOR="$GREEN"
            fi
        else
            LABEL="Ready"
            LABEL_COLOR="$BLUE"
        fi
        ;;
    "paused")
        ICON="$ICON_DOCKER"
        ICON_COLOR="$YELLOW"
        LABEL_COLOR="$YELLOW"
        BACKGROUND_COLOR="$SURFACE1"
        LABEL="Paused"
        ;;
    "error"|"no_command")
        ICON="$ICON_DOCKER"
        ICON_COLOR="$RED"
        LABEL_COLOR="$RED"
        BACKGROUND_COLOR="$SURFACE1"
        LABEL="Error"
        ;;
    "stopped")
        ICON="$ICON_DOCKER"
        ICON_COLOR="$SUBTEXT0"
        LABEL_COLOR="$SUBTEXT0"
        BACKGROUND_COLOR="$SURFACE0"
        LABEL="Launch"
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
