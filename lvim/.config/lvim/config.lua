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
-- lvim.keys.normal_mode["<leader>f"] = false
lvim.builtin.which_key.mappings["f"] = {
    name = "Telescope",
    f = { "<cmd>Telescope find_files<cr>", "Find Files" },
    b = { "<cmd>Telescope buffers<cr>", "Buffers" },
    e = { "<cmd>Telescope file_browser<cr>", "File Browser" },
    s = { "<cmd>Telescope live_grep<cr>", "Live Grep" },    -- find string in current working directory as you type
    c = { "<cmd>Telescope grep_string<cr>", "Grep String" } -- find string under cursor in current working directory
}
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

-- LSP --
lvim.lsp.automatic_servers_installation = false
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
    return server ~= "pylsp"
end, lvim.lsp.automatic_configuration.skipped_servers)
-- PLUGINS --
lvim.plugins = {
    {
        "nvim-telescope/telescope-fzy-native.nvim",
        build = "make",
    },
    { "nvim-telescope/telescope-file-browser.nvim" },
}
lvim.builtin.telescope.defaults.initial_mode = "normal"
lvim.builtin.telescope.on_config_done = function(telescope)
    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "file_browser")
end
