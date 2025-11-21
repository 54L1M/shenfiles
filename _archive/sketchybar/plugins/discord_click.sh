#!/bin/bash

# Discord Click Script
# Path: ~/.config/sketchybar/plugins/discord_click.sh

# Check if Discord is running
DISCORD_RUNNING=$(pgrep -f "Discord" > /dev/null && echo "true" || echo "false")

if [ "$DISCORD_RUNNING" = "true" ]; then
    # Discord is running - focus it and switch to workspace 3
    aerospace workspace 3
    osascript -e 'tell application "Discord" to activate' 2>/dev/null || open -a "Discord"
else
    # Discord is not running - launch it
    open -a "Discord"
    # Give it a moment to start, then switch to workspace 3
    sleep 1
    aerospace workspace 3
fi

# Update the discord item immediately
~/.config/sketchybar/plugins/discord.sh
