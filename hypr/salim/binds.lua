-- Hyprland's default binds, plus vim-style hjkl next to the arrow keys.
-- See https://wiki.hypr.land/configuring/core/binds/
--     https://wiki.hypr.land/configuring/core/dispatchers/

local mainMod = "SUPER"

local terminal    = "ghostty"
local fileManager = "ghostty -e yazi"
local menu        = "wofi --show drun"

local function bind(keys, dispatcher, flags)
    hl.bind(mainMod .. " + " .. keys, dispatcher, flags)
end

-- Apps and windows
bind("Q", hl.dsp.exec_cmd(terminal))
bind("C", hl.dsp.window.close())
bind("M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
bind("E", hl.dsp.exec_cmd(fileManager))
bind("R", hl.dsp.exec_cmd(menu))
bind("V", hl.dsp.window.float({ action = "toggle" }))
bind("F", hl.dsp.window.fullscreen())
bind("P", hl.dsp.window.pseudo())
bind("T", hl.dsp.layout("togglesplit")) -- dwindle only (default is SUPER+J, now focus down)

-- Focus with arrows or hjkl; SHIFT moves the window instead
local directions = {
    left  = { "left",  "H" },
    down  = { "down",  "J" },
    up    = { "up",    "K" },
    right = { "right", "L" },
}
for dir, keys in pairs(directions) do
    for _, key in ipairs(keys) do
        bind(key,              hl.dsp.focus({ direction = dir }))
        bind("SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
    end
end

-- Workspaces: SUPER + [0-9] switches, SUPER + SHIFT + [0-9] moves the window
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(tostring(key),             hl.dsp.focus({ workspace = i }))
    bind("SHIFT + " .. key,         hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
bind("S",         hl.dsp.workspace.toggle_special("magic"))
bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces
bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with LMB/RMB drag
bind("mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys (keyboard knob / media row); work on the lock screen too
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
