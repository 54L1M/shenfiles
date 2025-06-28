#!/bin/bash

# Sound Click Script with Volume Control
# Path: ~/.config/sketchybar/plugins/sound_click.sh

# Function to get current volume
get_volume() {
    osascript -e "output volume of (get volume settings)" 2>/dev/null || echo "0"
}

# Function to check if sound is muted
is_muted() {
    local muted=$(osascript -e "output muted of (get volume settings)" 2>/dev/null || echo "false")
    [[ "$muted" == "true" ]] && echo "true" || echo "false"
}

# Function to toggle mute
toggle_mute() {
    local current_mute=$(is_muted)
    if [[ "$current_mute" == "true" ]]; then
        osascript -e "set volume output muted false" 2>/dev/null
        echo "Unmuted"
    else
        osascript -e "set volume output muted true" 2>/dev/null
        echo "Muted"
    fi
}

# Function to set volume to specific level
set_volume() {
    local volume=$1
    osascript -e "set volume output volume $volume" 2>/dev/null
    echo "Volume set to $volume%"
}

# Function to adjust volume by increment
adjust_volume() {
    local increment=$1
    local current_volume=$(get_volume)
    local new_volume=$((current_volume + increment))
    
    # Clamp volume between 0 and 100
    if [[ $new_volume -lt 0 ]]; then
        new_volume=0
    elif [[ $new_volume -gt 100 ]]; then
        new_volume=100
    fi
    
    set_volume $new_volume
}

# Function to cycle through preset volume levels
cycle_volume() {
    local current_volume=$(get_volume)
    local current_mute=$(is_muted)
    
    if [[ "$current_mute" == "true" ]]; then
        # If muted, unmute to 50%
        osascript -e "set volume output muted false" 2>/dev/null
        set_volume 50
    elif [[ $current_volume -eq 0 ]]; then
        set_volume 25
    elif [[ $current_volume -le 25 ]]; then
        set_volume 50
    elif [[ $current_volume -le 50 ]]; then
        set_volume 75
    elif [[ $current_volume -le 75 ]]; then
        set_volume 100
    else
        # At 100%, cycle back to mute
        toggle_mute
    fi
}

# Handle different click types
case "$BUTTON" in
    "left")
        # Left click: Toggle mute
        toggle_mute
        ;;
    "right")
        # Right click: Open Sound preferences
        open -b com.apple.preference.sound
        ;;
    "middle")
        # Middle click: Cycle through volume levels
        cycle_volume
        ;;
    *)
        # Default: Toggle mute
        toggle_mute
        ;;
esac

# Show a brief notification of the action (optional)
if command -v osascript >/dev/null 2>&1; then
    current_volume=$(get_volume)
    current_mute=$(is_muted)
    
    if [[ "$current_mute" == "true" ]]; then
        osascript -e 'display notification "Audio Muted" with title "Sound"' 2>/dev/null
    else
        osascript -e "display notification \"Volume: ${current_volume}%\" with title \"Sound\"" 2>/dev/null
    fi
fi

# Force update the sound item immediately
~/.config/sketchybar/plugins/sound.sh
