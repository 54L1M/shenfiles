#!/bin/bash

# Tmux p4e Environment Plugin
# Displays the current active p4e environment for the active pane

# -----------------------------------------------------------------------------
# CONFIGURATION & COLORS (Gruvbox Material match)
# -----------------------------------------------------------------------------
COLOR_RED="#ea6962"     # Prod
COLOR_YELLOW="#d8a657"  # Staging
COLOR_GREEN="#a9b665"   # Dev/Local
COLOR_BLUE="#7daea3"    # Default
COLOR_MAUVE="#d3869b"   # p4e default
COLOR_BG="#1d2021"      # Base Background
COLOR_GRAY="#595959"    # Overlay0 (Separators)

# Icons
ICON_ENV="󱇵" 

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

# Use the provided pane_id or fall back to the currently active pane
PANE_ID="${1:-$(tmux display-message -p '#{pane_id}')}"

# Get the environment from the pane-specific option @p4e_env
CURRENT_ENV=$(tmux show-options -p -v -t "$PANE_ID" @p4e_env 2>/dev/null)

# If no environment is active for this pane, exit silently
if [[ -z "$CURRENT_ENV" ]]; then
    echo ""
    exit 0
fi

# Split PROJECT:ENV
PROJECT="${CURRENT_ENV%%:*}"
ENV="${CURRENT_ENV#*:}"

# Determine Color based on env name
case "$ENV" in
    *prod*|*PROD*|*production*)  TEXT_COLOR="$COLOR_RED" ;;
    *stage*|*STAGING*|*stg*)    TEXT_COLOR="$COLOR_YELLOW" ;;
    *dev*|*local*)              TEXT_COLOR="$COLOR_GREEN" ;;
    *)                          TEXT_COLOR="$COLOR_MAUVE" ;;
esac

# Format the segment with a leading separator
OUTPUT="#[fg=$TEXT_COLOR,bg=$COLOR_BG]$ICON_ENV $PROJECT:$ENV"

# Print final formatted string
echo "#[fg=$COLOR_GRAY,bg=$COLOR_BG,none]│ $OUTPUT "
