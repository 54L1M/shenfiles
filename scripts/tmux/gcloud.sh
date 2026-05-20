#!/bin/bash

# Tmux GCloud Auth Status Plugin
# Shows online (authenticated) or offline (needs p4g login)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

ICON_CLOUD="󰅟"

export PATH="/Users/54l1m/Downloads/google-cloud-sdk/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

cd "$HOME" 2>/dev/null

GCLOUD_CMD=""
for _p in "/Users/54l1m/Downloads/google-cloud-sdk/bin/gcloud" "/opt/homebrew/bin/gcloud" "$(command -v gcloud 2>/dev/null)"; do
    [[ -x "$_p" ]] && GCLOUD_CMD="$_p" && break
done

if [[ -z "$GCLOUD_CMD" ]]; then
    echo ""
    exit 0
fi

TOKEN=$(timeout 3 "$GCLOUD_CMD" auth print-access-token 2>/dev/null)

if [[ -z "$TOKEN" ]]; then
    echo "#[fg=${P4_OSHEN_OVERLAY0},bg=${P4_OSHEN_BASE},none]│#[fg=${P4_OSHEN_RED},bg=${P4_OSHEN_BASE}] $ICON_CLOUD GCS·off "
else
    echo "#[fg=${P4_OSHEN_OVERLAY0},bg=${P4_OSHEN_BASE},none]│#[fg=${P4_OSHEN_GREEN},bg=${P4_OSHEN_BASE}] $ICON_CLOUD GCS·on "
fi
