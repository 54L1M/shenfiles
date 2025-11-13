return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lsp",
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			build = "make install_jsregexp",
			dependencies = { "rafamadriz/friendly-snippets" },
		},
		"saadparwaiz1/cmp_luasnip",
		"onsails/lspkind.nvim",
		-- Sources used but not listed as dependencies
		"roobert/tailwindcss-colorizer-cmp.nvim",
		"folke/lazydev.nvim",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		local lspkind = require("lspkind")

		-- Load vscode style snippets
		require("luasnip.loaders.from_vscode").lazy_load()

		local has_words_before = function()
			local line, col = unpack(vim.api.nvim_win_get_cursor(0))
			return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
		end

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			-- A more standard mapping
			mapping = cmp.mapping.preset.insert({
				["<C-k>"] = cmp.mapping.select_prev_item(),
				["<C-j>"] = cmp.mapping.select_next_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = true }), -- Confirm with Enter

				-- Tab completion
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					elseif luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					elseif has_words_before() then
						cmp.complete()
					else
						fallback() -- Fallback to inserting a tab
					end
				end, { "i", "s" }),

				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif luasnip.jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
			}),
			-- Sources for completion
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "lazydev" },
				{ name = "buffer" },
				{ name = "path" },
				{ name = "tailwindcss-colorizer-cmp" },
			}),
			-- Formatting with lspkind
			formatting = {
				format = lspkind.cmp_format({
					mode = "symbol_text", -- show only symbol and text
					maxwidth = 50,
					ellipsis_char = "...",
					before = function(entry, vim_item)
						-- Add menu tags
						vim_item.menu = ({
							buffer = "[Buffer]",
							nvim_lsp = "[LSP]",
							luasnip = "[LuaSnip]",
							path = "[Path]",
							lazydev = "[LazyDev]",
							["tailwindcss-colorizer-cmp"] = "[Tailwind]",
						})[entry.source.name]
						return vim_item
					end,
				}),
			},
			experimental = {
				ghost_text = true,
			},
		})
		-- Add dadbod completion for sql files
		cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
			sources = cmp.config.sources({
				{ name = "vim-dadbod-completion" },
				{ name = "buffer" },
			}),
		})
	end,
}