return {
	dir = vim.fn.stdpath("config") .. "/lua/salim/plugins/custom/p4neorg",
	name = "p4neorg",
	config = function()
		require("p4neorg").setup({
			templates_dir = vim.fn.expand("~/TheGreatLibrary/_templates"),
			library_root = vim.fn.expand("~/TheGreatLibrary"),
		})
	end,
}
