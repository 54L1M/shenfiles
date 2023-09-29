local opt = vim.opt
-- LVIM --
-- transparency
lvim.transparent_window = true
-- format on save
lvim.format_on_save = true

-- keymaps
-- insert mode
lvim.keys.insert_mode["jk"] = "<ESC>"
lvim.keys.insert_mode["kj"] = "<ESC>"
-- normal mode
lvim.keys.normal_mode["<leader>t"] = "<cmd>ToggleTerm<CR>"
lvim.keys.normal_mode["<s-h>"] = "<cmd>BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<s-l>"] = "<cmd>BufferLineCycleNext<CR>"
-- OPTIONS--
-- line numbers
opt.number = true
opt.relativenumber = true
-- tabs & indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
-- line wrapping
opt.wrap = false
-- search settings
opt.ignorecase = true
opt.smartcase = true
-- cursor line
opt.cursorline = true
-- clipboard
opt.clipboard:append("unnamedplus")
--split windows
opt.splitright = true
opt.splitbelow = true
-- keyword
opt.iskeyword:append("_")
opt.iskeyword:append("-")
--background & colorscheme
opt.termguicolors = true
opt.background = "dark"
-- set column at charachter 80
opt.colorcolumn = "80"
-- Give more space for displaying messages.
opt.cmdheight = 1
-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
opt.updatetime = 50


-- PLUGINS --

lvim.builtin.telescope.defaults.initial_mode = "normal"
