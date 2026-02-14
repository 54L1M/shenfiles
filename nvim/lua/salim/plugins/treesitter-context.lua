return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		enable = true, -- Enable this plugin (Can be disabled globally or for specific filetypes)
		max_lines = 2, -- How many lines the window should span. Values <= 0 mean no limit.
		trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
		patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
			default = {
				"class",
				"function",
				"method",
				"for", -- These are helpful to see which loop you are inside
				"while",
				"if",
				"switch",
				"case",
			},
		},
	},
}
