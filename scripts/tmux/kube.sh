#!/bin/bash

# Tmux Kubernetes Context Plugin
# Ported from: ~/.config/sketchybar/plugins/kube.sh

# -----------------------------------------------------------------------------
# CONFIGURATION & COLORS (Gruvbox Material match)
# -----------------------------------------------------------------------------
# Hardcoding these to match your tmux.conf @thm_* variables
COLOR_RED="#ea6962"     # Prod
COLOR_YELLOW="#d8a657"  # Staging/Auth missing
COLOR_GREEN="#a9b665"   # Dev/Local
COLOR_BLUE="#7daea3"    # Default
COLOR_BG="#1d2021"      # Base Background
COLOR_GRAY="#595959"    # Overlay0 (Separators)
COLOR_FG="#ebdbb2"      # Text

# Icons
ICON_KUBE="󱃾" 

# -----------------------------------------------------------------------------
# PATHS & ENV
# -----------------------------------------------------------------------------
# Keep your specific SDK paths from the original script
export PATH="/Users/54l1m/Downloads/google-cloud-sdk/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

cd "$HOME" 2>/dev/null
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Find kubectl
KUBECTL_CMD=""
for kubectl_path in "/opt/homebrew/bin/kubectl" "/usr/local/bin/kubectl" "/usr/bin/kubectl" "$(command -v kubectl 2>/dev/null)"; do
    if [[ -x "$kubectl_path" ]]; then
        KUBECTL_CMD="$kubectl_path"
        break
    fi
done

# Check gcloud auth plugin
if command -v gke-gcloud-auth-plugin >/dev/null 2>&1; then
    GCLOUD_AUTH_AVAILABLE="true"
else
    GCLOUD_AUTH_AVAILABLE="false"
fi

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------
get_current_context() {
    [[ -n "$KUBECTL_CMD" ]] && "$KUBECTL_CMD" config current-context 2>/dev/null || echo ""
}

get_current_namespace() {
    [[ -n "$KUBECTL_CMD" ]] && "$KUBECTL_CMD" config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "default"
}

get_pod_count() {
    if [[ -n "$KUBECTL_CMD" && "$GCLOUD_AUTH_AVAILABLE" == "true" ]]; then
        # Reduced timeout to 2s to prevent tmux status lag
        "$KUBECTL_CMD" get pods --no-headers --request-timeout=2s 2>/dev/null | wc -l | tr -d ' ' || echo "0"
    else
        echo "0"
    fi
}

check_context_accessible() {
    [[ -z "$KUBECTL_CMD" ]] && echo "false" && return
    [[ "$GCLOUD_AUTH_AVAILABLE" == "false" ]] && echo "auth_missing" && return
    
    if "$KUBECTL_CMD" get --raw /api --request-timeout=2s >/dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}

truncate_context() {
    local context="$1"
    local max_length=${2:-15}
    if [ ${#context} -gt $max_length ]; then
        echo "${context:0:$max_length}..."
    else
        echo "$context"
    fi
}

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

# Default output (empty) if something is critical
OUTPUT=""

if [[ -z "$KUBECTL_CMD" ]]; then
    # Kubectl not found
    OUTPUT="#[fg=$COLOR_GRAY,bg=$COLOR_BG]$ICON_KUBE (no kubectl)"
else
    CURRENT_CONTEXT=$(get_current_context)
    
    if [[ -z "$CURRENT_CONTEXT" ]]; then
        # No context set
        OUTPUT="#[fg=$COLOR_GRAY,bg=$COLOR_BG]$ICON_KUBE (none)"
    else
        CURRENT_NAMESPACE=$(get_current_namespace)
        CONTEXT_ACCESSIBLE=$(check_context_accessible)
        DISPLAY_CONTEXT=$(truncate_context "$CURRENT_CONTEXT" 12)
        
        if [[ "$CONTEXT_ACCESSIBLE" == "true" ]]; then
            # Determine Color
            case "$CURRENT_CONTEXT" in
                *prod*|*production*)                         TEXT_COLOR="$COLOR_RED" ;;
                *stage*|*staging*|*stg*)                     TEXT_COLOR="$COLOR_YELLOW" ;;
                *dev*|*development*|*local*|*kind*|*docker*) TEXT_COLOR="$COLOR_GREEN" ;;
                *)                                           TEXT_COLOR="$COLOR_BLUE" ;;
            esac
            
            # Build Label
            LABEL="$DISPLAY_CONTEXT"
            # [[ "$CURRENT_NAMESPACE" != "default" && -n "$CURRENT_NAMESPACE" ]] && LABEL="$LABEL:$CURRENT_NAMESPACE"
            
            # Pod Count
            POD_COUNT=$(get_pod_count)
            [[ "$POD_COUNT" -gt 0 ]] && LABEL="$LABEL ($POD_COUNT)"
            
            OUTPUT="#[fg=$TEXT_COLOR,bg=$COLOR_BG]$ICON_KUBE $LABEL"
            
        elif [[ "$CONTEXT_ACCESSIBLE" == "auth_missing" ]]; then
            OUTPUT="#[fg=$COLOR_YELLOW,bg=$COLOR_BG]$ICON_KUBE $DISPLAY_CONTEXT (auth)"
        else
            OUTPUT="#[fg=$COLOR_RED,bg=$COLOR_BG]$ICON_KUBE $DISPLAY_CONTEXT (offline)"
        fi
    fi
fi

# Print final formatted string with a separator at the end
# The separator matches your tmux.conf style
echo "$OUTPUT #[fg=$COLOR_GRAY,bg=$COLOR_BG,none]"
