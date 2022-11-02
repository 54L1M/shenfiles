return {
	"stevearc/oil.nvim",
	config = function()
		local oil = require("oil")
		local util = require("oil.util")
		local actions = require("oil.actions")

		oil.setup({
			keymaps = {
				["gd"] = {
					desc = "Toggle file detail view",
					callback = function()
						Detail = not Detail
						if Detail then
							require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
						else
							require("oil").set_columns({ "icon" })
						end
					end,
				},
			},
			float = {
				padding = 2,
				max_width = 120,
				max_height = 30,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
			},
			view_options = {
				show_hidden = true,
			},
		})

		vim.keymap.set("n", "-", function()
			oil.open_float()
			util.run_after_load(0, function()
				oil.open_preview()
			end)
		end, { desc = "Open Oil" })

		vim.api.nvim_create_autocmd("User", {
			group = vim.api.nvim_create_augroup("OilFloatCustom", {}),
			pattern = "OilEnter",
			callback = function()
				if util.is_floating_win() then
					vim.keymap.set("n", "<Esc>", actions.close.callback, {
						buffer = true,
					})
					vim.keymap.set("n", "q", actions.close.callback, {
						buffer = true,
					})
				end
			end,
		})
	end,
}
