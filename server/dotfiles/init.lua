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
	-- 1. Colorscheme (Transparent)
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

	-- 2. Snacks.nvim (Full Keymaps + Navigation Fix)
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			dashboard = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			input = { enabled = true },
			picker = {
				enabled = true,
				sources = {
					files = { hidden = true },
				},
				-- FIX: Ctrl+j/k navigation in pickers
				win = {
					input = {
						keys = {
							["<C-j>"] = { "list_down", mode = { "i", "n" } },
							["<C-k>"] = { "list_up", mode = { "i", "n" } },
						},
					},
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

	-- 3. Blink.cmp (Your Settings + Tab Fix)
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

	-- 4. LSP & Mason (Implemented exactly as requested)
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

	-- 5. Lua Development
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
		},
	},

	-- 6. Formatting
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true })
				end,
				mode = { "n", "v" },
				desc = "Format",
			},
		},
		opts = {
			formatters_by_ft = {
				go = { "goimports", "gofmt" },
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				bash = { "shfmt" },
			},
		},
	},

	-- 7. Utilities
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "bash", "c", "html", "lua", "markdown", "vim", "yaml", "python", "go" },
				highlight = { enable = true },
			})
		end,
	},
	{ "folke/which-key.nvim", opts = { preset = "helix" } },
	{ "stevearc/oil.nvim", opts = {} },
	{ "lewis6991/gitsigns.nvim", opts = {} },
	{ "echasnovski/mini.icons", opts = {} },
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
	{ "numToStr/Comment.nvim", opts = {} },
})
