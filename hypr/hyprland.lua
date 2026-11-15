-- Hyprland entry point: only require()s, settings live in salim/.
-- Same layout as nvim (init.lua + lua/salim/). Hyprland puts ~/.config/hypr
-- on package.path, so require("salim.x") loads salim/x.lua, and every reload
-- starts a fresh Lua state, so edited modules re-run.
-- Wiki: https://wiki.hypr.land/configuring/

require("salim.monitors")
require("salim.env")
require("salim.autostart")
require("salim.look")
require("salim.input")
require("salim.binds")
require("salim.rules")
