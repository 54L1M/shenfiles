return {
	{ "L3MON4D3/LuaSnip", keys = {} },
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"saghen/blink.cmp",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		version = "*",
		config = function()
			require("blink.cmp").setup({
				snippets = { preset = "luasnip" },
				signature = { enabled = true },
				appearance = {
					use_nvim_cmp_as_default = false,
					nerd_font_variant = "normal",
				},
				sources = {
					default = { "lsp", "path", "snippets", "lazydev", "buffer" },
					providers = {
						lazydev = {
							name = "LazyDev",
							module = "lazydev.integrations.blink",
							score_offset = 100,
						},
						cmdline = {
							min_keyword_length = 2,
						},
					},
				},

				-- KEYMAP CONFIGURATION
				keymap = {
					preset = "none",

					-- Navigation
					["<C-k>"] = { "select_prev", "fallback" },
					["<C-j>"] = { "select_next", "fallback" },

					-- Scrolling Docs
					["<C-b>"] = { "scroll_documentation_up", "fallback" },
					["<C-f>"] = { "scroll_documentation_down", "fallback" },

					-- Control
					["<C-e>"] = { "hide", "fallback" },
					["<CR>"] = { "accept", "fallback" }, -- Enter also accepts. Change to "fallback" if you want Enter to be just Newline.

					-- Manual Trigger (Replaces C-Space due to tmux conflict)
					["<C-n>"] = { "show", "fallback" },

					-- TAB STRATEGY: Accept -> Snippet -> Indent
					["<Tab>"] = {
						"accept",
						"snippet_forward",
						"fallback",
					},
					["<S-Tab>"] = {
						"snippet_backward",
						"fallback",
					},
				},

				cmdline = {
					enabled = false,
					completion = { menu = { auto_show = true } },
					keymap = {
						["<CR>"] = { "accept_and_enter", "fallback" },
					},
				},

				completion = {
					-- 'ghost_text' is highly recommended when using Tab to accept
					ghost_text = { enabled = true },

					menu = {
						border = "single",
						scrolloff = 1,
						scrollbar = false,
						draw = {
							columns = {
								{ "kind_icon" },
								{ "label", "label_description", gap = 1 },
								{ "kind" },
								{ "source_name" },
							},
						},
					},
					documentation = {
						window = {
							border = "single",
							scrollbar = false,
							winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
						},
						auto_show = true,
						auto_show_delay_ms = 500,
					},
				},
			})

			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
}
