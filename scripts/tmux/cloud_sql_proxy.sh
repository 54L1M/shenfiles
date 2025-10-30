#!/bin/bash

SESSION_NAME="sql-proxy"
LOGFILE="/tmp/cloud-sql-proxy.log" 

PROXY_BINARY_PATH="$HOME/Documents/Workstation/In2Dialog/I2D_ATS/cloud-sql-proxy"

PROXY_OPTIONS="--port 5433 i2d-cloud:europe-west4:ats-db-production 2>&1 | tee $LOGFILE"

PROXY_COMMAND="$PROXY_BINARY_PATH $PROXY_OPTIONS"


case "$1" in
  start)
    # 1. Create an empty log file to prevent 'tail' from failing
    touch $LOGFILE

    # 2. Start the proxy (if not already running)
    tmux has-session -t $SESSION_NAME 2>/dev/null || \
      tmux new-session -d -s $SESSION_NAME "bash -c \"$PROXY_COMMAND\""

    # 3. Wait for the proxy to start and write to the log
    #    We wait max 5 seconds for the logfile to be non-empty.
    c=0
    while [ ! -s "$LOGFILE" ] && [ $c -lt 50 ]; do
      sleep 0.1
      c=$((c+1))
    done

    # 4. Open the popup to view the log
    tmux display-popup -T "#[align=centre]Cloud SQL Proxy" -h 60% -w 80% -S "bg=default" \
      "tail -f $LOGFILE"
    tmux display-message "Cloud SQL Proxy popup closed."
    ;;

  stop)
    tmux kill-session -t $SESSION_NAME 2>/dev/null
    rm $LOGFILE 2>/dev/null
    tmux display-message "Cloud SQL Proxy session stopped."
    ;;

  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
