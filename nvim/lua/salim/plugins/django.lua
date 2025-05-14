return {
	-- Add Django template support
	{
		"adoyle-h/lsp-toggle.nvim",
		dependencies = { "neovim/nvim-lspconfig" },
		config = function()
			require("lsp-toggle").setup()

			-- Auto-detect Django HTML templates
			vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
				pattern = { "*.html" },
				callback = function()
					local file_content = vim.api.nvim_buf_get_lines(0, 0, 50, false)
					for _, line in ipairs(file_content) do
						if line:match("{{") or line:match("{%%") then
							vim.bo.filetype = "htmldjango"
							break
						end
					end
				end,
			})
		end,
	},

	-- Add emmet support for Django HTML
	{
		"mattn/emmet-vim",
		ft = { "html", "htmldjango", "django-html", "css", "javascript", "typescript" },
		init = function()
			-- Enable just for html/css
			vim.g.user_emmet_install_global = 0
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "html", "htmldjango", "django-html", "css" },
				callback = function()
					vim.cmd("EmmetInstall")
				end,
			})
		end,
	},
}
