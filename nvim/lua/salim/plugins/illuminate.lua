return {
	"RRethy/vim-illuminate",
	config = function()
		require("illuminate").configure({
			-- Delay in milliseconds before highlighting
			delay = 100,
			-- Providers to use for finding references
			providers = {
				"lsp",
				"treesitter",
				"regex",
			},
			-- Filetypes to exclude
			filetypes_denylist = {
				"TelescopePrompt",
				"dashboard",
				"lazy",
				"oil",
			},
			-- Modes to highlight references in (e.g., 'n', 'i', 'v', etc.)
			modes_allowlist = { "n" },
			-- Other configurations
			under_cursor = true, -- Highlights the word under the cursor
			min_count_to_highlight = 2,
		})

		-- Set highlight groups if desired
		vim.cmd([[highlight IlluminatedWordText guibg=#3C3836]])
		vim.cmd([[highlight IlluminatedWordRead guibg=#3C3836]])
		vim.cmd([[highlight IlluminatedWordWrite guibg=#504945]])
		-- vim.cmd("highlight IlluminatedWordText guibg=#45475a guifg=NONE gui=NONE")
		-- vim.cmd("highlight IlluminatedWordRead guibg=#394b70 guifg=NONE gui=NONE")
		-- vim.cmd("highlight IlluminatedWordWrite guibg=#6c7086 guifg=NONE gui=bold")
		-- vim.cmd("highlight link IlluminatedWordText Visual")
		-- vim.cmd("highlight link IlluminatedWordRead Search")
		-- vim.cmd("highlight link IlluminatedWordWrite DiffAdd")
	end,
}
