-- Minimal Server Config with Snacks & Blink
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
opt.signcolumn = "yes" -- Keep sign column open for LSP/Git

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
	-- 1. Colorscheme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- 2. Snacks.nvim (Picker + Dashboard + Utils)
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			picker = { enabled = true },
			dashboard = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
		},
		keys = {
			-- Top Pickers & Explorer
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
			{
				"<leader>e",
				function()
					Snacks.explorer()
				end,
				desc = "File Explorer",
			},
			-- Find
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
				"<leader>fr",
				function()
					Snacks.picker.recent()
				end,
				desc = "Recent",
			},
			-- Git
			{
				"<leader>gl",
				function()
					Snacks.picker.git_log()
				end,
				desc = "Git Log",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Git Status",
			},
			-- LSP
			{
				"gd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "Goto Definition",
			},
			{
				"gr",
				function()
					Snacks.picker.lsp_references()
				end,
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
		},
	},

	-- 3. Blink.cmp (Autocompletion)
	{
		"saghen/blink.cmp",
		version = "*", -- Use latest release
		opts = {
			keymap = { preset = "default" }, -- Uses <C-space>, <Enter>, <Tab>
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			signature = { enabled = true }, -- Show function signature while typing
		},
	},

	-- 4. LSP & Mason (Auto-install LSPs)
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"saghen/blink.cmp", -- Dependency to get capabilities
		},
		config = function()
			-- Setup Mason (Package Manager for LSPs)
			require("mason").setup()
			require("mason-lspconfig").setup({
				-- These will be auto-installed on the server!
				ensure_installed = { "lua_ls", "bashls", "gopls", "pyright", "clangd" },
				automatic_installation = true,
			})

			-- Link Blink with LSPConfig
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local lspconfig = require("lspconfig")

			-- Loop through servers and set them up
			local servers = { "lua_ls", "bashls", "gopls", "pyright", "clangd", "ruff" }
			for _, server in ipairs(servers) do
				lspconfig[server].setup({
					capabilities = capabilities,
				})
			end
		end,
	},

	-- 5. Lua Development (Auto-completion for Neovim Lua)
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	-- 6. Syntax Highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")
			configs.setup({
				ensure_installed = { "bash", "c", "html", "lua", "markdown", "vim", "yaml", "python", "go" },
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- 7. Utilities
	{ "folke/which-key.nvim", opts = {} },
	{ "stevearc/oil.nvim", opts = {} },
	{ "lewis6991/gitsigns.nvim", opts = {} },
	{ "echasnovski/mini.icons", opts = {} },
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
	{ "numToStr/Comment.nvim", opts = {} },
})
