return {
	"ibhagwan/fzf-lua",
	-- optional for icon support
	-- dependencies = { "nvim-tree/nvim-web-devicons" },
	-- or if using mini.icons/mini.nvim
	dependencies = { "echasnovski/mini.icons" },
	opts = {},
	config = function()
		local fzf = require("fzf-lua")
		local actions = require("fzf-lua").actions
		fzf.setup({
			files = {
				git_icons = true,
			},
			keymap = {
				-- Keymaps for the fzf buffer
				fzf = {
					["ctrl-u"] = "half-page-up",
					["ctrl-d"] = "half-page-down",
					["ctrl-f"] = "preview-page-down",
					["ctrl-b"] = "preview-page-up",
				},
				-- Keymaps for the normal mode buffer
				builtin = {
					["<F1>"] = "toggle-help",
					["<C-f>"] = "preview-page-down",
					["<C-b>"] = "preview-page-up",
				},
			},
			winopts = {
				height = 0.85,
				width = 0.80,
			},
			actions = {
				files = {
					["ctrl-q"] = actions.file_sel_to_qf,
					["enter"] = actions.file_edit,
					["ctrl-s"] = actions.file_split,
					["ctrl-v"] = actions.file_vsplit,
					["ctrl-t"] = actions.file_tabedit,
				},
			},
		})
	end,
	keys = {
		{
			"<leader>ff",
			function()
				require("fzf-lua").files({
					fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude .next --exclude dist --exclude build --exclude src --exclude static",
					rg_opts = "--color=never --files --hidden --follow -g '!.git' -g '!node_modules' -g '!.next' -g '!dist' -g '!build' -g '!src' -g '!static'",
				})
			end,
			desc = "[F]ind [F]iles",
		},
		{
			"<leader>fa",
			function()
				require("fzf-lua").files()
			end,
			desc = "[F]ind [A]ll Files",
		},
		{
			"<leader>fg",
			function()
				require("fzf-lua").grep_project()
			end,
			desc = "[F]ind by [G]repping in project directory",
		},
		{
			"<leader>fc",
			function()
				require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "[F]ind in neovim [C]onfiguration",
		},
		{
			"<leader>fs",
			function()
				require("fzf-lua").files({ cwd = vim.fn.expand("$HOME/shenfiles/scripts/") })
			end,
			desc = "[F]ind [S]cripts",
		},
		{
			"<leader>fh",
			function()
				require("fzf-lua").helptags()
			end,
			desc = "[F]ind [H]elp",
		},
		{
			"<leader>fk",
			function()
				require("fzf-lua").keymaps()
			end,
			desc = "[F]ind [K]eymaps",
		},
		{
			"<leader>fb",
			function()
				require("fzf-lua").builtin()
			end,
			desc = "[F]ind [B]uiltin FZF",
		},
		{
			"<leader>fw",
			function()
				require("fzf-lua").diagnostics_workspace()
			end,
			desc = "[F]ind [W]orkspace Diagnostics",
		},
		{
			"<leader>fd",
			function()
				require("fzf-lua").diagnostics_document()
			end,
			desc = "[F]ind Buffer [D]iagnostics",
		},
		{
			"<leader>fr",
			function()
				require("fzf-lua").resume()
			end,
			desc = "[F]ind [R]esume",
		},
		{
			"<leader>fo",
			function()
				require("fzf-lua").oldfiles()
			end,
			desc = "[F]ind [O]ld Files",
		},
		{
			"<leader><leader>",
			function()
				require("fzf-lua").buffers()
			end,
			desc = "[F]ind [B]uffers",
		},
		{
			"<leader>/",
			function()
				require("fzf-lua").lgrep_curbuf()
			end,
			desc = "Live grep the current buffer",
		},
		-- LSP keymaps using fzf-lua
		{
			"<leader>ld",
			function()
				require("fzf-lua").lsp_definitions()
			end,
			desc = "LSP Definitions",
		},
		{
			"<leader>lr",
			function()
				require("fzf-lua").lsp_references()
			end,
			desc = "LSP References",
		},
		{
			"<leader>lf",
			function()
				require("fzf-lua").lsp_finder()
			end,
			desc = "LSP Finder",
		},
		{
			"<leader>li",
			function()
				require("fzf-lua").lsp_incoming_calls()
			end,
			desc = "LSP Incoming Calls",
		},
		{
			"<leader>lo",
			function()
				require("fzf-lua").lsp_outgoing_calls()
			end,
			desc = "LSP Outgoing Calls",
		},
		-- Git keymaps using fzf-lua
		{
			"<leader>gc",
			function()
				require("fzf-lua").git_commits()
			end,
			desc = "Git Commits",
		},
		{
			"<leader>gs",
			function()
				require("fzf-lua").git_status()
			end,
			desc = "Git Status",
		},
		{
			"<leader>gB",
			function()
				require("fzf-lua").git_branches()
			end,
			desc = "Git Branches",
		},
		{
			"<leader>gbb",
			function()
				require("fzf-lua").git_blame()
			end,
			desc = "Git Blame Buffer",
		},
		{
			"<leader>gt",
			function()
				require("fzf-lua").git_tags()
			end,
			desc = "Git Tags",
		},
	},
}
