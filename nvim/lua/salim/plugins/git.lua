return {
	{
		"lewis6991/gitsigns.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		-- All git keybinds live under <leader>g:
		--   <leader>g   → pickers & actions (Snacks / lazygit / browse / diffview)
		--   <leader>gh  → hunk actions (gitsigns, buffer-local via on_attach)
		--   ]h / [h     → next / prev hunk
		keys = {
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Status",
			},
			{
				"<leader>gl",
				function()
					Snacks.picker.git_log()
				end,
				desc = "Log",
			},
			{
				"<leader>gL",
				function()
					Snacks.picker.git_log_line()
				end,
				desc = "Log (Line)",
			},
			{
				"<leader>gf",
				function()
					Snacks.picker.git_log_file()
				end,
				desc = "Log (File)",
			},
			{
				"<leader>gb",
				function()
					Snacks.picker.git_branches()
				end,
				desc = "Branches",
			},
			{
				"<leader>gS",
				function()
					Snacks.picker.git_stash()
				end,
				desc = "Stash",
			},
			{
				"<leader>gd",
				function()
					Snacks.picker.git_diff()
				end,
				desc = "Diff (Hunks)",
			},
			{
				"<leader>gB",
				function()
					Snacks.gitbrowse()
				end,
				desc = "Browse",
				mode = { "n", "v" },
			},
		},
		config = function()
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
				current_line_blame = false, -- Toggle with <leader>ght
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

				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, desc)
						vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
					end

					-- Navigation (also handles diff mode with ]c / [c)
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

					-- Hunk actions (<leader>gh)
					map("n", "<leader>ghn", function()
						gs.nav_hunk("next")
					end, "Next Hunk")
					map("n", "<leader>ghN", function()
						gs.nav_hunk("prev")
					end, "Prev Hunk")

					map("n", "<leader>ghs", gs.stage_hunk, "Stage Hunk")
					map("n", "<leader>ghr", gs.reset_hunk, "Reset Hunk")
					map("v", "<leader>ghs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, "Stage Hunk")
					map("v", "<leader>ghr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, "Reset Hunk")

					map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
					map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")

					map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
					map("n", "<leader>ghb", function()
						gs.blame_line({ full = true })
					end, "Blame Line (Full)")
					map("n", "<leader>ght", gs.toggle_current_line_blame, "Toggle Line Blame")

					map("n", "<leader>ghd", gs.diffthis, "Diff This")
					map("n", "<leader>ghD", function()
						gs.diffthis("~")
					end, "Diff This ~")

					-- Text object (e.g. 'dih' = delete inner hunk)
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
				end,
			})
		end,
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gv", "<cmd>DiffviewOpen<CR>", desc = "Diffview Open" },
			{ "<leader>gV", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview File History" },
		},
	},
}
