#!/usr/bin/env bash
# walls - Pick and set the Hyprland wallpaper (hyprpaper). PC only.
# P4_DESC: Wallpapers — thumbnail picker and setter for hyprpaper

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

# Images: github:54L1M/walls, linked here by Home Manager (nix/hosts/pc/home.nix).
WALLS_DIR="${WALLS_DIR:-$HOME/Pictures/walls}"
# Symlink to the chosen image; hypr/hyprpaper.conf loads it at startup.
CURRENT="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
DEFAULT="gruvbox-nix.png"

show_help() {
    p4_header "walls - Wallpaper"
    p4_info "Usage: walls <command> [image]"
    echo
    p4_title "Commands:"
    p4_cmd "pick"            ""        "Thumbnail grid of $WALLS_DIR (Enter sets, Esc quits)"
    p4_cmd "set"             "<image>" "Set a wallpaper (path, or a file name in $WALLS_DIR)"
    p4_cmd "restore"         ""        "Start hyprpaper with the last wallpaper (used at login)"
    p4_cmd "current"         ""        "Print the current wallpaper path"
    p4_cmd "-h, --help"      ""        "Show this help"
    echo
    p4_title "Examples:"
    p4_example "walls pick"                "→ choose from thumbnails (SUPER+W)"
    p4_example "walls set gruvb99810.png"  "→ set one from the walls repo"
    p4_example "walls set ~/Downloads/x.jpg" "→ set any image"
}

monitors() {
    hyprctl monitors | awk '/^Monitor /{ print $2 }'
}

start_hyprpaper() {
    pgrep -x hyprpaper >/dev/null || setsid -f hyprpaper >/dev/null 2>&1
}

# Image argument -> absolute path. Symlinks are kept (realpath -s) so the
# saved choice points into ~/Pictures/walls, not a store path that gets GC'd.
resolve() {
    local img="$1"
    if [[ ! -f "$img" && -f "$WALLS_DIR/$img" ]]; then
        img="$WALLS_DIR/$img"
    fi
    [[ -f "$img" ]] || p4_die "Image not found: $1"
    realpath -s "$img"
}

cmd_set() {
    [[ -n "$1" ]] || p4_die "Usage: walls set <image>"
    local img mon
    img=$(resolve "$1") || exit 1

    mkdir -p "$(dirname "$CURRENT")"
    ln -sfn "$img" "$CURRENT"

    if pgrep -x hyprpaper >/dev/null; then
        # An empty monitor is silently ignored by hyprpaper, so set each one.
        for mon in $(monitors); do
            hyprctl hyprpaper wallpaper "$mon,$img,cover" >/dev/null \
                || p4_die "hyprpaper refused $img on $mon"
        done
    else
        start_hyprpaper
    fi
    p4_success "Wallpaper: $(basename "$img")"
}

cmd_restore() {
    if [[ ! -e "$CURRENT" ]]; then
        mkdir -p "$(dirname "$CURRENT")"
        ln -sfn "$WALLS_DIR/$DEFAULT" "$CURRENT"
    fi
    start_hyprpaper
}

cmd_current() {
    [[ -L "$CURRENT" ]] || p4_die "No wallpaper set yet."
    readlink "$CURRENT"
}

cmd_pick() {
    command -v swayimg >/dev/null || p4_die "swayimg is required but not installed."
    [[ -d "$WALLS_DIR" ]] || p4_die "No wallpapers at $WALLS_DIR (run: just pc)"

    # Enter (gallery or full view) sets the wallpaper and quits.
    # Space opens the selected thumbnail full size; Esc goes back / quits.
    local lua
    lua=$(cat <<LUA
local function quote(s) return "'" .. (s:gsub("'", [['\'']])) .. "'" end
local function apply(img)
  if img then os.execute(quote("$SELF") .. " set " .. quote(img.path) .. " >/dev/null") end
  swayimg.exit()
end
swayimg.gallery.on_key("Return", function() apply(swayimg.gallery.get_image()) end)
swayimg.gallery.on_key("space",  function() swayimg.mode = "viewer" end)
swayimg.viewer.on_key("Return",  function() apply(swayimg.viewer.get_image()) end)
swayimg.viewer.on_key("Escape",  function() swayimg.mode = "gallery" end)
LUA
)
    swayimg --gallery --appid walls --execute "$lua" "$WALLS_DIR"
}

case "$1" in
    pick)          cmd_pick ;;
    set)           cmd_set "$2" ;;
    restore)       cmd_restore ;;
    current)       cmd_current ;;
    -h|--help|"")  show_help ;;
    *)             p4_error "Unknown command: $1"; echo; show_help; exit 1 ;;
esac
