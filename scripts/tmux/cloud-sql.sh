#!/bin/bash

# Tmux Cloud SQL Proxy Status Plugin
# Detects sessions started by p4p.sh (sql-proxy-*)

# -----------------------------------------------------------------------------
# CONFIGURATION & COLORS (Gruvbox Material match)
# -----------------------------------------------------------------------------
# Matching your tmux.conf @thm_* variables
COLOR_RED="#ea6962"     # Prod
COLOR_YELLOW="#d8a657"  # Staging
COLOR_GREEN="#a9b665"   # Dev/Local
COLOR_BLUE="#7daea3"    # Default
COLOR_BG="#1d2021"      # Base Background
COLOR_GRAY="#595959"    # Overlay0 (Separators)

# Icons
ICON_DB="󰆼" 

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

# Find active proxy sessions created by p4p.sh
# They are named "sql-proxy-<profile>"
PROXY_SESSIONS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^sql-proxy-")

# If no proxies are running, exit silently (display nothing)
if [[ -z "$PROXY_SESSIONS" ]]; then
    echo ""
    exit 0
fi

OUTPUT=""

# Loop through found sessions (handles multiple proxies running at once)
while read -r session; do
    # Extract profile name (remove prefix)
    PROFILE="${session#sql-proxy-}"
    
    # Determine Color based on profile name
    case "$PROFILE" in
        *stage*|*STAGING*)    TEXT_COLOR="$COLOR_BLUE" ;;
        *PROD*|*production*)  TEXT_COLOR="$COLOR_RED" ;;
        *dev*|*local*)        TEXT_COLOR="$COLOR_GREEN" ;;
        *)                    TEXT_COLOR="$COLOR_BLUE" ;;
    esac

    # Add spacing if multiple proxies exist
    if [[ -n "$OUTPUT" ]]; then
        OUTPUT="$OUTPUT "
    fi

    # Format the segment
    OUTPUT="${OUTPUT}#[fg=${TEXT_COLOR},bg=${COLOR_BG}]${ICON_DB} ${PROFILE}"

done <<< "$PROXY_SESSIONS"

# Print final formatted string with a trailing separator to match your kube.sh style
echo "#[fg=$COLOR_GRAY,bg=$COLOR_BG,none]│ $OUTPUT"
