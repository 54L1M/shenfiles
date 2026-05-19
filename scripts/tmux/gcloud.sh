#!/bin/bash

# Tmux GCloud Auth Status Plugin
# Shows online (authenticated) or offline (needs p4g login)

COLOR_RED="#e05c6e"
COLOR_GREEN="#a8c97f"
COLOR_GRAY="#3d5570"
COLOR_BG="#0e1117"

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
    echo "#[fg=${COLOR_GRAY},bg=${COLOR_BG},none]│#[fg=${COLOR_RED},bg=${COLOR_BG}] $ICON_CLOUD offline "
else
    echo "#[fg=${COLOR_GRAY},bg=${COLOR_BG},none]│#[fg=${COLOR_GREEN},bg=${COLOR_BG}] $ICON_CLOUD gcloud "
fi
