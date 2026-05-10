return {
	-- "54L1M/Oshen.nvim",
	dir = vim.fn.expand("~/Documents/pf4/Oshen.nvim"),
	lazy = false,
	priority = 1000,
	config = function()
		require("oshen").setup({
			transparent = true, -- set false for opaque background
		})
	end,
}
