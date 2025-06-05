return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"williamboman/mason-lspconfig.nvim",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- Default capabilities for all servers
		local default_capabilities = cmp_nvim_lsp.default_capabilities()

		-- vim.diagnostic.config({
		-- 	signs = {
		-- 		text = {
		-- 			[vim.diagnostic.severity.ERROR] = " ",
		-- 			[vim.diagnostic.severity.WARN] = " ",
		-- 			[vim.diagnostic.severity.HINT] = "󰠠 ",
		-- 			[vim.diagnostic.severity.INFO] = " ",
		-- 		},
		-- 	},
		-- 	virtual_text = true, -- Specify Enable virtual text for diagnostics
		-- 	underline = true, -- Specify Underline diagnostics
		-- 	update_in_insert = false, -- Keep diagnostics active in insert mode
		-- })

		vim.diagnostic.config({
			virtual_text = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
			float = {
				border = "rounded",
				source = true,
			},
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.INFO] = "󰋽 ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
				},
				numhl = {
					[vim.diagnostic.severity.ERROR] = "ErrorMsg",
					[vim.diagnostic.severity.WARN] = "WarningMsg",
				},
			},
		})

		-- Lua LSP setup with "vim" recognized as a global
		lspconfig.lua_ls.setup({
			capabilities = default_capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					completion = {
						callSnippet = "Replace",
					},
					workspace = {
						library = {
							vim.api.nvim_get_runtime_file("", true),
							-- checkThirdParty = false,
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
				},
			},
		})

		lspconfig.docker_compose_language_service.setup({
			capabilities = default_capabilities,
		})
		lspconfig.dockerls.setup({
			capabilities = default_capabilities,
		})
		lspconfig.bashls.setup({
			capabilities = default_capabilities,
		})
		-- Enhanced Python/Django configuration
		lspconfig.pyright.setup({
			capabilities = default_capabilities,
			settings = {
				python = {
					analysis = {
						ignore = { "*" },
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						diagnosticMode = "workspace",
						typeCheckingMode = "off", -- Not too strict for Django
						extraPaths = {}, -- Will be populated dynamically
					},
				},
			},
		})
		-- Ruff LSP setup
		lspconfig.ruff.setup({
			capabilities = default_capabilities,
			init_options = {
				settings = {
					lint = {
						-- Ignore common Django patterns
						ignore = { "F403", "F405", "E501" },
					},
				},
			},
		})
		-- Enhanced Go configuration for side projects
		lspconfig.gopls.setup({
			capabilities = default_capabilities,
			settings = {
				gopls = {
					analyses = {
						unusedparams = true,
						shadow = true,
						nilness = true,
						unusedwrite = true,
						useany = true,
					},
					staticcheck = true,
					gofumpt = true,
					usePlaceholders = true,
					completeUnimported = true,
					experimentalPostfixCompletions = true,
				},
			},
		})

		-- Clangd setup with utf-16 encoding
		lspconfig.clangd.setup({
			capabilities = vim.tbl_deep_extend("force", default_capabilities, {
				offsetEncoding = { "utf-16" },
			}),
		})
	end,
}
