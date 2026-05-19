#!/bin/bash

# Tmux pod count plugin — shows namespace·count

COLOR_BLUE="#abdadc"
COLOR_GRAY="#3d5570"
COLOR_BG="#0e1117"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

cd "$HOME" 2>/dev/null

KUBECTL_CMD=""
for _p in "/opt/homebrew/bin/kubectl" "/usr/local/bin/kubectl" "$(command -v kubectl 2>/dev/null)"; do
    [[ -x "$_p" ]] && KUBECTL_CMD="$_p" && break
done

[[ -z "$KUBECTL_CMD" ]] && echo "" && exit 0

NS=$("$KUBECTL_CMD" config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
NS="${NS:-default}"

COUNT=$("$KUBECTL_CMD" get pods -n "$NS" --no-headers --request-timeout=2s 2>/dev/null | wc -l | tr -d ' ')
COUNT="${COUNT:-0}"

# Truncate namespace to 6 chars
if [[ ${#NS} -gt 6 ]]; then
    NS_DISPLAY="${NS:0:5}…"
else
    NS_DISPLAY="$NS"
fi

echo "#[fg=${COLOR_GRAY},bg=${COLOR_BG},none]│#[fg=${COLOR_BLUE},bg=${COLOR_BG}] 󱃾 ${NS_DISPLAY}·${COUNT} "
