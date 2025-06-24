#!/bin/bash

# Enhanced Battery Plugin with Centralized Icons
# Path: ~/.config/sketchybar/plugins/battery.sh

# Load colors and icons
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Get battery percentage
PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

# Exit if no battery info
if [ -z "$PERCENTAGE" ]; then
    exit 0
fi

# Determine icon and color based on battery level
case ${PERCENTAGE} in
    9[0-9]|100) ICON="$ICON_BATTERY_FULL" COLOR=$GREEN ;;   # 90-100%
    [6-8][0-9]) ICON="$ICON_BATTERY_HIGH" COLOR=$YELLOW ;;  # 60-89%
    [3-5][0-9]) ICON="$ICON_BATTERY_MID" COLOR=$PEACH ;;    # 30-59%
    [1-2][0-9]) ICON="$ICON_BATTERY_LOW" COLOR=$RED ;;      # 10-29%
    *) ICON="$ICON_BATTERY_EMPTY" COLOR=$RED ;;             # 0-9%
esac

# Override if charging
if [[ -n $CHARGING ]]; then
    ICON="$ICON_BATTERY_CHARGING"
    COLOR=$BLUE
fi

# Update sketchybar item
sketchybar --set $NAME \
           icon="$ICON" \
           icon.color=$COLOR \
           icon.font="JetBrains Mono:Bold:14.0" \
           label="${PERCENTAGE}%" \
           label.color=$COLOR \
           label.font="JetBrains Mono:Bold:14.0" \
           background.border_color=$COLOR
