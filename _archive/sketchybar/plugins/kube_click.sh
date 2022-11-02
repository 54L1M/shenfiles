#!/bin/bash

# Kubernetes Click Script with Context Switching
# Path: ~/.config/sketchybar/plugins/kube_click.sh

# Function to get all available contexts
get_contexts() {
    if command -v kubectl >/dev/null 2>&1; then
        kubectl config get-contexts --output=name 2>/dev/null | sort
    fi
}

# Function to get current context
get_current_context() {
    if command -v kubectl >/dev/null 2>&1; then
        kubectl config current-context 2>/dev/null || echo ""
    fi
}

# Function to switch to next context
switch_to_next_context() {
    contexts=($(get_contexts))
    current_context=$(get_current_context)
    
    if [[ ${#contexts[@]} -eq 0 ]]; then
        echo "No contexts available"
        return 1
    fi
    
    if [[ ${#contexts[@]} -eq 1 ]]; then
        echo "Only one context available: ${contexts[0]}"
        return 0
    fi
    
    # Find current context index
    current_index=-1
    for i in "${!contexts[@]}"; do
        if [[ "${contexts[$i]}" == "$current_context" ]]; then
            current_index=$i
            break
        fi
    done
    
    # Calculate next index (wrap around)
    if [[ $current_index -eq -1 ]]; then
        next_index=0
    else
        next_index=$(( (current_index + 1) % ${#contexts[@]} ))
    fi
    
    next_context="${contexts[$next_index]}"
    
    # Switch context
    if kubectl config use-context "$next_context" >/dev/null 2>&1; then
        echo "Switched to context: $next_context"
        return 0
    else
        echo "Failed to switch to context: $next_context"
        return 1
    fi
}

# Function to show context menu (using osascript)
show_context_menu() {
    contexts=($(get_contexts))
    current_context=$(get_current_context)
    
    if [[ ${#contexts[@]} -eq 0 ]]; then
        osascript -e 'display alert "No Kubernetes contexts found" message "Please configure kubectl contexts first."' 2>/dev/null
        return 1
    fi
    
    # Build context list for dialog
    context_list=""
    for i in "${!contexts[@]}"; do
        context="${contexts[$i]}"
        if [[ "$context" == "$current_context" ]]; then
            context_list="$context_list● $context (current)\n"
        else
            context_list="$context_list○ $context\n"
        fi
    done
    
    # Show selection dialog
    selected_context=$(osascript -e "
        set contextList to \"$context_list\"
        set selectedContext to (choose from list (paragraphs of contextList) with title \"Kubernetes Contexts\" with prompt \"Select a context:\")
        if selectedContext is false then
            return \"\"
        else
            set selectedItem to item 1 of selectedContext
            -- Extract context name (remove bullet and current indicator)
            set selectedItem to do shell script \"echo '\" & selectedItem & \"' | sed 's/^[●○] //' | sed 's/ (current)$//'\"
            return selectedItem
        end if
    " 2>/dev/null)
    
    if [[ -n "$selected_context" && "$selected_context" != "$current_context" ]]; then
        if kubectl config use-context "$selected_context" >/dev/null 2>&1; then
            osascript -e "display notification \"Switched to: $selected_context\" with title \"Kubernetes\"" 2>/dev/null
        else
            osascript -e "display alert \"Failed to switch context\" message \"Could not switch to: $selected_context\"" 2>/dev/null
        fi
    fi
}

# Function to open kubectl tools
open_kubectl_tools() {
    # Try to open k9s if available, otherwise open terminal with kubectl
    if command -v k9s >/dev/null 2>&1; then
        osascript -e 'tell application "Alacritty" to activate' 2>/dev/null || open -a "Alacritty"
        sleep 0.5
        osascript -e 'tell application "System Events" to keystroke "k9s"' 2>/dev/null
        osascript -e 'tell application "System Events" to key code 36' 2>/dev/null  # Enter key
    elif command -v kubectl >/dev/null 2>&1; then
        osascript -e 'tell application "Alacritty" to activate' 2>/dev/null || open -a "Alacritty"
        sleep 0.5
        osascript -e 'tell application "System Events" to keystroke "kubectl get pods"' 2>/dev/null
    else
        open -a "Terminal"
    fi
}

# Handle different click types
case "$BUTTON" in
    "left")
        # Left click: Switch to next context
        switch_to_next_context
        if [[ $? -eq 0 ]]; then
            osascript -e "display notification \"Context switched\" with title \"Kubernetes\"" 2>/dev/null
        fi
        ;;
    "right")
        # Right click: Show context selection menu
        show_context_menu
        ;;
    "middle")
        # Middle click: Open kubectl tools (k9s or terminal)
        open_kubectl_tools
        ;;
    *)
        # Default: Switch to next context
        switch_to_next_context
        ;;
esac

# Force update the kube item immediately
~/.config/sketchybar/plugins/kube.sh
