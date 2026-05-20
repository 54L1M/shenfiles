#!/bin/bash

# Tmux Cloud SQL Proxy Status Plugin
# Detects sessions started by p4p.sh (sql-proxy-*)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

ICON_DB="󰆼"

# Find active proxy sessions created by p4p.sh
# They are named "sql-proxy-<profile>"
PROXY_SESSIONS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^sql-proxy-")

if [[ -z "$PROXY_SESSIONS" ]]; then
    echo ""
    exit 0
fi

OUTPUT=""

while read -r session; do
    PROFILE="${session#sql-proxy-}"

    case "$PROFILE" in
        *stage*|*STAGING*)    TEXT_COLOR="$P4_OSHEN_TEAL" ;;
        *PROD*|*production*)  TEXT_COLOR="$P4_OSHEN_RED" ;;
        *dev*|*local*)        TEXT_COLOR="$P4_OSHEN_GREEN" ;;
        *)                    TEXT_COLOR="$P4_OSHEN_TEAL" ;;
    esac

    [[ -n "$OUTPUT" ]] && OUTPUT="$OUTPUT "

    OUTPUT="${OUTPUT}#[fg=${TEXT_COLOR},bg=${P4_OSHEN_BASE}]${ICON_DB} ${PROFILE}"

done <<< "$PROXY_SESSIONS"

echo "#[fg=${P4_OSHEN_OVERLAY0},bg=${P4_OSHEN_BASE},none]│ $OUTPUT"
