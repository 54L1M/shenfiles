local keymap = vim.keymap
-----------------------------
-- KEYMAPS
-----------------------------

-- set leader key to space
vim.g.mapleader = " "

-- insert mode keymaps
keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "" }) -- use jk to exit insert mode
keymap.set("i", "kj", "<ESC>", { noremap = true, silent = true, desc = "" }) -- use kj to exit insert mode

-- normal mode keymaps
keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover" })
keymap.set("n", "<leader>ww", "<cmd>w!<CR>", { noremap = true, silent = true, desc = "Save Current File" }) -- save current file
keymap.set("n", "<leader>wa", "<cmd>wa<CR>", { noremap = true, silent = true, desc = "Save All Files" }) -- save all files
keymap.set("n", "<leader>qq", "<cmd>q<CR>", { noremap = true, silent = true, desc = "Quit" }) -- quit
keymap.set("n", "x", '"_x') -- delete single character without copying into register
keymap.set("n", "<leader>h", "<cmd>nohl<CR>", { noremap = true, silent = true, desc = "Clear Highlight" }) -- clear highlight

keymap.set("n", "<leader>sv", "<C-w>v", { noremap = true, silent = true, desc = "Split Window Vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { noremap = true, silent = true, desc = "Split Window Horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { noremap = true, silent = true, desc = "Make Splits Equal" }) -- make split windows equal width & height
keymap.set("n", "<leader>sc", "<cmd>close<CR>", { noremap = true, silent = true, desc = "Close Current Split Window" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { noremap = true, silent = true, desc = "Open New Tab" }) -- open new tab
keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", { noremap = true, silent = true, desc = "Close Tab" }) -- close tab
keymap.set("n", "<leader>tn", "<cmd>tabnext<CR>", { noremap = true, silent = true, desc = "Next Tab" }) -- go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabprevious<CR>", { noremap = true, silent = true, desc = "Previous Tab" }) -- go to previous tab

-- Navigate vim panes better
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")
