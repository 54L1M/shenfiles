#!/bin/bash

# p4e - Project Environment Switcher
# Usage: p4e [options] | p4e link [project]

# Source your color library
source "$HOME/shenfiles/scripts/lib/colors/colors.sh"

CONFIG_FILE="$HOME/.config/p4e/projects.yaml"
ARG_PROJECT=""
ARG_ENV=""
SHOW_ACTIVE=false

# Display help message
function show_help() {
  p4_header "p4e - Environment Profile Switcher"
  p4_info "Usage: p4e [options] [command]"
  echo
  p4_title "Commands:"
  p4_cmd "link" "[project]" "Create a symlink from .env -> ENV/.env in project root"
  echo
  p4_title "Options:"
  p4_cmd "-h, --help" "" "Show this help message"
  p4_cmd "-c, --config" "<file>" "Use alternative config file"
  p4_cmd "-p, --project" "<name>" "Pre-select a project from config"
  p4_cmd "-e, --env" "<name>" "Pre-select an env suffix (e.g. 'prod' for .env.prod)"
  p4_cmd "-a, --active" "" "Show the currently active environment in this shell"
  p4_info "  Note: -e requires -p to be set."
}

# Check dependencies early
if ! command -v yq >/dev/null 2>&1; then
    p4_error "yq is required but not installed."
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    p4_error "Config file not found: $CONFIG_FILE"
    exit 1
fi

# ==========================================
# ARGUMENT PARSING
# ==========================================
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -c|--config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    -p|--project)
      ARG_PROJECT="$2"
      shift 2
      ;;
    -e|--env)
      ARG_ENV="$2"
      shift 2
      ;;
    -a|--active)
      SHOW_ACTIVE=true
      shift
      ;;
    link)
      LINK_MODE=true
      shift
      LINK_ARG="$1"
      break
      ;;
    *)
      p4_error "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# ==========================================
# HANDLER: ACTIVE STATE (-a)
# ==========================================
if [ "$SHOW_ACTIVE" = true ]; then
    if [ -n "$P4E_CURRENT_ENV" ]; then
        p4_info "Active Environment: $(p4_highlight "$P4E_CURRENT_ENV")"
    else
        p4_warn "No environment active in this shell (P4E_CURRENT_ENV not set)"
    fi
    exit 0
fi

# ==========================================
# HANDLER: LINK COMMAND
# ==========================================
if [ "$LINK_MODE" = true ]; then
    PROJECT_NAME="$LINK_ARG"

    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(yq eval 'keys | .[]' "$CONFIG_FILE" | fzf --height=20% --reverse --header="Select Project to Link" --color="header:blue,prompt:yellow,pointer:red")
    fi

    if [ -z "$PROJECT_NAME" ]; then
        echo "No project selected."
        exit 0
    fi

    PROJECT_PATH=$(yq eval -r ".${PROJECT_NAME}.path" "$CONFIG_FILE")
    
    if [ "$PROJECT_PATH" == "null" ] || [ -z "$PROJECT_PATH" ]; then
         p4_error "Project '$PROJECT_NAME' not found in configuration."
         exit 1
    fi

    if [[ "$PROJECT_PATH" == ~* ]]; then
        PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"
    fi
    # Remove trailing slash if present to avoid //
    PROJECT_PATH="${PROJECT_PATH%/}"

    if [ ! -d "$PROJECT_PATH" ]; then
        p4_error "Project path not found: $PROJECT_PATH"
        exit 1
    fi

    TARGET="$PROJECT_PATH/.env"
    RELATIVE_SOURCE="ENV/.env"
    
    if [ -L "$TARGET" ]; then
        CURRENT_LINK=$(readlink "$TARGET")
        if [ "$CURRENT_LINK" == "$RELATIVE_SOURCE" ]; then
            p4_success "Symlink already correctly set for $PROJECT_NAME."
            exit 0
        else
            p4_warn "Symlink exists but points to: $CURRENT_LINK"
            read -p "Update it to $RELATIVE_SOURCE? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
        fi
    elif [ -f "$TARGET" ]; then
        p4_warn "A regular .env file exists at $TARGET"
        read -p "Backup and replace with symlink? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
        mv "$TARGET" "${TARGET}.bak.$(date +%s)"
        p4_success "Backed up original .env"
    fi

    cd "$PROJECT_PATH" || exit 1
    if [ ! -d "ENV" ]; then
        mkdir -p "ENV"
    fi
    
    ln -sf "$RELATIVE_SOURCE" .env
    p4_success "Linked .env -> ENV/.env in $PROJECT_PATH"
    exit 0
fi

# ==========================================
# MAIN LOGIC (Environment Switching)
# ==========================================

if [ -n "$ARG_ENV" ] && [ -z "$ARG_PROJECT" ]; then
    p4_error "The -e flag cannot be used without -p."
    show_help
    exit 1
fi

# 1. Select Project
if [ -n "$ARG_PROJECT" ]; then
    PROJECT_PATH=$(yq eval -r ".${ARG_PROJECT}.path" "$CONFIG_FILE")
    if [ "$PROJECT_PATH" == "null" ] || [ -z "$PROJECT_PATH" ]; then
         p4_error "Project '$ARG_PROJECT' not found in configuration."
         show_help
         exit 1
    fi
    PROJECT_NAME="$ARG_PROJECT"
