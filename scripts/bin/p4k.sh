#!/usr/bin/env bash
# P4_DESC: Kubernetes switcher — fzf context and namespace switching with tmux integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

export PATH="/Users/54l1m/Downloads/google-cloud-sdk/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

KUBECTL_CMD=""
for _p in "/opt/homebrew/bin/kubectl" "/usr/local/bin/kubectl" "$(command -v kubectl 2>/dev/null)"; do
    [[ -x "$_p" ]] && KUBECTL_CMD="$_p" && break
done

function show_help() {
    p4_header "p4k - Kubernetes Context & Namespace Switcher"
    p4_info "Usage: p4k [command]"
    echo
    p4_title "Commands:"
    p4_cmd "ctx, context" "" "fzf-select and switch active kubeconfig context (default)"
    p4_cmd "ns, namespace" "" "fzf-select namespace in current context"
    p4_cmd "pods" "[namespace]" "fzf over pod list with describe preview"
    p4_cmd "status, s" "" "Print current context and namespace"
    p4_cmd "-h, --help" "" "Show this help"
}

function require_kubectl() {
    if [[ -z "$KUBECTL_CMD" ]]; then
        p4_error "kubectl not found in PATH"
        exit 1
    fi
}

function switch_context() {
    require_kubectl
    local contexts current
    contexts=$("$KUBECTL_CMD" config get-contexts -o name 2>/dev/null | sort)
    current=$("$KUBECTL_CMD" config current-context 2>/dev/null)

    if [[ -z "$contexts" ]]; then
        p4_warn "No kubeconfig contexts found"
        exit 0
    fi

    local selected
    selected=$(echo "$contexts" | fzf \
        --header="Switch Context | Current: ${current:-none}" \
        --preview="$KUBECTL_CMD config get-contexts {} 2>/dev/null" \
        --preview-window=down:4:wrap \
        --height=50% --reverse \
        --color="header:blue,prompt:yellow,pointer:red")

    [[ -z "$selected" ]] && exit 0

    "$KUBECTL_CMD" config use-context "$selected" >/dev/null
    p4_success "Context: $selected"
    [[ -n "$TMUX" ]] && tmux refresh-client -S
}

function switch_namespace() {
    require_kubectl
    local namespaces current_ns current_ctx
    current_ctx=$("$KUBECTL_CMD" config current-context 2>/dev/null)
    current_ns=$("$KUBECTL_CMD" config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
    namespaces=$("$KUBECTL_CMD" get namespaces -o name 2>/dev/null | sed 's|namespace/||' | sort)

    if [[ -z "$namespaces" ]]; then
        p4_warn "Cannot list namespaces (cluster may be offline)"
        exit 0
    fi

    local selected
    selected=$(echo "$namespaces" | fzf \
        --header="Switch Namespace | Context: ${current_ctx:-none} | Current NS: ${current_ns:-default}" \
        --preview="$KUBECTL_CMD get pods -n {} --no-headers 2>/dev/null | head -20 || echo '(no pods)'" \
        --preview-window=down:8:wrap \
        --height=50% --reverse \
        --color="header:blue,prompt:yellow,pointer:red")

    [[ -z "$selected" ]] && exit 0

    "$KUBECTL_CMD" config set-context "$current_ctx" --namespace="$selected" >/dev/null
    p4_success "Namespace: $selected (context: $current_ctx)"
    [[ -n "$TMUX" ]] && tmux refresh-client -S
}

function list_pods() {
    require_kubectl
    local ns_flag=""
    [[ -n "$1" ]] && ns_flag="-n $1"

    local pods
    pods=$("$KUBECTL_CMD" get pods $ns_flag --no-headers 2>/dev/null | awk '{print $1}')

    if [[ -z "$pods" ]]; then
        p4_warn "No pods found"
        exit 0
    fi

    local current_ns
    current_ns=$("$KUBECTL_CMD" config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
    current_ns="${1:-${current_ns:-default}}"

    local selected
    selected=$(echo "$pods" | fzf \
        --header="Pods in namespace: $current_ns | Enter: exec shell" \
        --preview="
            KUBE=$KUBECTL_CMD
            NS=$current_ns
            echo '=== Status & Uptime ==='
            \"\$KUBE\" get pod {} -n \"\$NS\" 2>/dev/null
            echo ''
            echo '=== Describe ==='
            \"\$KUBE\" describe pod {} -n \"\$NS\" 2>/dev/null | head -35
        " \
        --preview-window=right:60%:wrap \
        --height=80% --reverse \
        --color="header:blue,prompt:yellow,pointer:red")

    [[ -z "$selected" ]] && exit 0

    p4_info "Execing into pod: $selected (ns: $current_ns)"
    if ! "$KUBECTL_CMD" exec -it "$selected" -n "$current_ns" -- bash 2>/dev/null; then
        "$KUBECTL_CMD" exec -it "$selected" -n "$current_ns" -- sh
    fi
}

function show_status() {
    require_kubectl
    local ctx ns
    ctx=$("$KUBECTL_CMD" config current-context 2>/dev/null)
    ns=$("$KUBECTL_CMD" config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
    p4_info "Context:   $(p4_highlight "${ctx:-none}")"
    p4_info "Namespace: $(p4_highlight "${ns:-default}")"
}

case "${1:-ctx}" in
    ctx|context) switch_context ;;
    ns|namespace) switch_namespace ;;
    pods|p) list_pods "${2:-}" ;;
    status|s) show_status ;;
    -h|--help) show_help ;;
    *)
        p4_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
