return {
	"stevearc/oil.nvim",
	config = function()
		local oil = require("oil")
		oil.setup({
			view_options = {
				show_hidden = true,
			},
		})
		vim.keymap.set("n", "-", oil.toggle_float, { desc = "Open parent directory" })
	end,
}
