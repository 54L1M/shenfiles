return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")
		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- Configure mason-lspconfig
		require("mason-lspconfig").setup({
			-- List of servers for mason to install
			ensure_installed = {
				"html",
				"cssls",
				"lua_ls",
				"pyright",
				"gopls",
			},
			automatic_enable = false,
		})

		-- Set up tool installer
		local mason_tool_installer = require("mason-tool-installer")
		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"isort", -- python formatter
				"black", -- python formatter
				"ruff", -- python linter
				"eslint_d",
				-- Django-specific tools
				"djlint", -- Django template linter and formatter
			},
		})
	end,
}
