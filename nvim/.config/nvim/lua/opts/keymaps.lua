local opts = { noremap = true, silent = true }
local keymap = vim.keymap
-----------------------------
-- KEYMAPS
-----------------------------

-- set leader key to space
vim.g.mapleader = " "


-- insert mode keymaps
keymap.set("i", "jk", "<ESC>", opts) -- use jk to exit insert mode
keymap.set("i", "kj", "<ESC>", opts) -- use kj to exit insert mode

-- normal mode keymaps
keymap.set("n", "<leader>w", "<cmd>w!<CR>", opts) -- save current file
keymap.set("n", "<leader>qq", "<cmd>q<CR>", opts) -- quit
keymap.set("n", "<leader>qb", "<cmd>bdelete<CR>", opts) -- delete buffer
keymap.set("n", "<leader>cw", "<cmd>cd%:p:h<CR>", opts) -- change working directory
keymap.set("n", "x", '"_x') -- delete single character without copying into register
keymap.set("n", "<leader>h", "<cmd>nohl<CR>", opts) -- clear highlight

keymap.set("n", "<leader>sv", "<C-w>v", opts) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", opts) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", opts) -- make split windows equal width & height
keymap.set("n", "<leader>sc", "<cmd>close<CR>", opts) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", opts) -- open new tab
keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", opts) -- close tab
keymap.set("n", "<leader>tn", "<cmd>tabnext<CR>", opts) -- go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabprevious<CR>", opts) -- go to previous tab

-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>')
