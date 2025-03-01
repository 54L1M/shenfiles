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

		-- Create commands for quick template access
		-- vim.api.nvim_create_user_command('GTLWork', function()
		--   require('p4template').new_note_from_template('work', '~/The Great Library/Work')
		-- end, {})
		--
		-- vim.api.nvim_create_user_command('GTLProject', function()
		--   require('p4template').new_note_from_template('project', '~/The Great Library/Projects')
		-- end, {})
		--
		-- vim.api.nvim_create_user_command('GTLLearn', function()
		--   require('p4template').new_note_from_template('learning', '~/The Great Library/Learning')
		-- end, {})
		--
		-- vim.api.nvim_create_user_command('GTLPersonal', function()
		--   require('p4template').new_note_from_template('personal', '~/The Great Library/Personal')
		-- end, {})
		--
		-- Autocommands for Neorg files
		-- vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
		--   pattern = {"*.norg"},
		--   callback = function()
		--     -- Set up Neorg-specific settings
		--     vim.opt_local.wrap = true
		--     vim.opt_local.conceallevel = 2
		--     -- Add custom keybindings
		--     vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>nt', ':P4Template<CR>', { noremap = true, silent = true })
		--     vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>nw', ':P4Work<CR>', { noremap = true, silent = true })
		--     vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>np', ':P4Project<CR>', { noremap = true, silent = true })
		--     vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>nl', ':P4Learning<CR>', { noremap = true, silent = true })
		--     vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>nj', ':P4Personal<CR>', { noremap = true, silent = true })
		--   end
		-- })
	end,
}
