#!/usr/bin/env bash
# colors.sh - Common utility functions for colorful output

# ── Oshen Palette ─────────────────────────────────────────────────────────────
# Hex values for tmux format strings and direct reference.
# Maps to oshen/palette.lua — require("oshen").get_palette()
export P4_OSHEN_AMBER="#ffb703"      # keywords, numbers, cursors
export P4_OSHEN_CREAM="#f1faee"      # foreground alias
export P4_OSHEN_TEAL="#abdadc"       # functions, info
export P4_OSHEN_STEEL="#457b9d"      # borders, accents
export P4_OSHEN_NAVY="#1d3567"       # selection, deep UI chrome
export P4_OSHEN_CRUST="#060810"      # deepest bg
export P4_OSHEN_MANTLE="#090c12"     # panels, popups, sidebars
export P4_OSHEN_BASE="#0e1117"       # main editor background
export P4_OSHEN_SURFACE0="#131c2b"   # cursorline, word highlights
export P4_OSHEN_SURFACE1="#1e2d42"   # raised surfaces
export P4_OSHEN_SURFACE2="#2a3f58"   # hover states, picker selections
export P4_OSHEN_OVERLAY0="#3d5570"   # barely-visible guides
export P4_OSHEN_OVERLAY1="#526d82"   # comments, inactive line numbers
export P4_OSHEN_OVERLAY2="#6a8599"   # operators, punctuation
export P4_OSHEN_SUBTEXT0="#8899aa"   # secondary/dim info
export P4_OSHEN_SUBTEXT1="#b0c4d8"   # slightly brighter secondary
export P4_OSHEN_TEXT="#f1faee"       # main foreground
export P4_OSHEN_PEACH="#e8944a"      # warnings, orange-adjacent tokens
export P4_OSHEN_GREEN="#a8c97f"      # strings, git added
export P4_OSHEN_SKY="#7ab8d4"        # string escapes, special punctuation
export P4_OSHEN_LAVENDER="#c3a0d8"   # types, hints, constructors
export P4_OSHEN_RED="#e05c6e"        # errors, git deleted, exceptions

# ── Truecolor ANSI escape codes (24-bit, mapped to oshen palette) ─────────────
export P4_RESET="\033[0m"
export P4_BLACK="\033[38;2;14;17;23m"        # base
export P4_RED="\033[38;2;224;92;110m"        # red
export P4_GREEN="\033[38;2;168;201;127m"     # green
export P4_YELLOW="\033[38;2;255;183;3m"      # amber
export P4_BLUE="\033[38;2;171;218;220m"      # teal
export P4_MAGENTA="\033[38;2;195;160;216m"   # lavender
export P4_CYAN="\033[38;2;122;184;212m"      # sky
export P4_WHITE="\033[38;2;241;250;238m"     # text/cream

export P4_BG_BLACK="\033[48;2;14;17;23m"     # base
export P4_BG_RED="\033[48;2;224;92;110m"     # red
export P4_BG_GREEN="\033[48;2;168;201;127m"  # green
export P4_BG_YELLOW="\033[48;2;255;183;3m"   # amber
export P4_BG_BLUE="\033[48;2;171;218;220m"   # teal
export P4_BG_MAGENTA="\033[48;2;195;160;216m" # lavender
export P4_BG_CYAN="\033[48;2;122;184;212m"   # sky
export P4_BG_WHITE="\033[48;2;241;250;238m"  # text/cream

# Text modifiers (rendering attributes, not colors)
export P4_BOLD="\033[1m"
export P4_DIM="\033[2m"
export P4_ITALIC="\033[3m"
export P4_UNDERLINE="\033[4m"
export P4_BLINK="\033[5m"
export P4_REVERSE="\033[7m"
export P4_HIDDEN="\033[8m"

# Icons
export P4_ICON_INFO="ℹ️ "
export P4_ICON_SUCCESS="✅ "
export P4_ICON_WARNING="⚠️ "
export P4_ICON_ERROR="❌ "
export P4_ICON_DEBUG="🔍 "
export P4_ICON_STEP="🔄 "
export P4_ICON_TIP="💡 "
export P4_ICON_QUESTION="❓ "

# ── Color control ─────────────────────────────────────────────────────────────
P4_USE_COLORS=1
if [ -n "${NO_COLOR:-}" ] || [ -n "${P4_NO_COLOR:-}" ] || [ ! -t 1 ]; then
  P4_USE_COLORS=0
fi

p4_disable_colors() { P4_USE_COLORS=0; }
p4_enable_colors()  { [ -t 1 ] && P4_USE_COLORS=1; }
p4_colors_enabled() { [ "$P4_USE_COLORS" -eq 1 ]; }

p4_color() {
  local color_code="${1:-}" text="${2:-}"
  if p4_colors_enabled; then
    echo -e "${color_code}${text}${P4_RESET}"
  else
    echo -e "$text"
  fi
}

