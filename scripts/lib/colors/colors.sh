#!/usr/bin/env bash
# colors.sh - Common utility functions for colorful output

# ====================================
# Color and Formatting Helper Functions
# ====================================

# Define ANSI color codes
export P4_RESET="\033[0m"
export P4_BLACK="\033[30m"
export P4_RED="\033[31m"
export P4_GREEN="\033[32m"
export P4_YELLOW="\033[33m"
export P4_BLUE="\033[34m"
export P4_MAGENTA="\033[35m"
export P4_CYAN="\033[36m"
export P4_WHITE="\033[37m"

# Define ANSI background color codes
export P4_BG_BLACK="\033[40m"
export P4_BG_RED="\033[41m"
export P4_BG_GREEN="\033[42m"
export P4_BG_YELLOW="\033[43m"
export P4_BG_BLUE="\033[44m"
export P4_BG_MAGENTA="\033[45m"
export P4_BG_CYAN="\033[46m"
export P4_BG_WHITE="\033[47m"

# Define ANSI text formatting
export P4_BOLD="\033[1m"
export P4_DIM="\033[2m"
export P4_ITALIC="\033[3m"
export P4_UNDERLINE="\033[4m"
export P4_BLINK="\033[5m"
export P4_REVERSE="\033[7m"
export P4_HIDDEN="\033[8m"

# Define emoji icons for different message types
export P4_ICON_INFO="ℹ️ "
export P4_ICON_SUCCESS="✅ "
export P4_ICON_WARNING="⚠️ "
export P4_ICON_ERROR="❌ "
export P4_ICON_DEBUG="🔍 "
export P4_ICON_STEP="🔄 "
export P4_ICON_TIP="💡 "
export P4_ICON_QUESTION="❓ "

# Enable/disable colors based on terminal capabilities and environment
P4_USE_COLORS=1
if [ -n "${NO_COLOR}" ] || [ -n "${P4_NO_COLOR}" ] || [ ! -t 1 ]; then
  P4_USE_COLORS=0
fi

# Function to disable colors
p4_disable_colors() {
  P4_USE_COLORS=0
}

# Function to enable colors
p4_enable_colors() {
  if [ -t 1 ]; then
    P4_USE_COLORS=1
  fi
}

# Function to check if colors are enabled
p4_colors_enabled() {
  [ "$P4_USE_COLORS" -eq 1 ]
}

# Function to apply color formatting, only if colors are enabled
p4_color() {
  local color_code="$1"
  local text="$2"

  if p4_colors_enabled; then
    echo -e "${color_code}${text}${P4_RESET}"
  else
    echo -e "$text"
  fi
}

# ====================================
# Formatted Output Functions
# ====================================

# Print a header with background color
p4_header() {
  local text="$1"
  local padding="$(printf '%*s' ${#text} | tr ' ' '=')"

  echo
  if p4_colors_enabled; then
    echo -e "${P4_BOLD}${P4_BG_BLUE}${P4_WHITE} ${text} ${P4_RESET}"
  else
    echo -e "=== ${text} ==="
  fi
  echo
}

# Print title for a section
p4_title() {
  local text="$1"

  if p4_colors_enabled; then
    echo -e "${P4_BOLD}${P4_CYAN}${text}${P4_RESET}"
  else
    echo -e "${text}"
  fi
}

# Print a command with its description
p4_cmd() {
  local cmd="$1"
  local args="$2"
  local description="$3"

  if p4_colors_enabled; then
    printf "  ${P4_GREEN}%-10s${P4_RESET} ${P4_YELLOW}%-30s${P4_RESET}  ${description}\n" "$cmd" "$args"
  else
    printf "  %-10s %-30s  %s\n" "$cmd" "$args" "$description"
  fi
}

# Print an example command with its description
p4_example() {
  local cmd="$1"
  local description="$2"

  if p4_colors_enabled; then
    printf "  ${P4_CYAN}%-40s${P4_RESET}  ${description}\n" "$cmd"
  else
    printf "  %-40s  %s\n" "$cmd" "$description"
  fi
}

