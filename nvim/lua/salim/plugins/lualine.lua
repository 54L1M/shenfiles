return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")

		local colors = {
			-- blue = "#65D1FF",
			blue = "#8aadf4",
			-- green = "#3EFFDC",
			green = "#a6da95",
			-- violet = "#FF61EF",
			violet = "#c6a0f6",
			-- yellow = "#FFDA7B",
			yellow = "#eed49f",
			-- red = "#FF4A4A",
			red = "#ed8796",
			-- fg = "#c3ccdc",
			fg = "#cad3f5",
			-- bg = "#112638",
			bg = "#363a4f",
			inactive_bg = "#2c3043",
		}

		local my_lualine_theme = {
			normal = {
				a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			insert = {
				a = { bg = colors.green, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			visual = {
				a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			command = {
				a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			replace = {
				a = { bg = colors.red, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			inactive = {
				a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
				b = { bg = colors.inactive_bg, fg = colors.semilightgray },
				c = { bg = colors.inactive_bg, fg = colors.semilightgray },
			},
		}
		-- configure lualine with modified theme
		lualine.setup({
			extensions = { "oil", "trouble", "mason", "quickfix", "ctrlspace" },
			options = {
				theme = my_lualine_theme,
				section_separators = "",
				component_separators = "",
			},
			sections = {
				lualine_a = { {
					"mode",
					fmt = function(str)
						return str:sub(1, 1)
					end,
				} },
				lualine_b = {
					{ "filename", path = 1, shorting_target = 40, symbols = { modified = "●" } },
				},
				lualine_c = { { "diagnostics" } },
				lualine_x = { { "diff" } },
				lualine_y = { { "branch" } },
				lualine_z = {
					{
						"location",
						color = { bg = colors.bg, fg = colors.fg },
					},
				},
			},
		})
	end,
}
