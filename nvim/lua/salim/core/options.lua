local opt = vim.opt
----------------------------
-- OPTIONS
-----------------------------
-- line number
opt.number = true
opt.relativenumber = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
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
opt.colorcolumn = "88"

-- conceallevel
opt.conceallevel = 1

-- Give more space for displaying messages.
vim.opt.cmdheight = 1

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 50
-- colors
vim.o.termguicolors = true
