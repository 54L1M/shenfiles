return {
	"ibhagwan/fzf-lua",
	-- optional for icon support
	-- dependencies = { "nvim-tree/nvim-web-devicons" },
	-- or if using mini.icons/mini.nvim
	dependencies = { "echasnovski/mini.icons" },
	opts = {},
	config = function()
		local fzf = require("fzf-lua")
		local config = fzf.config
		config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
		config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
		config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
		config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
		config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
		config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"
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
				require("fzf-lua").live_grep()
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
				require("fzf-lua").grep_cword()
			end,
			desc = "[F]ind current [W]ord",
		},
		{
			"<leader>fW",
			function()
				require("fzf-lua").grep_cWORD()
			end,
			desc = "[F]ind current [W]ORD",
		},
		{
			"<leader>fd",
			function()
				require("fzf-lua").diagnostics_document()
			end,
			desc = "[F]ind [D]iagnostics",
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
	},
}
