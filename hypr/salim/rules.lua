-- Window and workspace rules.
-- See https://wiki.hypr.land/configuring/core/rules/
-- Find classes with `hyprctl clients`.

-- App -> workspace, same as the Mac (AeroSpace). Classes are regexes.
local assignments = {
    { class = [[^com\.mitchellh\.ghostty$]], workspace = "1" },
    { class = "^firefox$",                   workspace = "2" },
    { class = "^discord$",                   workspace = "3" },
}
for _, a in ipairs(assignments) do
    hl.window_rule({
        name      = "workspace-" .. a.workspace,
        match     = { class = a.class },
        workspace = a.workspace,
    })
end

-- Ignore maximize requests from all apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- hyprland-run window
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Wallpaper picker (walls pick): floating, centered
hl.window_rule({
    name  = "float-walls-picker",
    match = { class = "^walls$" },

    float  = true,
    size   = "monitor_w*0.7 monitor_h*0.7",
    center = true,
})

-- "Smart gaps" (no gaps when only one window), uncomment to enable:
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
