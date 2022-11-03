-- Packer
require("shen.plugins-setup") -- should be at top
-- core configs
require("shen.core.colorscheme")
require("shen.core.keymaps")
require("shen.core.options")
-- plugins configs
require("shen.plugins.comment")
require("shen.plugins.lualine")
require("shen.plugins.nvim-cmp")
require("shen.plugins.telescope")
require("shen.plugins.transparent")
require("shen.plugins.bufferline")
require("shen.plugins.bufdel")
require("shen.plugins.autopairs")
require("shen.plugins.treesitter")
require("shen.plugins.gitsigns")
-- lsp configs
require("shen.plugins.lsp.mason")
require("shen.plugins.lsp.lspsaga")
require("shen.plugins.lsp.lspconfig")
require("shen.plugins.lsp.null-ls")