else
    PROJECT_NAME=$(yq eval 'keys | .[]' "$CONFIG_FILE" | fzf --height=20% --reverse --header="Select Project" --color="header:blue,prompt:yellow,pointer:red")
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "No project selected."
        exit 0
    fi
    PROJECT_PATH=$(yq eval -r ".${PROJECT_NAME}.path" "$CONFIG_FILE")
fi

if [[ "$PROJECT_PATH" == ~* ]]; then
    PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"
fi
# Remove trailing slash
PROJECT_PATH="${PROJECT_PATH%/}"

if [ ! -d "$PROJECT_PATH" ]; then
    p4_error "Project directory not found: $PROJECT_PATH"
    exit 1
fi

ENV_DIR="$PROJECT_PATH/ENV"

if [ ! -d "$ENV_DIR" ]; then
    p4_error "ENV directory not found at: $ENV_DIR"
    p4_tip "Please create the directory and move your .env templates there."
    exit 1
fi

# 2. Select Environment Profile
CURRENT_FILE_STATE="Unknown"
if [ -f "$ENV_DIR/.env" ]; then
    SOURCE_LINE=$(grep "^# p4e_source:" "$ENV_DIR/.env" | head -n 1 | cut -d':' -f2 | xargs)
    [ -n "$SOURCE_LINE" ] && CURRENT_FILE_STATE="${SOURCE_LINE#.env.}"
fi

if [ -n "$ARG_ENV" ]; then
    SELECTED_PROFILE=".env.${ARG_ENV}"
    if [ ! -f "$ENV_DIR/$SELECTED_PROFILE" ]; then
        p4_error "Environment file '$SELECTED_PROFILE' not found in '$ENV_DIR'."
        p4_tip "Available environments:"
        ls -1a "$ENV_DIR" | grep "^.env\." | grep -v "^.env$" | sed 's/^.env./  - /'
        exit 1
    fi
else
    SELECTED_PROFILE=$(ls -1a "$ENV_DIR" | grep "^.env\." | grep -v "^.env$" | fzf --height=20% --reverse --header="Select Environment ($PROJECT_NAME) | Active File: $CURRENT_FILE_STATE" --color="header:green,prompt:blue,pointer:red")

    if [ -z "$SELECTED_PROFILE" ]; then
        echo "Selection cancelled."
        exit 0
    fi
fi

# 3. Apply Environment (with content check)
TARGET_ENV="$ENV_DIR/.env"
SOURCE_PATH="$ENV_DIR/$SELECTED_PROFILE"
ENV_SHORT_NAME="${SELECTED_PROFILE#.env.}"
SKIP_COPY=false

# Check if we are switching to the same environment that is already active
if [[ "$CURRENT_FILE_STATE" == "$ENV_SHORT_NAME" ]]; then
    # We are on the same env, but has the template changed?
    # Use 'cmp' to compare the active file (minus 3 header lines) with the source template
    if tail -n +4 "$TARGET_ENV" | cmp -s - "$SOURCE_PATH"; then
        p4_info "Already using $(p4_highlight "$SELECTED_PROFILE") (no changes detected)."
        SKIP_COPY=true
    else
        p4_warn "Changes detected in $(p4_highlight "$SELECTED_PROFILE"). Updating active environment..."
    fi
fi

if [ "$SKIP_COPY" = false ]; then
    p4_step "Applying $(p4_highlight "$SELECTED_PROFILE") to $(p4_highlight "$TARGET_ENV")..."

    # We use a temp file to ensure atomicity, then move it
    TMP_ENV="$TARGET_ENV.tmp"
    echo "# p4e_project: $PROJECT_NAME" > "$TMP_ENV"
    echo "# p4e_source: $SELECTED_PROFILE" >> "$TMP_ENV"
    echo "export P4E_CURRENT_ENV=$PROJECT_NAME:$ENV_SHORT_NAME" >> "$TMP_ENV"
    cat "$SOURCE_PATH" >> "$TMP_ENV"

    chmod 600 "$TMP_ENV"
    mv "$TMP_ENV" "$TARGET_ENV"

    if [ $? -eq 0 ]; then
        p4_success "Updated $TARGET_ENV"
    else
        p4_error "Failed to create .env file."
        exit 1
    fi
fi

# Check if symlink exists in project root
LINK_CHECK="$PROJECT_PATH/.env"
if [ ! -e "$LINK_CHECK" ]; then
    p4_warn "No valid .env symlink found in project root."
    p4_tip "Your app likely expects a .env file in the root."
    p4_tip "Run '$(p4_highlight "p4e link $PROJECT_NAME")' to fix this."
fi

# 4. Automate sourcing in Tmux (Invisible Command)
if [ -n "$TMUX" ]; then
    p4_step "Sourcing in current pane..."
    
    # The ANSI Trick:
    # 1. Execute source
    # 2. \033[1A moves cursor UP one line (to the command line)
    # 3. \033[2K clears that line completely
    # 4. \r prints our message over the spot where the command was
    CMD="source $TARGET_ENV"
    
    # C-u clears the shell prompt line before we paste our command
    tmux send-keys -t "$TMUX_PANE" "$CMD" Enter
else
    p4_warn "Not in Tmux. Run 'source $TARGET_ENV' manually to apply changes."
fi
