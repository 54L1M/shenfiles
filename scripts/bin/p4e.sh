#!/bin/bash

# p4e - Switch .env profiles and reload in tmux
# Usage: p4e [options] [search_path]

# Source your color library
source "$HOME/shenfiles/scripts/lib/colors/colors.sh"

# Display help message
function show_help() {
  p4_header "p4e - Environment Profile Switcher"
  p4_info "Usage: p4e [options] [path]"
  echo

  p4_title "Description:"
  echo "  Scans for configuration files matching '.env.*' and copies the"
  echo "  selected one to '.env'. Automatically reloads the environment"
  echo "  if running inside a Tmux pane."
  echo

  p4_title "Options:"
  p4_cmd "-h, --help" "" "Show this help message"
  echo

  p4_title "Arguments:"
  p4_cmd "path" "" "Directory to scan (default: current directory)"
  echo

  p4_title "Examples:"
  p4_example "p4e" "Scan current directory"
  p4_example "p4e ~/projects/backend" "Scan specific directory"
}

# Parse arguments
TARGET_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -*)
      p4_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

# Validate target directory
if [ ! -d "$TARGET_DIR" ]; then
    p4_error "Directory not found: $TARGET_DIR"
    exit 1
fi

ENV_FILE="$TARGET_DIR/.env"

# 1. Find available environment templates (e.g., .env.local, .env.prod)
# Excludes the active .env file itself
if [ -z "$(find "$TARGET_DIR" -maxdepth 1 -name ".env.*" -print -quit)" ]; then
    p4_error "No .env.* files found in $TARGET_DIR"
    p4_tip "Create files like .env.dev, .env.prod to use this script."
    exit 1
fi

# 2. Select profile using fzf
# We change directory to target briefly to make fzf output clean filenames
pushd "$TARGET_DIR" > /dev/null || exit
SELECTED_PROFILE=$(find . -maxdepth 1 -name ".env.*" -printf "%f\n" | \
    fzf --height=20% --reverse --header="Select Environment Profile" \
    --color="header:blue,prompt:yellow,pointer:red")
popd > /dev/null || exit

if [ -z "$SELECTED_PROFILE" ]; then
    echo "Selection cancelled."
    exit 0
fi

# 3. Update the .env file
p4_step "Switching to profile: $(p4_highlight "$SELECTED_PROFILE")"
cp "$TARGET_DIR/$SELECTED_PROFILE" "$ENV_FILE"

if [ $? -eq 0 ]; then
    p4_success "Updated .env"
    
    # 4. Automate sourcing in Tmux
    if [ -n "$TMUX" ]; then
        p4_step "Sourcing .env in current pane..."
        # Send keys to the current pane to source the file and verify the switch
        tmux send-keys -t "$TMUX_PANE" "source .env && clear && echo 'Environment switched to $SELECTED_PROFILE'" Enter
    else
        p4_warn "Not in Tmux. Run 'source .env' manually to apply changes."
    fi
else
    p4_error "Failed to copy profile."
    exit 1
fi
