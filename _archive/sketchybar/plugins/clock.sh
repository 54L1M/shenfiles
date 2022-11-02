#!/bin/bash

# Clock Plugin
# Path: ~/.config/sketchybar/plugins/clock.sh

# Update clock with current time (24-hour format)
sketchybar --set $NAME label="$(date '+%H:%M')" \
                       label.font="JetBrains Mono:Bold:14.0"
