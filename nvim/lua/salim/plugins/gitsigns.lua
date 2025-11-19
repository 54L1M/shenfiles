return {
	{
		"lewis6991/gitsigns.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- local icons = require('config.icons')
			require("gitsigns").setup({
				signs = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signs_staged = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true,
				numhl = false,
				linehl = false,
				word_diff = false,
				watch_gitdir = {
					interval = 1000,
					follow_files = true,
				},
				attach_to_untracked = true,
				current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
					delay = 1000,
					ignore_whitespace = false,
				},
				current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
				sign_priority = 6,
				status_formatter = nil,
				update_debounce = 200,
				max_file_length = 40000,
				preview_config = {
					border = "rounded",
					style = "minimal",
					relative = "cursor",
					row = 0,
					col = 1,
				},
				-- yadm = { enable = false },

				on_attach = function(bufnr)
					vim.keymap.set("n", "]]", require("gitsigns").next_hunk, { buffer = bufnr, desc = "Next git hunk" })

					vim.keymap.set(
						"n",
						"[[",
						require("gitsigns").prev_hunk,
						{ buffer = bufnr, desc = "Previous git hunk" }
					)
				end,
			})
		end,
		keys = {
			{
				"<leader>Gk",
				function()
					require("gitsigns").prev_hunk({ navigation_message = false })
				end,
				desc = "Git Prev Hunk",
			},
			{
				"<leader>Gl",
				function()
					require("gitsigns").blame_line()
				end,
				desc = "Git Blame",
			},
			{
				"<leader>Gp",
				function()
					require("gitsigns").preview_hunk()
				end,
				desc = "Git Preview Hunk",
			},
			{
				"<leader>Gr",
				function()
					require("gitsigns").reset_hunk()
				end,
				desc = "Git Reset Hunk",
			},
			{
				"<leader>GR",
				function()
					require("gitsigns").reset_buffer()
				end,
				desc = "Git Reset Buffer",
			},
			{
				"<leader>Gj",
				function()
					require("gitsigns").next_hunk({ navigation_message = false })
				end,
				desc = "Git Next Hunk",
			},
			{
				"<leader>Gs",
				function()
					require("gitsigns").stage_hunk()
				end,
				desc = "Git Stage Hunk",
			},
			{
				"<leader>Gu",
				function()
					require("gitsigns").undo_stage_hunk()
				end,
				desc = "Git Undo Stage Hunk",
			},
			{
				"<leader>Gd",
				function()
					vim.cmd("Gitsigns diffthis HEAD")
				end,
				desc = "Git Diff HEAD",
			},
		},
	},
	{
		"sindrets/diffview.nvim",
		event = "VeryLazy",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
	},
	-- Git related plugins
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
}
