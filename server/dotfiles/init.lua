-- Minimal Server Config
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-----------------------------
-- OPTIONS
-----------------------------
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.termguicolors = true
opt.cursorline = true
opt.splitright = true
opt.splitbelow = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.signcolumn = "yes"

-----------------------------
-- KEYMAPS
-----------------------------
local keymap = vim.keymap

-- Insert Mode: Fast exit
keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "Exit insert mode" })
keymap.set("i", "kj", "<ESC>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- Normal Mode: General
keymap.set("n", "<leader>ww", "<cmd>w!<CR>", { desc = "Save Current File" })
keymap.set("n", "<leader>wa", "<cmd>wa<CR>", { desc = "Save All Files" })
keymap.set("n", "<leader>qq", "<cmd>q<CR>", { desc = "Quit" })
keymap.set("n", "<leader>h", "<cmd>nohl<CR>", { desc = "Clear Highlight" })
keymap.set("n", "x", '"_x')

-- Window Splitting
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split Vertical" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split Horizontal" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Equal Splits" })
keymap.set("n", "<leader>sc", "<cmd>close<CR>", { desc = "Close Split" })

-- Window Navigation
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move Left" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move Down" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move Up" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move Right" })

-- Tab Management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "New Tab" })
keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close Tab" })
keymap.set("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "Next Tab" })
keymap.set("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "Prev Tab" })

-- File Navigation
keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open Parent Directory" })

-----------------------------
-- LAZY.NVIM BOOTSTRAP
-----------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-----------------------------
-- PLUGINS
-----------------------------
require("lazy").setup({
	--  Colorscheme (Transparent)
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				transparent_background = true, -- ENABLED
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},
	--  Tmux Navigator (CRITICAL FIX for C-j/C-k)
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},
	--  Snacks.nvim (Full Keymaps + Navigation Fix)
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			dashboard = { enabled = true },
			notifier = { enabled = false },
			quickfile = { enabled = true },
			input = { enabled = true },
			picker = {
				enabled = true,
				sources = {
					files = { hidden = true },
				},
			},
		},
		keys = {
			-- Top Pickers
			{
				"<leader><space>",
				function()
					Snacks.picker.smart()
				end,
				desc = "Smart Find Files",
			},
			{
				"<leader>,",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>/",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>:",
				function()
					Snacks.picker.command_history()
				end,
				desc = "Command History",
			},

			-- Find
			{
				"<leader>fb",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>fc",
				function()
					Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find Config File",
			},
			{
				"<leader>fi",
				function()
					Snacks.picker.icons()
				end,
				desc = "Find Icons",
			},
			{
				"<leader>ff",
				function()
					Snacks.picker.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					Snacks.picker.git_files()
				end,
				desc = "Find Git Files",
			},
			{
				"<leader>fp",
				function()
					Snacks.picker.projects()
				end,
				desc = "Projects",
			},
			{
				"<leader>fr",
				function()
					Snacks.picker.recent()
				end,
				desc = "Recent",
			},

			-- Grep
			{
				"<leader>fB",
				function()
					Snacks.picker.grep_buffers()
				end,
				desc = "Grep Open Buffers",
			},
			{
				"<leader>fw",
				function()
					Snacks.picker.grep_word({ buffers = true, title = "Grep Word Open Buffers" })
				end,
				desc = "Grep Word Open Buffers",
			},
			{
				"<leader>fW",
				function()
					Snacks.picker.grep_word()
				end,
				desc = "Grep Word",
			},

			-- Diagnostics & Help
			{
				"<leader>fd",
				function()
					Snacks.picker.diagnostics_buffer()
				end,
				desc = "Buffer Diagnostics",
			},
			{
				"<leader>fD",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				"<leader>fm",
				function()
					Snacks.picker.man()
				end,
				desc = "Man",
			},
			{
				"<leader>fP",
				function()
					Snacks.picker.pickers()
				end,
				desc = "Available Pickers",
			},

			-- Git
			{
				"<leader>gb",
				function()
					Snacks.picker.git_branches()
				end,
				desc = "Git Branches",
			},
			{
				"<leader>gl",
				function()
					Snacks.picker.git_log()
				end,
				desc = "Git Log",
			},
			{
				"<leader>gL",
				function()
					Snacks.picker.git_log_line()
				end,
				desc = "Git Log Line",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Git Status",
			},
			{
				"<leader>gS",
				function()
					Snacks.picker.git_stash()
				end,
				desc = "Git Stash",
			},
			{
				"<leader>gd",
				function()
					Snacks.picker.git_diff()
				end,
				desc = "Git Diff (Hunks)",
			},
			{
				"<leader>gf",
				function()
					Snacks.picker.git_log_file()
				end,
				desc = "Git Log File",
			},
			{
				"<leader>gB",
				function()
					Snacks.gitbrowse()
				end,
				desc = "Git Browse",
				mode = { "n", "v" },
			},
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},

			-- LSP
			{
				"<leader>lc",
				function()
					Snacks.picker.lsp_config()
				end,
				desc = "LSP Config",
			},
			{
				"<leader>ld",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "LSP Definitions",
			},
			{
				"<leader>li",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "LSP Implementations",
			},
			{
				"<leader>ls",
				function()
					Snacks.picker.lsp_symbols()
				end,
				desc = "LSP Symbols",
			},
			{
				"<leader>lS",
				function()
					Snacks.picker.lsp_workspace_symbols()
				end,
				desc = "LSP Workspace Symbols",
			},
			{
				"gd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "Goto Definition",
			},
			{
				"gD",
				function()
					Snacks.picker.lsp_declarations()
				end,
				desc = "Goto Declaration",
			},
			{
				"gr",
				function()
					Snacks.picker.lsp_references()
				end,
				nowait = true,
				desc = "References",
			},
			{
				"gI",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "Goto Implementation",
			},
			{
				"gy",
				function()
					Snacks.picker.lsp_type_definitions()
				end,
				desc = "Goto T[y]pe Definition",
			},
			{
				"gai",
				function()
					Snacks.picker.lsp_incoming_calls()
				end,
				desc = "C[a]lls Incoming",
			},
			{
				"gao",
				function()
					Snacks.picker.lsp_outgoing_calls()
				end,
				desc = "C[a]lls Outgoing",
			},

			-- Utils
			{
				"<leader>bd",
				function()
					Snacks.bufdelete()
				end,
				desc = "Delete Buffer",
			},
			{
				"<leader>cR",
				function()
					Snacks.rename.rename_file()
				end,
				desc = "Rename File",
			},
			{
				"<leader>uC",
				function()
					Snacks.picker.colorschemes()
				end,
				desc = "Colorschemes",
			},
		},
	},

	-- Blink.cmp (Your Settings + Tab Fix)
	{
		"saghen/blink.cmp",
		dependencies = { "rafamadriz/friendly-snippets", "L3MON4D3/LuaSnip" },
		version = "*",
		opts = {
			snippets = { preset = "luasnip" },
			signature = { enabled = true },
			appearance = {
				use_nvim_cmp_as_default = false,
				nerd_font_variant = "normal",
			},
			sources = {
				default = { "lsp", "path", "snippets", "lazydev", "buffer" },
				providers = {
					lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
				},
			},
			keymap = {
				preset = "none",
				["<C-k>"] = { "select_prev", "fallback" },
				["<C-j>"] = { "select_next", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<C-n>"] = { "show", "fallback" },
				["<Tab>"] = { "accept", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "fallback" },
			},
		},
	},

	-- LSP & Mason (Implemented exactly as requested)
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			-- 1. Setup Mason (Installs binaries)
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "pyright", "ruff", "gopls", "bashls", "clangd", "dockerls" },
				automatic_installation = true,
			})

			-- 2. Diagnostic Config
			vim.diagnostic.config({
				virtual_text = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = { border = "rounded", source = true },
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.INFO] = " ",
						[vim.diagnostic.severity.HINT] = " ",
					},
				},
			})

			-- 3. Autocmds (Keymaps)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(ev)
					local opts = { buffer = ev.buf, silent = true }
					opts.desc = "Code Action"
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
					opts.desc = "Rename Symbol"
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					opts.desc = "LSP Hover"
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				end,
			})

			-- 4. Enable Servers (using vim.lsp.enable as requested)
			local servers = {
				"lua_ls",
				"pyright",
				"ruff",
				"gopls",
				"dockerls",
				"bashls",
				"clangd",
			}

			local capabilities = require("blink.cmp").get_lsp_capabilities()

			for _, server in ipairs(servers) do
				vim.lsp.enable(server)
			end
		end,
	},

	-- Lua Development
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
		},
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true }, function(err, did_edit)
						if not err and did_edit then
							vim.notify("Code formatted", vim.log.levels.INFO, { title = "Conform" })
						end
					end)
				end,
				mode = { "n", "v" },
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				-- Go
				go = { "goimports", "gofmt" },

				-- Lua
				lua = { "stylua" },

				-- Web technologies
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },

				-- Python
				python = { "isort", "black" },

				-- Shell
				sh = { "shfmt" },
				bash = { "shfmt" },
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = {
				-- timeout_ms = 3000,
				-- lsp_format = "fallback",
			},
		},
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},

	-- Lua Line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local lualine = require("lualine")

			-- mocha
			local colors = {
				flamingo = "#ea6962",
				red = "#ea6962",
				maroon = "#ea6962",
				mauve = "#d3869b",
				peach = "#e78a4e",
				yellow = "#d8a657",
				green = "#a9b665",
				sky = "#89b482",
				blue = "#7daea3",
				text = "#ebdbb2",
				subtext1 = "#d5c4a1",
				subtext0 = "#bdae93",
				overlay2 = "#a89984",
				overlay1 = "#928374",
				overlay0 = "#595959",
				surface2 = "#4d4d4d",
				surface1 = "#404040",
				surface0 = "#292929",
				base = "#1d2021",
				mantle = "#191b1c",
				crust = "#141617",
			}
			local my_lualine_theme = {
				normal = {
					a = { bg = colors.blue, fg = colors.base, gui = "bold" },
					b = { bg = colors.base, fg = colors.subtext0 },
					c = { bg = colors.base, fg = colors.subtext0 },
				},
				insert = {
					a = { bg = colors.green, fg = colors.base, gui = "bold" },
					b = { bg = colors.base, fg = colors.subtext0 },
					c = { bg = colors.base, fg = colors.subtext0 },
				},

				visual = {
					a = { bg = colors.mauve, fg = colors.base, gui = "bold" },
					b = { bg = colors.base, fg = colors.subtext0 },
					c = { bg = colors.base, fg = colors.subtext0 },
				},
				command = {
					a = { bg = colors.yellow, fg = colors.base, gui = "bold" },
					b = { bg = colors.base, fg = colors.subtext0 },
					c = { bg = colors.base, fg = colors.subtext0 },
				},
				replace = {
					a = { bg = colors.red, fg = colors.base, gui = "bold" },
					b = { bg = colors.base, fg = colors.subtext0 },
					c = { bg = colors.base, fg = colors.subtext0 },
				},
				inactive = {
					a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
					b = { bg = colors.inactive_bg, fg = colors.semilightgray },
					c = { bg = colors.inactive_bg, fg = colors.semilightgray },
				},
			}
			-- configure lualine with modified theme
			lualine.setup({
				extensions = { "oil", "trouble", "mason", "quickfix", "ctrlspace" },
				options = {
					theme = my_lualine_theme,
					section_separators = "",
					component_separators = "",
					globalstatus = false,
				},
				sections = {
					lualine_a = {
						{
							"mode",
							fmt = function(str)
								return str:sub(1, 1)
							end,
						},
					},
					lualine_b = {
						{ "filename", path = 4, shorting_target = 110, symbols = { modified = "●" } },
					},
					lualine_c = { { "diagnostics" } },
					lualine_x = { { "diff" } },
					lualine_y = { { "branch" } },
					lualine_z = {
						{
							"location",
							color = { bg = colors.bg, fg = colors.fg },
						},
					},
				},
				inactive_sections = {
					lualine_a = {
						{
							"mode",
							fmt = function(str)
								return str:sub(1, 1)
							end,
						},
					},
					lualine_b = {
						{ "filename", path = 1, shorting_target = 40, symbols = { modified = "●" } },
					},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = { { "location" } },
				},
			})
		end,
	},
	-- Utilities
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		branch = "master",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "bash", "c", "html", "lua", "markdown", "vim", "yaml", "python", "go" },
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
	{ "folke/which-key.nvim", opts = { preset = "helix" } },
	{
		"stevearc/oil.nvim",
		config = function()
			local oil = require("oil")
			local util = require("oil.util")
			local actions = require("oil.actions")

			oil.setup({
				keymaps = {
					["gd"] = {
						desc = "Toggle file detail view",
						callback = function()
							Detail = not Detail
							if Detail then
								require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
							else
								require("oil").set_columns({ "icon" })
							end
						end,
					},
				},
				float = {
					padding = 2,
					max_width = 120,
					max_height = 30,
					border = "rounded",
					win_options = {
						winblend = 0,
					},
				},
				view_options = {
					show_hidden = true,
				},
			})

			vim.keymap.set("n", "-", function()
				oil.open_float()
				util.run_after_load(0, function()
					oil.open_preview()
				end)
			end, { desc = "Open Oil" })

			vim.api.nvim_create_autocmd("User", {
				group = vim.api.nvim_create_augroup("OilFloatCustom", {}),
				pattern = "OilEnter",
				callback = function()
					if util.is_floating_win() then
						vim.keymap.set("n", "<Esc>", actions.close.callback, {
							buffer = true,
						})
						vim.keymap.set("n", "q", actions.close.callback, {
							buffer = true,
						})
					end
				end,
			})
		end,
	},

	{ "lewis6991/gitsigns.nvim", opts = {} },
	{ "echasnovski/mini.icons", opts = {} },
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
	{ "numToStr/Comment.nvim", opts = {} },
})
