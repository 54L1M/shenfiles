return {
	"nvim-neorg/neorg",
	build = ":Neorg sync-parsers",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neorg").setup({
			load = {
				["core.defaults"] = {},
				["core.concealer"] = {
					config = {
						icon_preset = "varied",
					},
				},
				["core.dirman"] = {
					config = {
						workspaces = {
							library = "~/TheGreatLibrary",
						},
						default_workspace = "library",
					},
				},
				["core.completion"] = {
					config = {
						engine = "nvim-cmp",
					},
				},
				["core.ui.calendar"] = {
					config = {
						week_start_day = 1, -- 1 = Monday (0 = Sunday)
						default_view = "month", -- View modes: "day", "week", "month"
					},
				},
				["core.qol.toc"] = {},
				["core.export"] = {},
				["core.presenter"] = {
					config = {
						zen_mode = "zen-mode",
					},
				},
				["core.keybinds"] = {
					config = {
						default_keybinds = true,
						neorg_leader = "<Leader>n",
					},
				},
			},
		})

		-- Add keymappings for quick access to The Great Library
		vim.api.nvim_set_keymap("n", "<Leader>nl", ":Neorg workspace library<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap(
			"n",
			"<Leader>ni",
			":e ~/TheGreatLibrary/index.norg<CR>",
			{ noremap = true, silent = true }
		)
	end,
}
