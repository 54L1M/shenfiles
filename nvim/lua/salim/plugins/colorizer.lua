return {
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	opts = { -- set to setup table
	},
	config = function()
		require("colorizer").setup({
			filetypes = {
				"css",
				"javascript",
				"html",
			},
		})
	end,
}
