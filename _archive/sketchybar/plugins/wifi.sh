#!/bin/bash

# WiFi Plugin
# Path: ~/.config/sketchybar/plugins/wifi.sh

# Load colors
source "$HOME/.config/sketchybar/colors.sh"

# Function to get WiFi SSID
get_wifi_ssid() {
    # Method 1: Try networksetup with common interfaces
    for interface in en0 en1 en2; do
        local result=$(networksetup -getairportnetwork "$interface" 2>/dev/null)
        if [[ $result == "Current Wi-Fi Network: "* ]]; then
            local ssid=$(echo "$result" | sed 's/Current Wi-Fi Network: //')
            if [[ -n "$ssid" && "$ssid" != *"You are not associated"* ]]; then
                echo "$ssid"
                return 0
            fi
        fi
    done
    
    # Method 2: Use airport utility if available
    if command -v airport >/dev/null 2>&1; then
        local ssid=$(airport -I | awk -F': ' '/[^B]SSID/ {print $2}' | head -1)
        if [[ -n "$ssid" ]]; then
            echo "$ssid"
            return 0
        fi
    fi
    
    # Method 3: Use system_profiler (slower but reliable)
    local ssid=$(system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network/{getline; getline; if ($1 != "Error:") print $0}' | sed 's/^[[:space:]]*//' | head -1)
    if [[ -n "$ssid" && "$ssid" != *"Error:"* && "$ssid" != *"Current Network Information:"* ]]; then
        echo "$ssid"
        return 0
    fi
    
    return 1
}

# Get WiFi status
WIFI_SSID=$(get_wifi_ssid)

if [[ -z "$WIFI_SSID" ]]; then
    # Disconnected or no WiFi
    sketchybar --set $NAME \
               icon=󰖪 \
               icon.color=$RED \
               label="Disconnected"
else
    # Connected - clean up and truncate if needed
    WIFI_SSID=$(echo "$WIFI_SSID" | tr -d '"' | xargs)
    
    # Truncate long network names
    if [ ${#WIFI_SSID} -gt 15 ]; then
        WIFI_SSID=$(echo "$WIFI_SSID" | cut -c 1-15)...
    fi
    
    sketchybar --set $NAME \
               icon=󰖩 \
               icon.color=$GREEN \
               label="$WIFI_SSID"
fi
