#!/bin/bash

# Custom GKE Kubernetes Context Plugin with your specific gcloud path
# Path: ~/.config/sketchybar/plugins/kube.sh

# Load colors and icons
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Set default NAME if not provided
NAME=${NAME:-kube}

# Add your specific gcloud SDK path first, then other common paths
export PATH="/Users/54l1m/Downloads/google-cloud-sdk/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Set working directory and KUBECONFIG
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

# Check if gke-gcloud-auth-plugin is available now
if command -v gke-gcloud-auth-plugin >/dev/null 2>&1; then
    GCLOUD_AUTH_AVAILABLE="true"
else
    GCLOUD_AUTH_AVAILABLE="false"
fi

# Function to get current kubectl context
get_current_context() {
    if [[ -n "$KUBECTL_CMD" ]]; then
        "$KUBECTL_CMD" config current-context 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Function to get current namespace
get_current_namespace() {
    if [[ -n "$KUBECTL_CMD" ]]; then
        "$KUBECTL_CMD" config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "default"
    else
        echo "default"
    fi
}

# Function to check if context is accessible
check_context_accessible() {
    if [[ -z "$KUBECTL_CMD" ]]; then
        echo "false"
        return
    fi
    
    # If gcloud auth plugin is not available, mark as auth missing
    if [[ "$GCLOUD_AUTH_AVAILABLE" == "false" ]]; then
        echo "auth_missing"
        return
    fi
    
    # Try API check with reasonable timeout for GKE
    if "$KUBECTL_CMD" get --raw /api --request-timeout=3s >/dev/null 2>&1; then
        echo "true"
        return
    fi
    
    echo "false"
}

# Function to get pod count
get_pod_count() {
    if [[ -n "$KUBECTL_CMD" && "$GCLOUD_AUTH_AVAILABLE" == "true" ]]; then
        "$KUBECTL_CMD" get pods --no-headers --request-timeout=3s 2>/dev/null | wc -l | tr -d ' ' || echo "0"
    else
        echo "0"
    fi
}

# Function to truncate long context names
truncate_context() {
    context="$1"
    max_length=${2:-15}
    
    if [ ${#context} -gt $max_length ]; then
        echo "${context:0:$max_length}..."
    else
        echo "$context"
    fi
}

# Main logic
if [[ -z "$KUBECTL_CMD" ]]; then
    # kubectl not available
    ICON="$ICON_KUBERNETES"
    ICON_COLOR="$SUBTEXT0"
    LABEL_COLOR="$SUBTEXT0"
    BACKGROUND_COLOR="$SURFACE0"
    LABEL="kubectl not found"
else
    CURRENT_CONTEXT=$(get_current_context)
    
    if [[ -z "$CURRENT_CONTEXT" ]]; then
        # No context set
        ICON="$ICON_KUBERNETES"
        ICON_COLOR="$YELLOW"
        LABEL_COLOR="$YELLOW"
        BACKGROUND_COLOR="$SURFACE0"
        LABEL="No context"
    else
        CURRENT_NAMESPACE=$(get_current_namespace)
        CONTEXT_ACCESSIBLE=$(check_context_accessible)
        
        # Truncate long context names
        DISPLAY_CONTEXT=$(truncate_context "$CURRENT_CONTEXT" 12)
        
        if [[ "$CONTEXT_ACCESSIBLE" == "true" ]]; then
            # Context is accessible - determine color based on context type
            case "$CURRENT_CONTEXT" in
                *prod*|*production*)
                    ICON="$ICON_KUBERNETES"
                    ICON_COLOR="$RED"
                    LABEL_COLOR="$RED"
                    BACKGROUND_COLOR="$SURFACE1"
                    ;;
                *stage*|*staging*|*stg*)
                    ICON="$ICON_KUBERNETES"
                    ICON_COLOR="$YELLOW"
                    LABEL_COLOR="$YELLOW"
                    BACKGROUND_COLOR="$SURFACE1"
                    ;;
                *dev*|*development*|*local*|*minikube*|*kind*|*docker-desktop*)
                    ICON="$ICON_KUBERNETES"
                    ICON_COLOR="$GREEN"
                    LABEL_COLOR="$GREEN"
                    BACKGROUND_COLOR="$SURFACE1"
                    ;;
                *)
                    ICON="$ICON_KUBERNETES"
                    ICON_COLOR="$BLUE"
                    LABEL_COLOR="$BLUE"
                    BACKGROUND_COLOR="$SURFACE1"
                    ;;
            esac
            
            # Build label with context and namespace
            if [[ "$CURRENT_NAMESPACE" != "default" && -n "$CURRENT_NAMESPACE" ]]; then
                LABEL="$DISPLAY_CONTEXT:$CURRENT_NAMESPACE"
            else
                LABEL="$DISPLAY_CONTEXT"
            fi
            
            # Add pod count for additional context
            POD_COUNT=$(get_pod_count)
            if [[ "$POD_COUNT" -gt 0 ]]; then
                LABEL="$LABEL ($POD_COUNT)"
            fi
            
        elif [[ "$CONTEXT_ACCESSIBLE" == "auth_missing" ]]; then
            # Context exists but auth plugin is missing
            ICON="$ICON_KUBERNETES"
            ICON_COLOR="$YELLOW"
            LABEL_COLOR="$YELLOW"
            BACKGROUND_COLOR="$SURFACE1"
            LABEL="$DISPLAY_CONTEXT (no auth)"
        else
            # Context exists but is not accessible
            ICON="$ICON_KUBERNETES"
            ICON_COLOR="$RED"
            LABEL_COLOR="$RED"
            BACKGROUND_COLOR="$SURFACE1"
            LABEL="$DISPLAY_CONTEXT (offline)"
        fi
    fi
fi

# Update sketchybar item
sketchybar --set "$NAME" \
           icon="$ICON" \
           icon.color="$ICON_COLOR" \
           icon.font="JetBrains Mono:Bold:16.0" \
           label="$LABEL" \
           label.color="$LABEL_COLOR" \
           label.font="JetBrains Mono:Bold:11.0" \
           background.color="$BACKGROUND_COLOR" \
           background.corner_radius=6 \
           background.height=24
