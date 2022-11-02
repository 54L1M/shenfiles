return {
	"rebelot/kanagawa.nvim",
	branch = "master",
	config = function()
		require("kanagawa").setup({
			compile = true,
			transparent = true,
			colors = {
				theme = {
					all = {
						ui = {
							bg_gutter = "none",
						},
					},
				},
			},
			overrides = function(colors)
				return {
					NormalFloat = { bg = "none" },
					FloatBorder = { bg = "none" },
					FloatTitle = { bg = "none" },
				}
			end,
		})
		-- vim.cmd("colorscheme kanagawa")
	end,
}
