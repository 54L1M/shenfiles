return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	branch = "main",
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		-- Install your required language parsers
		local parsers = {
			"json",
			"javascript",
			"typescript",
			"yaml",
			"html",
			"css",
			"markdown",
			"markdown_inline",
			"bash",
			"lua",
			"vim",
			"dockerfile",
			"gitignore",
			"query",
			"python",
			"go",
		}
		require("nvim-treesitter").install(parsers)

		-- Enable syntax highlighting via Neovim's built-in API
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})

		-- Set up nvim-ts-autotag independently (it no longer hooks into treesitter.configs)
		require("nvim-ts-autotag").setup({
			enable = true,
		})
	end,
}
