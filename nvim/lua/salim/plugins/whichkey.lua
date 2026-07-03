return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 500
	end,
	opts = {
		preset = "helix",
		spec = {
			{ "<leader>b", group = "buffer" },
			{ "<leader>c", group = "code" },
			{ "<leader>D", group = "debug" },
			{ "<leader>Ds", group = "step" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>gh", group = "hunks" },
			{ "<leader>l", group = "lsp" },
			{ "<leader>m", group = "harpoon" },
			{ "<leader>p", group = "python" },
			{ "<leader>q", group = "quit" },
			{ "<leader>s", group = "split" },
			{ "<leader>t", group = "tab" },
			{ "<leader>u", group = "ui/toggle" },
			{ "<leader>w", group = "write" },
		},
	},
}
