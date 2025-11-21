#!/bin/bash

# Enhanced Sound Plugin with Volume Control
# Path: ~/.config/sketchybar/plugins/sound.sh

# Load colors and icons
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Function to get current volume
get_volume() {
    osascript -e "output volume of (get volume settings)" 2>/dev/null || echo "0"
}

# Function to check if sound is muted
is_muted() {
    local muted=$(osascript -e "output muted of (get volume settings)" 2>/dev/null || echo "false")
    [[ "$muted" == "true" ]] && echo "true" || echo "false"
}

# Function to get current input volume (microphone)
get_input_volume() {
    osascript -e "input volume of (get volume settings)" 2>/dev/null || echo "0"
}

# Function to check if input is muted
is_input_muted() {
    # Check if input volume is 0 as a proxy for muted mic
    local input_vol=$(get_input_volume)
    [[ "$input_vol" -eq 0 ]] && echo "true" || echo "false"
}

# Get current audio state
VOLUME=$(get_volume)
MUTED=$(is_muted)

# Determine icon, color, and label based on volume state
if [[ "$MUTED" == "true" ]]; then
    # Sound is muted
    ICON="$ICON_VOLUME_MUTED"
    ICON_COLOR=$RED
    LABEL_COLOR=$RED
    BACKGROUND_COLOR=$SURFACE1
    LABEL="Deafen"
else
    # Sound is not muted - determine level
    if [[ "$VOLUME" -eq 0 ]]; then
        ICON="$ICON_VOLUME_OFF"
        ICON_COLOR=$SUBTEXT0
        LABEL_COLOR=$SUBTEXT0
        BACKGROUND_COLOR=$SURFACE0
        LABEL="0%"
    elif [[ "$VOLUME" -le 25 ]]; then
        ICON="$ICON_VOLUME_LOW"
        ICON_COLOR=$YELLOW
        LABEL_COLOR=$YELLOW
        BACKGROUND_COLOR=$SURFACE0
        LABEL="${VOLUME}%"
    elif [[ "$VOLUME" -le 60 ]]; then
        ICON="$ICON_VOLUME_MEDIUM"
        ICON_COLOR=$BLUE
        LABEL_COLOR=$BLUE
        BACKGROUND_COLOR=$SURFACE0
        LABEL="${VOLUME}%"
    else
        ICON="$ICON_VOLUME_HIGH"
        ICON_COLOR=$GREEN
        LABEL_COLOR=$GREEN
        BACKGROUND_COLOR=$SURFACE0
        LABEL="${VOLUME}%"
    fi
fi

# Update sketchybar item
sketchybar --set $NAME \
           icon="$ICON" \
           icon.color=$ICON_COLOR \
           icon.font="JetBrains Mono:Bold:16.0" \
           label="$LABEL" \
           label.color=$LABEL_COLOR \
           label.font="JetBrains Mono:Bold:12.0" \
           background.color=$BACKGROUND_COLOR \
           background.corner_radius=6 \
           background.height=24
