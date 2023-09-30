-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- wezterm.on('update-right-status', function(window, pane)
function FindLast(haystack, needle)
    local i = haystack:match(".*" .. needle .. "()")
    if i == nil then return nil else return i - 1 end
end

--     window:set_right_status(window:active_workspace())
-- end)
wezterm.on('update-right-status', function(window, pane)
    -- Each element holds the text for a cell in a "powerline" style << fade
    local cells = {}

    -- Figure out the cwd and host of the current pane.
    -- This will pick up the hostname for the remote host if your
    -- shell is using OSC 7 on the remote host.
    local cwd = pane:get_current_working_dir()
    local workspacename = window:active_workspace()
    local slash = FindLast(cwd, "/")
    if slash then
        cwd = cwd:sub(slash + 1, cwd:len())
    end

    table.insert(cells, cwd)
    table.insert(cells, workspacename)

    -- The powerline < symbol
    local LEFT_ARROW = utf8.char(0xe0b3)
    -- The filled in variant of the < symbol
    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

    -- Color palette for the backgrounds of each cell
    local colors = {
        '#49f3fc',
        '#02ced9',
    }
    -- Foreground color for the text across the fade
    local text_fg = '#000'

    -- The elements to be formatted
    local elements = {}
    -- How many cells have been formatted
    local num_cells = 0

    -- Translate a cell into elements
    function push(text, is_last)
        local cell_no = num_cells + 1
        table.insert(elements, { Foreground = { Color = text_fg } })
        table.insert(elements, { Background = { Color = colors[cell_no] } })
        table.insert(elements, { Text = ' ' .. text .. ' ' })
        if not is_last then
            table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
            table.insert(elements, { Text = SOLID_LEFT_ARROW })
        end
        num_cells = num_cells + 1
    end

    while #cells > 0 do
        local cell = table.remove(cells, 1)
        push(cell, #cells == 0)
    end

    window:set_right_status(wezterm.format(elements))
end)


-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Github Dark'
config.font = wezterm.font 'Hack Nerd Font'
config.bidi_enabled = true
config.window_decorations = "NONE"
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
-- config.default_cwd = "Documents/0xshen/"
config.window_background_opacity = 0.75
-- config.text_background_opacity = 0.3
config.bidi_direction = "AutoLeftToRight"
config.leader = {
    key = ' ',
    mods = 'CTRL',
    timeout_milliseconds = 1000
}
config.keys = {
    { key = 'c', mods = 'LEADER', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|COMMANDS' } },
    { key = 'l', mods = 'LEADER', action = wezterm.action.ShowTabNavigator },
    { key = 't', mods = 'LEADER', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    {
        key = 'r',
        mods = 'LEADER',
        action = wezterm.action.PromptInputLine {
            description = wezterm.format {
                { Attribute = { Intensity = 'Bold' } },
                { Foreground = { AnsiColor = 'Fuchsia' } },
                { Text = 'Enter name for current tab' },
            },
            action = wezterm.action_callback(function(window, _, line)
                -- line will be `nil` if they hit escape without entering anything
                -- An empty string if they just hit enter
                -- Or the actual line of text they wrote
                if line then
                    window:active_tab():set_title(line)
                end
            end),
        }
    },
    {
        key = '-',
        mods = 'LEADER',
        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
        key = '=',
        mods = 'LEADER',
        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
        key = 'j',
        mods = 'CTRL|SHIFT',
        action = wezterm.action.ActivatePaneDirection 'Next',
    },
    {
        key = 'k',
        mods = 'CTRL|SHIFT',
        action = wezterm.action.ActivatePaneDirection 'Prev',
    },
    {
        key = 'w',
        mods = 'LEADER',
        action = wezterm.action.PromptInputLine {
            description = wezterm.format {
                { Attribute = { Intensity = 'Bold' } },
                { Foreground = { AnsiColor = 'Fuchsia' } },
                { Text = 'Enter name for new workspace' },
            },
            action = wezterm.action_callback(function(window, pane, line)
                -- line will be `nil` if they hit escape without entering anything
                -- An empty string if they just hit enter
                -- Or the actual line of text they wrote
                if line then
                    window:perform_action(
                        wezterm.action.SwitchToWorkspace {
                            name = line,
                        },
                        pane
                    )
                end
            end),
        },
    },
    {
        key = ';',
        mods = 'LEADER',
        action = wezterm.action.ShowLauncherArgs {
            flags = 'WORKSPACES',
        },
    },



}

-- and finally, return the configuration to wezterm
return config