# ── Formatted output ──────────────────────────────────────────────────────────

p4_header() {
  local text="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_BOLD}${P4_BG_BLUE}${P4_WHITE} ${text} ${P4_RESET}"
  else
    echo -e "=== ${text} ==="
  fi
}

p4_title() {
  local text="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_BOLD}${P4_CYAN}${text}${P4_RESET}"
  else
    echo -e "${text}"
  fi
}

p4_cmd() {
  local cmd="${1:-}" args="${2:-}" description="${3:-}"
  if p4_colors_enabled; then
    printf "${P4_GREEN}%s${P4_RESET} ${P4_YELLOW}%s${P4_RESET} %s\n" "$cmd" "$args" "$description"
  else
    printf "%s %s %s\n" "$cmd" "$args" "$description"
  fi
}

p4_example() {
  local cmd="${1:-}" description="${2:-}"
  if p4_colors_enabled; then
    printf "${P4_CYAN}%s${P4_RESET} %s\n" "$cmd" "$description"
  else
    printf "%s %s\n" "$cmd" "$description"
  fi
}

p4_item() {
  local name="${1:-}" description="${2:-}"
  if p4_colors_enabled; then
    printf "${P4_BOLD}${P4_BLUE}%s${P4_RESET} %s\n" "$name" "$description"
  else
    printf "%s %s\n" "$name" "$description"
  fi
}

p4_info() {
  local message="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_ICON_INFO} ${P4_BLUE}${message}${P4_RESET}"
  else
    echo -e "INFO: ${message}"
  fi
}

p4_success() {
  local message="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_ICON_SUCCESS} ${P4_GREEN}${message}${P4_RESET}"
  else
    echo -e "SUCCESS: ${message}"
  fi
}

p4_warn() {
  local message="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_ICON_WARNING} ${P4_YELLOW}${message}${P4_RESET}"
  else
    echo -e "WARNING: ${message}"
  fi
}

p4_error() {
  local message="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_ICON_ERROR} ${P4_RED}${message}${P4_RESET}" >&2
  else
    echo -e "ERROR: ${message}" >&2
  fi
}

p4_debug() {
  if [ -n "${P4_DEBUG:-}" ]; then
    local message="${1:-}"
    if p4_colors_enabled; then
      echo -e "${P4_ICON_DEBUG} ${P4_DIM}${message}${P4_RESET}" >&2
    else
      echo -e "DEBUG: ${message}" >&2
    fi
  fi
}

p4_step() {
  local message="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_ICON_STEP} ${P4_MAGENTA}${message}${P4_RESET}"
  else
    echo -e "STEP: ${message}"
  fi
}

p4_tip() {
  local message="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_ICON_TIP} ${P4_CYAN}${message}${P4_RESET}"
  else
    echo -e "TIP: ${message}"
  fi
}

p4_highlight() {
  local text="${1:-}"
  if p4_colors_enabled; then
    echo -e "${P4_BOLD}${P4_WHITE}${text}${P4_RESET}"
  else
    echo -e "${text}"
  fi
}

p4_print_colored() {
  local color="${1:-}" text="${2:-}"
  if p4_colors_enabled; then
    echo -e "${color}${text}${P4_RESET}"
  else
    echo -e "${text}"
  fi
}

# ── Logging ───────────────────────────────────────────────────────────────────

format_timestamp() {
  local format="${1:-%Y-%m-%d %H:%M:%S}"
  date +"$format"
}

log_message() {
  local level="${1:-}" message="${2:-}"
  local timestamp
  timestamp=$(format_timestamp)
  case "$level" in
    "INFO")    p4_print_colored "$P4_BLUE"   "[$timestamp] [INFO] $message" ;;
    "SUCCESS") p4_print_colored "$P4_GREEN"  "[$timestamp] [SUCCESS] $message" ;;
    "WARN")    p4_print_colored "$P4_YELLOW" "[$timestamp] [WARNING] $message" ;;
    "ERROR")   p4_print_colored "$P4_RED"    "[$timestamp] [ERROR] $message" >&2 ;;
    "DEBUG")
      if [ -n "${P4_DEBUG:-}" ]; then
        p4_print_colored "$P4_DIM" "[$timestamp] [DEBUG] $message" >&2
      fi
      ;;
    *) echo "[$timestamp] [$level] $message" ;;
  esac
}

log_info()    { log_message "INFO"    "${1:-}"; }
log_success() { log_message "SUCCESS" "${1:-}"; }
log_warn()    { log_message "WARN"    "${1-}";  }
log_error()   { log_message "ERROR"   "${1:-}"; }
log_debug()   { log_message "DEBUG"   "${1:-}"; }

p4_confirm() {
  local prompt="${1:-Are you sure?}"
  echo -e "${P4_YELLOW}${prompt} (y/N)${P4_RESET}"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

p4_die() {
  p4_error "${1:-Unknown error}"
  exit "${2:-1}"
}
