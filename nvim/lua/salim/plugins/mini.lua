return {
	{ "echasnovski/mini.icons", version = "*", opts = {} },

	{
		"echasnovski/mini.pairs",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},

	{
		"echasnovski/mini.surround",
		version = "*",
		opts = {},
	},

	{
		"echasnovski/mini.move",
		version = "*",

		opts = {
			mappings = {
				-- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
				left = "<M-h>",
				right = "<M-l>",
				down = "<M-j>",
				up = "<M-k>",

				-- Move current line in Normal mode
				line_left = "<M-h>",
				line_right = "<M-l>",
				line_down = "<M-j>",
				line_up = "<M-k>",
			},
		},
	},
}
