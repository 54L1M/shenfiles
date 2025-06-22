#!/bin/bash

# Front App Plugin
# Path: ~/.config/sketchybar/plugins/front_app.sh

# Load colors
source "$HOME/.config/sketchybar/colors.sh"

# Handle front app switched event
if [ "$SENDER" = "front_app_switched" ] && [ ! -z "$INFO" ]; then
    # Use the INFO variable provided by the event
    FRONT_APP="$INFO"
else
    # Fallback: get the focused application from aerospace
    FRONT_APP=$(aerospace list-windows --focused --format "%{app-name}" 2>/dev/null)
fi

# Handle empty result
if [ -z "$FRONT_APP" ]; then
    FRONT_APP="Desktop"
fi

# Truncate long app names
if [ ${#FRONT_APP} -gt 20 ]; then
    FRONT_APP=$(echo "$FRONT_APP" | cut -c 1-20)...
fi

# Update the sketchybar item with proper font
sketchybar --set $NAME label="$FRONT_APP" \
                       label.font="JetBrains Mono:Bold:14.0"
