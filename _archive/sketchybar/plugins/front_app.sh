#!/bin/bash

# Enhanced Front App Plugin with Centralized Icons
# Path: ~/.config/sketchybar/plugins/front_app.sh

# Load colors and icons
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

# Function to get app icon based on app name
get_app_icon() {
    local app_name="$1"
    
    # Return default icon if app name is empty
    if [ -z "$app_name" ]; then
        echo "$ICON_DEFAULT_APP"
        return
    fi
    
    case "$app_name" in
        # Browsers
        "Google Chrome"|"Chrome") echo "$ICON_CHROME" ;;
        "Firefox") echo "$ICON_FIREFOX" ;;
        "Safari") echo "$ICON_SAFARI" ;;
        "Arc") echo "$ICON_ARC" ;;
        
        # Development & Terminal
        "Alacritty") echo "$ICON_TERMINAL" ;;
        "Ghostty") echo "$ICON_TERMINAL_ALT" ;;
        "Terminal") echo "$ICON_TERMINAL_ALT" ;;
        "iTerm2") echo "$ICON_CONSOLE" ;;
        "Warp") echo "$ICON_COMMAND_PROMPT" ;;
        "Visual Studio Code"|"Code") echo "$ICON_CODE" ;;
        "Xcode") echo "$ICON_XCODE" ;;
        "GitHub Desktop") echo "$ICON_GITHUB" ;;
        "Docker Desktop") echo "$ICON_DOCKER" ;;
        
        # AI Applications
        "ChatGPT"|"OpenAI") echo "$ICON_AI_BRAIN" ;;
        "Claude"|"Anthropic") echo "$ICON_AI_BRAIN" ;;
        "Copilot"|"GitHub Copilot") echo "$ICON_AI_SPARKLES" ;;
        "Cursor") echo "$ICON_AI_LIGHTBULB" ;;
        "Replit") echo "$ICON_AI_ROBOT" ;;
        "Perplexity") echo "$ICON_AI_BRAIN" ;;
        "Midjourney") echo "$ICON_AI_SPARKLES" ;;
        "Stable Diffusion") echo "$ICON_AI_SPARKLES" ;;
        "Character.AI") echo "$ICON_AI_ROBOT" ;;
        "Jasper") echo "$ICON_AI_LIGHTBULB" ;;
        "Copy.ai") echo "$ICON_AI_LIGHTBULB" ;;
        
        # Communication
        "Discord") echo "$ICON_DISCORD" ;;
        "Slack") echo "$ICON_SLACK" ;;
        "Telegram") echo "$ICON_TELEGRAM" ;;
        "WhatsApp") echo "$ICON_WHATSAPP" ;;
        "Messages") echo "$ICON_MESSAGES" ;;
        "Mail") echo "$ICON_MAIL" ;;
        "Zoom") echo "$ICON_ZOOM" ;;
        
        # Media
        "Spotify") echo "$ICON_SPOTIFY" ;;
        "Music") echo "$ICON_MUSIC" ;;
        "VLC") echo "$ICON_VLC" ;;
        "QuickTime Player") echo "$ICON_QUICKTIME" ;;
        "Photos") echo "$ICON_PHOTOS" ;;
        "Photoshop") echo "$ICON_PHOTOSHOP" ;;
        "GIMP") echo "$ICON_GIMP" ;;
        
        # Productivity
        "Finder") echo "$ICON_FINDER" ;;
        "System Preferences"|"System Settings") echo "$ICON_SYSTEM_PREFS" ;;
        "Activity Monitor") echo "$ICON_ACTIVITY_MONITOR" ;;
        "Notion") echo "$ICON_NOTION" ;;
        "Obsidian") echo "$ICON_OBSIDIAN" ;;
        "Notes") echo "$ICON_NOTES" ;;
        "Calendar") echo "$ICON_CALENDAR" ;;
        "Reminders") echo "$ICON_REMINDERS" ;;
        
        # Office
        "Microsoft Word"|"Word") echo "$ICON_WORD" ;;
        "Microsoft Excel"|"Excel") echo "$ICON_EXCEL" ;;
        "Microsoft PowerPoint"|"PowerPoint") echo "$ICON_POWERPOINT" ;;
        "Pages") echo "$ICON_PAGES" ;;
        "Numbers") echo "$ICON_NUMBERS" ;;
        "Keynote") echo "$ICON_KEYNOTE" ;;
        
        # Games
        "Steam") echo "$ICON_STEAM" ;;
        
        # Utilities
        "1Password") echo "$ICON_PASSWORD_MANAGER" ;;
        "CleanMyMac") echo "$ICON_CLEANER" ;;
        "The Unarchiver") echo "$ICON_ARCHIVE" ;;
        "Trash (Full)"|"Trash") echo "$ICON_TRASH" ;;
        
        # IDEs & Editors
        "IntelliJ IDEA") echo "$ICON_INTELLIJ" ;;
        "PyCharm") echo "$ICON_PYCHARM" ;;
        "WebStorm") echo "$ICON_WEBSTORM" ;;
        "Vim"|"Neovim"|"MacVim") echo "$ICON_VIM" ;;
        "Emacs") echo "$ICON_EMACS" ;;
        "Sublime Text") echo "$ICON_SUBLIME" ;;
        "Atom") echo "$ICON_ATOM" ;;
        
        # Design
        "Figma") echo "$ICON_FIGMA" ;;
        "Sketch") echo "$ICON_SKETCH" ;;
        "Adobe Illustrator") echo "$ICON_ILLUSTRATOR" ;;
        "Adobe After Effects") echo "$ICON_AFTER_EFFECTS" ;;
        
        # Special cases
        "Desktop") echo "$ICON_DESKTOP" ;;
        
        # DEFAULT: Any app not listed above gets the default app icon
        *) 
            # Debug: log unknown apps (optional)
            # echo "Unknown app: $app_name" >> /tmp/sketchybar_unknown_apps.log
            echo "$ICON_DEFAULT_APP" 
            ;;
    esac
}

# Handle front app switched event
if [ "$SENDER" = "front_app_switched" ] && [ ! -z "$INFO" ]; then
    # Use the INFO variable provided by the event
    FRONT_APP="$INFO"
else
    # Fallback: get the focused application from aerospace
    FRONT_APP=$(aerospace list-windows --focused --format "%{app-name}" 2>/dev/null)
fi

# Handle empty result
if [ -z "$FRONT_APP" ]; then
    FRONT_APP="Desktop"
fi

# Get the appropriate icon for the app
APP_ICON=$(get_app_icon "$FRONT_APP")

# Truncate long app names
DISPLAY_NAME="$FRONT_APP"
if [ ${#FRONT_APP} -gt 20 ]; then
    DISPLAY_NAME=$(echo "$FRONT_APP" | cut -c 1-20)...
fi

# Update the sketchybar item with icon and label
sketchybar --set $NAME \
                 icon="$APP_ICON" \
                 icon.color=$RED \
                 icon.font="JetBrains Mono:Bold:16.0" \
                 label="$DISPLAY_NAME" \
                 label.font="JetBrains Mono:Bold:14.0"
