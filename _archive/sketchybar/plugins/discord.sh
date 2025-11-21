#!/bin/bash

# Enhanced Discord Plugin with Centralized Icons and Microphone Detection
# Path: ~/.config/sketchybar/plugins/discord.sh

# Load colors and icons
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Function to check if Discord is using microphone
check_discord_mic() {
    local discord_pid=$(pgrep -f "Discord")
    
    if [ -z "$discord_pid" ]; then
        echo "not_running"
        return
    fi
    
    # Method 1: Check if Discord is accessing microphone via system permissions
    # This checks if microphone permission is granted and potentially active
    local mic_permission=$(tccutil --list | grep -i discord | grep -i microphone 2>/dev/null || echo "")
    
    # Method 2: Check audio processes more specifically
    local audio_usage=""
    if command -v lsof >/dev/null 2>&1; then
        # Check if Discord has any audio device files open
        audio_usage=$(lsof -p "$discord_pid" 2>/dev/null | grep -E "(CoreAudio|AudioUnit|coreaudio)" | wc -l)
    fi
    
    # Method 3: Check system audio input levels (requires SwitchAudioSource or similar)
    # This is a fallback method
    local input_detected="false"
    if command -v SwitchAudioSource >/dev/null 2>&1; then
        # Check if default input device is being used
        local input_level=$(osascript -e "input volume of (get volume settings)" 2>/dev/null || echo "0")
        if [ "$input_level" -gt 0 ]; then
            input_detected="true"
        fi
    fi
    
    # Method 4: Check Control Center microphone indicator (macOS Big Sur+)
    # This requires checking if the microphone indicator is showing
    local cc_mic_active=""
    if command -v osascript >/dev/null 2>&1; then
        # Try to detect if microphone is in use system-wide
        cc_mic_active=$(osascript -e '
            tell application "System Events"
                try
                    set micStatus to (do shell script "system_profiler SPAudioDataType | grep -A 5 \"Built-in Microphone\" | grep -i \"in use\"")
                    if micStatus contains "Yes" then
                        return "active"
                    else
                        return "inactive"
                    end if
                on error
                    return "unknown"
                end try
            end tell
        ' 2>/dev/null)
    fi
    
    # Enhanced heuristic detection
    local frontmost_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
    
    # Decision logic
    if [ "$audio_usage" -gt 0 ] && [[ "$frontmost_app" == "Discord" ]]; then
        echo "mic_active"
    elif [ "$audio_usage" -gt 0 ]; then
        echo "mic_background"
    elif [[ "$cc_mic_active" == "active" ]] && [[ "$frontmost_app" == "Discord" ]]; then
        echo "mic_active"
    else
        echo "no_mic"
    fi
}

# Function to get Discord notification/message status
check_discord_notifications() {
    # This is a placeholder for notification detection
    # In practice, this would require more complex integration
    # For now, we'll use window title or badge detection
    
    local discord_pid=$(pgrep -f "Discord")
    if [ -z "$discord_pid" ]; then
        echo "none"
        return
    fi
    
    # Try to get Discord window title which sometimes contains notification info
    local window_title=$(osascript -e '
        tell application "System Events"
            try
                set discordWindows to (every window of application process "Discord")
                if (count of discordWindows) > 0 then
                    return name of item 1 of discordWindows
                else
                    return "Discord"
                end if
            on error
                return "Discord"
            end try
        end tell
    ' 2>/dev/null)
    
    # Check if window title indicates notifications (common patterns)
    if [[ "$window_title" == *"("*")"* ]]; then
        echo "notifications"
    else
        echo "none"
    fi
}

# Main logic
DISCORD_RUNNING=$(pgrep -f "Discord" > /dev/null && echo "true" || echo "false")

if [ "$DISCORD_RUNNING" = "true" ]; then
    DISCORD_FOCUSED=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
    MIC_STATUS=$(check_discord_mic)
    NOTIFICATION_STATUS=$(check_discord_notifications)
    
    # Determine icon, color, and label based on status
    case "$MIC_STATUS" in
        "mic_active")
            ICON="$ICON_DISCORD_MIC_ACTIVE"  # Microphone icon
            ICON_COLOR=$GREEN
            LABEL_COLOR=$GREEN
            BACKGROUND_COLOR=$SURFACE1
            if [[ "$DISCORD_FOCUSED" == "Discord" ]]; then
                LABEL="🎙️ Live"
            else
                LABEL="🎙️ Active"
            fi
            ;;
        "mic_background")
            ICON="$ICON_DISCORD_MIC_ACTIVE"  # Microphone icon  
            ICON_COLOR=$YELLOW
            LABEL_COLOR=$YELLOW
            BACKGROUND_COLOR=$SURFACE1
            LABEL="🎙️ Background"
            ;;
        *)
            # No mic usage
            ICON="$ICON_DISCORD"  # Discord icon
            if [[ "$NOTIFICATION_STATUS" == "notifications" ]]; then
                ICON_COLOR=$RED
                LABEL_COLOR=$RED
                BACKGROUND_COLOR=$SURFACE1
                LABEL="💬 Messages"
            elif [[ "$DISCORD_FOCUSED" == "Discord" ]]; then
                ICON_COLOR=$MAUVE
                LABEL_COLOR=$MAUVE
                BACKGROUND_COLOR=$SURFACE1
                LABEL="Discord"
            else
                ICON_COLOR=$LAVENDER
                LABEL_COLOR=$LAVENDER
                BACKGROUND_COLOR=$SURFACE0
                LABEL="Discord"
            fi
            ;;
    esac
else
    # Discord not running
    ICON="$ICON_DISCORD"
    ICON_COLOR=$SUBTEXT0
    LABEL_COLOR=$SUBTEXT0
    BACKGROUND_COLOR=$SURFACE0
    LABEL="Launch"
fi

# Update sketchybar item
sketchybar --set $NAME \
           icon="$ICON" \
           icon.color=$ICON_COLOR \
           icon.font="JetBrains Mono:Bold:16.0" \
           label="$LABEL" \
           label.color=$LABEL_COLOR \
           label.font="JetBrains Mono:Bold:12.0" \
           background.color=$BACKGROUND_COLOR \
           background.corner_radius=6 \
           background.height=24
