local opts = { noremap = true, silent = true }
local keymap = vim.keymap -- for conciseness

-- set leader key to space
vim.g.mapleader = " "

-----------------------
-- insert mode keymaps
-----------------------

keymap.set("i", "jk", "<ESC>", opts) -- use jk to exit insert mode
keymap.set("i", "kj", "<ESC>", opts) -- use kj to exit insert mode

-----------------------
-- normal mode keymaps
-----------------------
keymap.set("n", "<leader>w", "<cmd>w!<CR>", opts) -- save current file
keymap.set("n", "<leader>q", "<cmd>q<CR>", opts) -- quit
keymap.set("n", "x", '"_x') -- delete single character without copying into register
keymap.set("n", "<leader>h", "<cmd>nohl<CR>", opts) -- clear highlight
keymap.set("n", "<leader>l", "<cmd>Mason<CR>", opts) -- toggle Mason
-- window management
keymap.set("n", "<leader>sv", "<C-w>v", opts) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", opts) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", opts) -- make split windows equal width & height
keymap.set("n", "<leader>sc", "<cmd>close<CR>", opts) -- close current split window

-- tab management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", opts) -- open new tab
keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", opts) -- close tab
keymap.set("n", "<leader>tn", "<cmd>tabnext<CR>", opts) -- go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabprevious<CR>", opts) -- go to previous tab

-----------------------
-- plugins keymaps
-----------------------

-- bufdel
keymap.set("n", "<leader>k", "<cmd>BufDel<CR>", opts)
-- bufferline
keymap.set("n", "<s-h>", "<cmd>BufferLineCyclePrev<CR>", opts)
keymap.set("n", "<s-l>", "<cmd>BufferLineCycleNext<CR>", opts)
-- vim maximizer
keymap.set("n", "<leader>sm", "<cmd>MaximizerToggle<CR>", opts) -- maximize current split window
-- telescope
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>") -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>") -- find string in current working directory as you type
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>") -- find string under cursor in current working directory
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>") -- list open buffers in current neovim instance
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>") -- list available help tags
-- telescope file browser
keymap.set("n", "<leader>fe", "<cmd>Telescope file_browser<cr>")
-- neogit
keymap.set("n", "<leader>ng", "<cmd>Neogit<cr>") -- toggle neogit
-- glow, md preview
keymap.set("n", "<leader>m", "<cmd>Glow<cr>") -- toggle neogit
