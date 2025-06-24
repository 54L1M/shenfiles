#!/bin/bash

# Aerospace Workspace Plugin
# Path: ~/.config/sketchybar/plugins/aerospace.sh

# Load colors
source "$HOME/.config/sketchybar/colors.sh"

# Handle workspace change events
if [ "$SENDER" = "aerospace_workspace_change" ]; then
    # Use the FOCUSED parameter sent by aerospace
    CURRENT_WORKSPACE="$FOCUSED"
    
    # Update all workspaces with proper styling
    for i in {1..9}; do
        if [ "$i" = "$CURRENT_WORKSPACE" ]; then
            # Active workspace styling - highlighted and bold
            sketchybar --set space.$i \
                             icon.color=$RED \
                             icon.font="JetBrains Mono:Black:16.0"
        else
            # Inactive workspace styling - dimmed
            sketchybar --set space.$i \
                             icon.color=$SUBTEXT0 \
                             icon.font="JetBrains Mono:Bold:14.0"
        fi
    done
else
    # Fallback: query aerospace directly and update all workspaces
    CURRENT_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
    
    if [ -n "$CURRENT_WORKSPACE" ]; then
        for i in {1..9}; do
            if [ "$i" = "$CURRENT_WORKSPACE" ]; then
                sketchybar --set space.$i \
                                 icon.color=$RED \
                                 icon.font="JetBrains Mono:Black:16.0"
            else
                sketchybar --set space.$i \
                                 icon.color=$SUBTEXT0 \
                                 icon.font="JetBrains Mono:Bold:14.0"
            fi
        done
    fi
fi
