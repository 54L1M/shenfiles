return {
	"vyfor/cord.nvim",
	build = ":Cord update",
	-- opts = {}
	config = function()
		require("cord").setup()
	end,
}
