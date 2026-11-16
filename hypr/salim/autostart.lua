-- See https://wiki.hypr.land/configuring/core/autostart/
-- Runs once at login (not on config reload).

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("hyprpaper")
end)
