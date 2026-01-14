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
opt.cursorline = true -- Highlight current line
opt.splitright = true -- Vertical splits open to the right
opt.splitbelow = true -- Horizontal splits open below
opt.tabstop = 2 -- 2 spaces for tabs
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

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
keymap.set("n", "x", '"_x') -- Delete without copying

-- Window Splitting
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split Vertical" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split Horizontal" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Equal Splits" })
keymap.set("n", "<leader>sc", "<cmd>close<CR>", { desc = "Close Split" })

-- Window Navigation (Ctrl + h/j/k/l)
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
-- PLUGINS (LAZY.NVIM)
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
	-- 2. Syntax Highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local status, configs = pcall(require, "nvim-treesitter.configs")
			if not status then
				return
			end
			configs.setup({
				ensure_installed = { "bash", "c", "html", "lua", "markdown", "vim", "yaml", "python", "go" },
				highlight = { enable = true },
			})
		end,
	},
	-- 3. FZF-Lua (Replaces Telescope)
	{
		"ibhagwan/fzf-lua",
		dependencies = { "echasnovski/mini.icons" },
		cmd = "FzfLua",
		opts = {
			winopts = {
				height = 0.85,
				width = 0.80,
				preview = { default = "bat" }, -- Uses 'bat' which you installed
			},
		},
		keys = {
			{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
			{ "<leader>fa", "<cmd>FzfLua files<cr>", desc = "Find All" },
			{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep Project" },
			{ "<leader>fw", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Workspace Diagnostics" },
			{ "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Buffer Diagnostics" },
			{ "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
			{ "<leader>fo", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
			{ "<leader><leader>", "<cmd>FzfLua buffers<cr>", desc = "Find Buffers" },
		},
	},
	-- 4. Key Helper (Essential)
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {},
	},
	-- 5. Utilities
	{ "stevearc/oil.nvim", opts = {} },
	{ "lewis6991/gitsigns.nvim", opts = {} },
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
	{ "numToStr/Comment.nvim", opts = {} },
	{ "echasnovski/mini.icons", opts = {} },
})
