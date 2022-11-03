local status, telescope = pcall(require, "telescope")
if not status then
  return
end

-- import telescope actions safely
local actions_setup, actions = pcall(require, "telescope.actions")
if not actions_setup then
	return
end

-- configure telescope
telescope.setup({
	defaults = {

    path_display = {"smart"},

		mappings = {
			i = {
				["<C-k>"] = actions.move_selection_previous, -- move to prev result
				["<C-j>"] = actions.move_selection_next, -- move to next result
				["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- send selected to quickfixlist
			},
		},
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
        n = {
            ["<C-d>"] = actions.delete_buffer
        },
      },
    },
    help_tags = {
      theme = "dropdown",
    },
 },
   extensions = {
    file_browser = {
      initial_mode = "normal",
      theme = "dropdown",
      -- disables netrw and use telescope-file-browser in its place
      hijack_netrw = true,
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

telescope.load_extension("fzf")
telescope.load_extension("file_browser")