# Print an item with description
p4_item() {
  local name="$1"
  local description="$2"

  if p4_colors_enabled; then
    printf "  ${P4_BOLD}${P4_BLUE}%-15s${P4_RESET}  ${description}\n" "$name"
  else
    printf "  %-15s  %s\n" "$name" "$description"
  fi
}

# Print an info message
p4_info() {
  local message="$1"

  if p4_colors_enabled; then
    echo -e "${P4_ICON_INFO} ${P4_BLUE}${message}${P4_RESET}"
  else
    echo -e "INFO: ${message}"
  fi
}

# Print a success message
p4_success() {
  local message="$1"

  if p4_colors_enabled; then
    echo -e "${P4_ICON_SUCCESS} ${P4_GREEN}${message}${P4_RESET}"
  else
    echo -e "SUCCESS: ${message}"
  fi
}

# Print a warning message
p4_warn() {
  local message="$1"

  if p4_colors_enabled; then
    echo -e "${P4_ICON_WARNING} ${P4_YELLOW}${message}${P4_RESET}"
  else
    echo -e "WARNING: ${message}"
  fi
}

# Print an error message
p4_error() {
  local message="$1"

  if p4_colors_enabled; then
    echo -e "${P4_ICON_ERROR} ${P4_RED}${message}${P4_RESET}" >&2
  else
    echo -e "ERROR: ${message}" >&2
  fi
}

# Print a debug message (only when DEBUG is enabled)
p4_debug() {
  if [ -n "$P4_DEBUG" ]; then
    local message="$1"

    if p4_colors_enabled; then
      echo -e "${P4_ICON_DEBUG} ${P4_DIM}${message}${P4_RESET}" >&2
    else
      echo -e "DEBUG: ${message}" >&2
    fi
  fi
}

# Print a step message (for progress indication)
p4_step() {
  local message="$1"

  if p4_colors_enabled; then
    echo -e "${P4_ICON_STEP} ${P4_MAGENTA}${message}${P4_RESET}"
  else
    echo -e "STEP: ${message}"
  fi
}

# Print a tip message
p4_tip() {
  local message="$1"

  if p4_colors_enabled; then
    echo -e "${P4_ICON_TIP} ${P4_CYAN}${message}${P4_RESET}"
  else
    echo -e "TIP: ${message}"
  fi
}

# Highlight text
p4_highlight() {
  local text="$1"

  if p4_colors_enabled; then
    echo -e "${P4_BOLD}${P4_WHITE}${text}${P4_RESET}"
  else
    echo -e "${text}"
  fi
}

# Print colored text
p4_print_colored() {
  local color="$1"
  local text="$2"

  if p4_colors_enabled; then
    echo -e "${color}${text}${P4_RESET}"
  else
    echo -e "${text}"
  fi
}

# Format a timestamp
function format_timestamp() {
  local format="${1:-%Y-%m-%d %H:%M:%S}"
  date +"$format"
}

# Log a message with timestamp
function log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(format_timestamp)

  case "$level" in
  "INFO") p4_print_colored "$P4_BLUE" "[$timestamp] [INFO] $message" ;;
  "SUCCESS") p4_print_colored "$P4_GREEN" "[$timestamp] [SUCCESS] $message" ;;
  "WARN") p4_print_colored "$P4_YELLOW" "[$timestamp] [WARNING] $message" ;;
  "ERROR") p4_print_colored "$P4_RED" "[$timestamp] [ERROR] $message" >&2 ;;
  "DEBUG")
    if [ -n "$P4_DEBUG" ]; then
      p4_print_colored "$P4_DIM" "[$timestamp] [DEBUG] $message" >&2
    fi
    ;;
  *) echo "[$timestamp] [$level] $message" ;;
  esac
}

# Log wrapper functions
function log_info() { log_message "INFO" "$1"; }
function log_success() { log_message "SUCCESS" "$1"; }
function log_warn() { log_message "WARN" "$1"; }
function log_error() { log_message "ERROR" "$1"; }
function log_debug() { log_message "DEBUG" "$1"; }
