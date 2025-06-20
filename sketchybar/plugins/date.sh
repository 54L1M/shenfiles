#!/bin/bash

# Date Plugin
# Path: ~/.config/sketchybar/plugins/date.sh

# Update date with current date (abbreviated day, day number, abbreviated month)
sketchybar --set $NAME label="$(date '+%a %d %b')"
