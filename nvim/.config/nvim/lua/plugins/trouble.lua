return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below

		vim.keymap.set("n", "<leader>xw", function()
			require("trouble").toggle("workspace_diagnostics")
		end),
		vim.keymap.set("n", "<leader>gr", function()
			require("trouble").toggle("lsp_references")
		end),
		vim.keymap.set("n", "<leader>gd", function()
			require("trouble").toggle("lsp_definitions")
		end),
	},
}
