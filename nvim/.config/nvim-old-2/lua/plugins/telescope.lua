return {
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          path_display = { "smart" },
        },
        pickers = {
          find_files = {
            theme = "dropdown",
            initial_mode = "normal",
          },
          live_grep = {
            theme = "dropdown",
          },
          grep_string = {
            theme = "dropdown",
          },
          buffers = {
            theme = "dropdown",
            initial_mode = "normal",
            mappings = {
              ["n"]={
                  ["<C-d>"] = require("telescope.actions").delete_buffer,
              },
            }
          },
          help_tags = {
            theme = "dropdown",
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
          ["file_browser"] = {
            hijack_netrw = true,
            initial_mode = "normal",
            theme = "dropdown",
            mappings = {
              ["i"] = {
                -- your custom insert mode mappings
              },
              ["n"] = {
                -- your custom normal mode mappings
              },
            },
          },
        },
      })


      vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>") -- find files within current working directory, respects .gitignore
      vim.keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>") -- find string in current working directory as you type
      vim.keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>") -- find string under cursor in current working directory
      vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")  -- list open buffers in current neovim instance
      vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>") -- list available help tags
      vim.keymap.set("n", "<leader>fe", "<cmd>Telescope file_browser<cr>")

      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("file_browser")
    end,
  },
}
