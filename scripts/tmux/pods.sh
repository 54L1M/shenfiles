#!/bin/bash

# Tmux pod count plugin — shows namespace·count

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

cd "$HOME" 2>/dev/null

KUBECTL_CMD=""
for _p in "/opt/homebrew/bin/kubectl" "/usr/local/bin/kubectl" "$(command -v kubectl 2>/dev/null)"; do
    [[ -x "$_p" ]] && KUBECTL_CMD="$_p" && break
done

[[ -z "$KUBECTL_CMD" ]] && echo "" && exit 0

NS=$("$KUBECTL_CMD" config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
CTX=$("$KUBECTL_CMD" config current-context 2>/dev/null)
NS="${NS:-default}"

COUNT=$("$KUBECTL_CMD" get pods -n "$NS" --no-headers --request-timeout=2s 2>/dev/null | wc -l | tr -d ' ')
COUNT="${COUNT:-0}"

echo "#[fg=${P4_OSHEN_OVERLAY0},bg=${P4_OSHEN_BASE},none]│#[fg=${P4_OSHEN_TEAL},bg=${P4_OSHEN_BASE}] 󱃾 ${CTX}·${COUNT} "
