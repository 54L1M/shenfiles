#!/bin/bash

#TODO: Add flags
#TODO: Add autocomplete
echo "============="
ls ~/Documents/0xshen/repos/
echo "============="
read projectName


tmux has-session -t $projectName &> /dev/null

if [[ $? != 0 ]]; then
   tmux new -s $projectName -n code -d 
   tmux neww -n terminal -t $projectName:
   tmux send-keys -t $projectName:0. "cd ~/Documents/0xshen/repos/$projectName/" C-m
   tmux send-keys -t $projectName:0. "clear" C-m
   tmux send-keys -t $projectName:1. "cd ~/Documents/0xshen/repos/$projectName/" C-m
   tmux send-keys -t $projectName:1. "clear" C-m
fi

tmux attach -t $projectName

