return {
	"nvimdev/lspsaga.nvim",
	event = "LspAttach",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons" },
		{ "nvim-treesitter/nvim-treesitter" },
	},
	config = function()
		require("lspsaga").setup({
			-- Use rounded borders
			ui = {
				border = "rounded",
				colors = {
					normal_bg = "#1e2030",
				},
			},
			lightbulb = {
				enable = false,
				sign = true,
				virtual_text = false,
			},
			symbol_in_winbar = {
				enable = true,
				separator = " > ",
				hide_keyword = true,
				ignore_patterns = {},
				show_file = false,
			},
			hover = {
				max_width = 0.6,
				open_link = "gx",
				open_browser = "!chrome",
			},
			-- Make finder use telescope if available
			finder = {
				-- Method to use: 'lsp' or 'telescope'
				method = "telescope",
				max_height = 0.5,
				left_width = 0.3,
				right_width = 0.7,
				layout = "float", -- Options: float, expand, normal
				keys = {
					toggle_or_open = "<CR>",
					quit = "q",
				},
			},
		})

		-- Create an autocommand to set Lspsaga keymaps as the primary LSP interface
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("LspsagaPrimaryKeymaps", { clear = true }),
			callback = function(args)
				-- Use lspsaga for all filetypes
				local opts = { buffer = args.buf, silent = true }

				-- Override standard LSP keymaps with Lspsaga
				vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)
				vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>", opts)
				vim.keymap.set("n", "gD", "<cmd>Lspsaga goto_type_definition<CR>", opts)
				vim.keymap.set("n", "gR", "<cmd>Lspsaga finder<CR>", opts)
				vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts)
				vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", opts)
				vim.keymap.set("n", "<leader>ol", "<cmd>Lspsaga outline<CR>", opts)
				vim.keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
				vim.keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
				vim.keymap.set("n", "<leader>d", "<cmd>Lspsaga show_line_diagnostics<CR>", opts)
				vim.keymap.set("n", "<leader>cd", "<cmd>Lspsaga show_cursor_diagnostics<CR>", opts)
				vim.keymap.set("n", "<leader>sb", "<cmd>Lspsaga show_buf_diagnostics<CR>", opts)

				-- Add Lspsaga preview functionality
				vim.keymap.set("n", "gp", "<cmd>Lspsaga peek_definition<CR>", opts)
				vim.keymap.set("n", "gP", "<cmd>Lspsaga peek_type_definition<CR>", opts)

				-- Enhanced callhierarchy
				vim.keymap.set("n", "<leader>ci", "<cmd>Lspsaga incoming_calls<CR>", opts)
				vim.keymap.set("n", "<leader>co", "<cmd>Lspsaga outgoing_calls<CR>", opts)
			end,
		})
	end,
}
