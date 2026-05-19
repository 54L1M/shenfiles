#!/usr/bin/env bash
# P4_DESC: Log viewer — unified tail for proxy logs, k8s pods, and tmux server windows

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

export PATH="/Users/54l1m/Downloads/google-cloud-sdk/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

P4M_CONFIG="$HOME/.config/p4/p4m.yaml"
LINES=50
SINCE=""
NAMESPACE=""

function show_help() {
    p4_header "p4l - Unified Log Viewer"
    p4_info "Usage: p4l [command] [options]"
    echo
    p4_title "Commands:"
    p4_cmd "(none)" "" "fzf over all discovered log sources"
    p4_cmd "proxy" "[profile]" "Tail a cloud-sql proxy log"
    p4_cmd "pod" "[pod-name]" "Stream k8s pod logs"
    p4_cmd "-h, --help" "" "Show this help"
    echo
    p4_title "Options:"
    p4_cmd "--lines, -n" "<N>" "History lines to show (default: 50)"
    p4_cmd "--since" "<duration>" "K8s logs since duration (e.g. 5m, 1h)"
    p4_cmd "--ns" "<namespace>" "K8s namespace override"
}

function find_kubectl() {
    for _p in "/opt/homebrew/bin/kubectl" "/usr/local/bin/kubectl" "$(command -v kubectl 2>/dev/null)"; do
        [[ -x "$_p" ]] && echo "$_p" && return
    done
}

function build_source_list() {
    # Proxy logs
    for logfile in /tmp/cloud-sql-proxy-*.log; do
        [[ -f "$logfile" ]] || continue
        profile="${logfile#/tmp/cloud-sql-proxy-}"
        profile="${profile%.log}"
        echo "[proxy] $profile"
    done

    # K8s pods
    local kubectl_cmd
    kubectl_cmd=$(find_kubectl)
    if [[ -n "$kubectl_cmd" ]]; then
        local ns_flag=""
        [[ -n "$NAMESPACE" ]] && ns_flag="-n $NAMESPACE"
        "$kubectl_cmd" get pods --no-headers $ns_flag 2>/dev/null | \
            awk '{print "[pod]   " $1}'
    fi

    # Active p4m tmux server windows
    if command -v yq >/dev/null 2>&1 && [[ -f "$P4M_CONFIG" ]]; then
        yq eval 'keys | .[]' "$P4M_CONFIG" 2>/dev/null | while read -r session; do
            if tmux has-session -t "$session" 2>/dev/null; then
                if tmux list-windows -t "$session" -F '#W' 2>/dev/null | grep -q "^server$"; then
                    echo "[tmux]  $session:server"
                fi
            fi
        done
    fi
}

function tail_proxy() {
    local profile="$1"
    local logfile="/tmp/cloud-sql-proxy-${profile}.log"

    if [[ ! -f "$logfile" ]]; then
        p4_error "Proxy log not found: $logfile"
        p4_tip "Start a proxy with: p4p start $profile"
        exit 1
    fi

    p4_info "Tailing proxy log: $logfile"
    p4_tip "Press Ctrl-C to stop (proxy keeps running)"
    tail -f -n "$LINES" "$logfile"
}

function tail_pod() {
    local pod="$1"
    local kubectl_cmd
    kubectl_cmd=$(find_kubectl)

    if [[ -z "$kubectl_cmd" ]]; then
        p4_error "kubectl not found"
        exit 1
    fi

    local ns_flag=""
    [[ -n "$NAMESPACE" ]] && ns_flag="-n $NAMESPACE"

    local since_flag=""
    [[ -n "$SINCE" ]] && since_flag="--since=$SINCE"

    p4_info "Streaming pod: $pod"
    "$kubectl_cmd" logs -f --tail="$LINES" $ns_flag $since_flag "$pod"
}

function attach_tmux() {
    local target="$1"
    if tmux switch-client -t "$target" 2>/dev/null || tmux select-window -t "$target" 2>/dev/null; then
        return 0
    fi
    p4_error "Cannot attach to tmux target: $target"
}

function select_proxy() {
    local profiles
    profiles=$(ls /tmp/cloud-sql-proxy-*.log 2>/dev/null | sed 's|/tmp/cloud-sql-proxy-||; s|\.log||')
    [[ -z "$profiles" ]] && p4_warn "No running proxies found" && exit 0
    echo "$profiles" | fzf --header="Select proxy" --height=20% --reverse
}

function select_pod() {
    local kubectl_cmd
    kubectl_cmd=$(find_kubectl)
    [[ -z "$kubectl_cmd" ]] && p4_error "kubectl not found" && exit 1

    local ns_flag=""
    [[ -n "$NAMESPACE" ]] && ns_flag="-n $NAMESPACE"

    local pods
    pods=$("$kubectl_cmd" get pods --no-headers $ns_flag 2>/dev/null | awk '{print $1}')
    [[ -z "$pods" ]] && p4_warn "No pods found" && exit 0

    echo "$pods" | fzf --header="Select pod" --height=30% --reverse
}

function tail_source() {
    local source="$1"
    local type="${source%% *}"
    local target="${source##* }"

    case "$type" in
        "[proxy]") tail_proxy "$target" ;;
        "[pod]")   tail_pod "$target" ;;
        "[tmux]")  attach_tmux "$target" ;;
    esac
}

function interactive_select() {
    local sources
    sources=$(build_source_list)

    if [[ -z "$sources" ]]; then
        p4_warn "No log sources found"
        p4_tip "Start a proxy (p4p start), have running k8s pods, or launch a p4m session"
        exit 0
    fi

    local kubectl_cmd
    kubectl_cmd=$(find_kubectl)

    local selected
    selected=$(echo "$sources" | fzf \
        --header="Select Log Source | Ctrl-R: Reload" \
        --preview='
            type=$(echo "{}" | awk "{print \$1}")
            target=$(echo "{}" | awk "{print \$2}")
            case "$type" in
                "[proxy]") tail -n 10 "/tmp/cloud-sql-proxy-${target}.log" 2>/dev/null || echo "(log empty)" ;;
                "[pod]")   kubectl logs --tail=10 "${target}" 2>/dev/null || echo "(cannot reach cluster)" ;;
                "[tmux]")  tmux capture-pane -p -t "${target}" 2>/dev/null | tail -15 || echo "(tmux unavailable)" ;;
            esac
        ' \
        --preview-window=down:12:wrap \
        --bind "ctrl-r:reload($(declare -f build_source_list P4M_CONFIG NAMESPACE find_kubectl); build_source_list)" \
        --height=60% --reverse \
        --color="header:blue,prompt:yellow,pointer:red")

    [[ -z "$selected" ]] && exit 0
    tail_source "$selected"
}

# Parse args
COMMAND=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) show_help; exit 0 ;;
        -n|--lines) LINES="$2"; shift 2 ;;
        --since) SINCE="$2"; shift 2 ;;
        --ns) NAMESPACE="$2"; shift 2 ;;
        proxy|pod) COMMAND="$1"; shift ;;
        *) break ;;
    esac
done

case "${COMMAND:-}" in
    proxy) tail_proxy "${1:-$(select_proxy)}" ;;
    pod)   tail_pod "${1:-$(select_pod)}" ;;
    *)     interactive_select ;;
esac
