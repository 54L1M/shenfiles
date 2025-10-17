return {
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()',
    config = function()
      require("go").setup({
        -- Go command
        go = "go",
        -- Use gopls for import organization
        goimports = "gopls",
        fillstruct = "gopls",
        -- Use gofumpt for enhanced formatting
        gofmt = "gofumpt",
        -- max_line_len = 120,
        tag_transform = false,
        lsp_cfg = false,
        lsp_on_attach = false,
        lsp_gofumpt = true,

        -- Format on save
        lsp_format_on_save = true,
        -- Use treesitter for syntax
        -- Use Lspsaga for the UI - skip the default keymaps
        lsp_keymaps = false,
        lsp_codelens = true,
        diagnostic = {
          hdlr = true,
          virtual_text = true, -- Updated from lsp_diag_virtual_text
          underline = true,
        },
        -- Use the enhanced UI for lspsaga
        lsp_inlay_hints = {
          enable = true,
          -- Only show inlay hints for the current line
          only_current_line = false,
          -- Event which triggers a refresh of the inlay hints.
          -- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
          -- not that this may cause higher CPU usage.
          -- This option is only respected when only_current_line and
          -- autoSetHints both are true.
          only_current_line_autocmd = "CursorHold",
          -- whether to show variable name before type hints with the inlay hints or not
          -- default: false
          show_variable_name = true,
          -- prefix for parameter hints
          parameter_hints_prefix = "󰊕 ",
          show_parameter_hints = true,
          -- prefix for all the other hints (type, chaining)
          other_hints_prefix = "=> ",
          -- whether to align to the length of the longest line in the file
          max_len_align = false,
          -- padding from the left if max_len_align is true
          max_len_align_padding = 1,
          -- whether to align to the extreme right or not
          right_align = false,
          -- padding from the right if right_align is true
          right_align_padding = 6,
          -- The color of the hints
          highlight = "Comment",
        },
      })

      -- Add custom keymaps using Lspsaga when applicable
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "go" },
        callback = function()
          local opts = { buffer = true, silent = true }

          -- Go-specific commands (not handled by LSP)
          vim.keymap.set("n", "<leader>goi", "<cmd>GoImpl<CR>", opts)
          vim.keymap.set("n", "<leader>got", "<cmd>GoAddTag<CR>", opts)
          vim.keymap.set("n", "<leader>goT", "<cmd>GoRmTag<CR>", opts)
          vim.keymap.set("n", "<leader>gott", "<cmd>GoTestFunc<CR>", opts)
          vim.keymap.set("n", "<leader>gotf", "<cmd>GoTestFile<CR>", opts)

          -- Special handling for P4nda projects
          local path = vim.fn.expand("%:p")
          if string.find(path, "P4nda") or string.find(path, "p4") then
            vim.keymap.set("n", "<leader>p4r", function()
              vim.cmd("GoRun")
            end, opts)

            vim.keymap.set("n", "<leader>p4t", function()
              vim.cmd("GoTest")
            end, opts)

            vim.keymap.set("n", "<leader>p4b", function()
              vim.cmd("GoBuild")
            end, opts)
          end
        end,
      })
    end,
  },
  {
    "romus204/go-tagger.nvim",
    config = function()
      require("go-tagger").setup({
        skip_private = true, -- Skip unexported fields (starting with lowercase)
      })
    end,
  },
}
