return {
	{
		"lewis6991/gitsigns.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- local icons = require('config.icons')
			require("gitsigns").setup({
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signs_staged = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
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
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, desc)
						vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
					end

					-- Navigation (Unified with standard vim-diff keys)
					map("n", "]h", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gs.nav_hunk("next")
						end
					end, "Next Hunk")

					map("n", "[h", function()
						if vim.wo.diff then
							vim.cmd.normal({ "[c", bang = true })
						else
							gs.nav_hunk("prev")
						end
					end, "Prev Hunk")

					-- Hunk Actions (Prefix 'h' for Hunk to avoid conflicts with Snacks 'g' for Global)
					map("n", "<leader>Gs", gs.stage_hunk, "Stage Hunk")
					map("n", "<leader>Gr", gs.reset_hunk, "Reset Hunk")

					-- Visual mode support
					map("v", "<leader>Gs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, "Stage Hunk")
					map("v", "<leader>Gr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, "Reset Hunk")

					-- Buffer Actions
					map("n", "<leader>GS", gs.stage_buffer, "Stage Buffer")
					map("n", "<leader>GR", gs.reset_buffer, "Reset Buffer")

					-- Preview & Blame
					map("n", "<leader>Gp", gs.preview_hunk, "Preview Hunk")
					map("n", "<leader>Gb", function()
						gs.blame_line({ full = true })
					end, "Blame Line (Full)")
					map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle Virtual Blame")

					-- Diff
					map("n", "<leader>Gd", gs.diffthis, "Diff This")
					map("n", "<leader>GD", function()
						gs.diffthis("~")
					end, "Diff This ~")

					-- Text Object (e.g. 'dih' = delete inner hunk)
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
				end,
			})
		end,
	},
	{
		"sindrets/diffview.nvim",
		event = "VeryLazy",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
	},
}
