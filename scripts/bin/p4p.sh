#!/bin/bash

# Cloud SQL Proxy Manager
# Usage: cloud_sql_proxy.sh {start|stop} [db_profile]

ENV_FILE="$HOME/.config/p4/p4p"
PROXY_BINARY_PATH="$HOME/.local/bin/cloud-sql-proxy"

# 1. Load Configuration
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Helper: Select Profile
select_profile() {
    local profiles=$(printenv | grep "^DB_INSTANCE_" | sed 's/^DB_INSTANCE_//' | cut -d= -f1)
    if [ -z "$profiles" ]; then echo "default"; return; fi
    
    if command -v fzf >/dev/null; then
        echo "$profiles" | fzf --header="Select Cloud SQL DB" --height=20% --reverse
    else
        echo "$profiles" | head -n 1
    fi
}

# Helper: Select Running Proxy (With Kill Bindings)
select_running_proxy() {
    # Command to list active proxy profiles (strips 'sql-proxy-')
    local list_cmd="tmux list-sessions -F '#S' 2>/dev/null | grep '^sql-proxy-' | sed 's/^sql-proxy-//'"
    
    # Logic to kill one proxy and remove its log
    # fzf replaces {} with the selected profile name
    local kill_one="bash -c 'tmux kill-session -t sql-proxy-{} 2>/dev/null; rm -f /tmp/cloud-sql-proxy-{}.log'"
    
    # Logic to kill ALL proxies
    # Re-runs list_cmd, then executes kill logic for every item
    local kill_all="bash -c \"$list_cmd | xargs -I {} bash -c 'tmux kill-session -t sql-proxy-{} 2>/dev/null; rm -f /tmp/cloud-sql-proxy-{}.log'\""

    eval "$list_cmd" | \
    fzf --header="Select Proxy to Stop | C-x: Kill Selected | C-a: Kill All" \
        --height=20% --reverse \
        --bind "ctrl-x:execute($kill_one)+reload($list_cmd)" \
        --bind "ctrl-a:execute($kill_all)+reload($list_cmd)"
}

case "$1" in
  start)
    TARGET_PROFILE="$2"
    if [ -z "$TARGET_PROFILE" ]; then
        TARGET_PROFILE=$(select_profile)
    fi
    
    if [ -z "$TARGET_PROFILE" ]; then exit 0; fi

    # --- Unique Session & Log Files ---
    SESSION_NAME="sql-proxy-${TARGET_PROFILE}"
    LOGFILE="/tmp/cloud-sql-proxy-${TARGET_PROFILE}.log"

    # Resolve variables
    if [ "$TARGET_PROFILE" != "default" ]; then
        VAR_INSTANCE="DB_INSTANCE_${TARGET_PROFILE}"
        VAR_PORT="DB_PORT_${TARGET_PROFILE}"
        INSTANCE="${!VAR_INSTANCE}"
        PORT="${!VAR_PORT}"
    else
        INSTANCE="${DB_INSTANCE}"
        PORT="${DB_PORT}"
    fi

    if [ -z "$INSTANCE" ]; then
        echo "Error: No instance configured for $TARGET_PROFILE"
        read -p "Press enter to exit"
        exit 1
    fi
    [ -z "$PORT" ] && PORT="5433"

    # Start Proxy if not running
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        touch "$LOGFILE"
        PROXY_CMD="$PROXY_BINARY_PATH --port $PORT $INSTANCE 2>&1 | tee $LOGFILE"
        
        tmux new-session -d -s "$SESSION_NAME" "bash -c \"echo 'Starting $TARGET_PROFILE...'; $PROXY_CMD\""
        echo "✅ Started proxy for $TARGET_PROFILE on port $PORT"
    else
        echo "⚠️  Proxy $TARGET_PROFILE is already running."
    fi

    # --- Non-blocking Log Streaming ---
    echo "-------------------------------------------------------"
    echo "Streaming logs for $TARGET_PROFILE."
    echo "Press ENTER (or Ctrl-C) to close this window (Proxy stays alive)."
    echo "-------------------------------------------------------"

    # Run tail in background and capture its PID
    tail -f "$LOGFILE" &
    TAIL_PID=$!

    # Cleanup function to kill tail when this script exits
    cleanup() {
        kill $TAIL_PID 2>/dev/null
    }
    
    # Trap EXIT (normal close) and INT (Ctrl-C)
    trap cleanup EXIT INT TERM

    # Wait for user input (Enter key)
    read -r _
    ;;

  stop)
    TARGET_PROFILE="$2"
    
    if [ -z "$TARGET_PROFILE" ]; then
        TARGET_PROFILE=$(select_running_proxy)
    fi

    # Only proceed if a selection was actually returned (i.e., user hit Enter)
    # If user used C-x/C-a to kill everything and backed out, this will be empty
    if [ -n "$TARGET_PROFILE" ]; then
        SESSION_NAME="sql-proxy-${TARGET_PROFILE}"
        LOGFILE="/tmp/cloud-sql-proxy-${TARGET_PROFILE}.log"
        
        if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            tmux kill-session -t "$SESSION_NAME"
            rm -f "$LOGFILE"
            echo "🛑 Stopped proxy: $TARGET_PROFILE"
        else
            echo "❌ No running proxy found for: $TARGET_PROFILE"
        fi
        sleep 1
    fi
    ;;
esac
