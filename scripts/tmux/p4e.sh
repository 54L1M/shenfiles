#!/bin/bash

# Tmux p4e Environment Plugin
# Displays the current active p4e environment for the active pane

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

ICON_ENV="󱇵"

PANE_ID="${1:-$(tmux display-message -p '#{pane_id}')}"

CURRENT_ENV=$(tmux show-options -p -v -t "$PANE_ID" @p4e_env 2>/dev/null)

if [[ -z "$CURRENT_ENV" ]]; then
    echo ""
    exit 0
fi

PROJECT="${CURRENT_ENV%%:*}"
ENV="${CURRENT_ENV#*:}"

case "$ENV" in
    *prod*|*PROD*|*production*)  TEXT_COLOR="$P4_OSHEN_RED" ;;
    *stage*|*STAGING*|*staging*) TEXT_COLOR="$P4_OSHEN_TEAL" ;;
    *dev*|*local*)               TEXT_COLOR="$P4_OSHEN_GREEN" ;;
    *)                           TEXT_COLOR="$P4_OSHEN_LAVENDER" ;;
esac

ENV_INITIAL=$(printf '%s' "${ENV:0:1}" | tr '[:lower:]' '[:upper:]')
PROJECT_DISPLAY=$(printf '%s' "$PROJECT" | tr '[:lower:]' '[:upper:]')
OUTPUT="#[fg=${TEXT_COLOR},bg=${P4_OSHEN_BASE}]${ICON_ENV} ${PROJECT_DISPLAY}(${ENV_INITIAL})"

echo "$OUTPUT #[fg=${P4_OSHEN_OVERLAY0},bg=${P4_OSHEN_BASE},none]│"
