return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")

		--catppuccin colors
		-- local colors = {
		-- 	blue = "#8aadf4",
		-- 	green = "#a6da95",
		-- 	violet = "#c6a0f6",
		-- 	yellow = "#eed49f",
		-- 	red = "#ed8796",
		-- 	fg = "#cad3f5",
		-- 	bg = "#363a4f",
		-- 	semilightgray = "#5b6078",
		-- 	inactive_bg = "#181926",
		-- }
		-- kanagawa colors
		local colors = {
			blue = "#7FB4CA",
			green = "#98BB6C",
			violet = "#957FB8",
			yellow = "#E6C384",
			red = "#E46876",
			fg = "#938AA9",
			bg = "#2A2A37	",
			semilightgray = "#54546D",
			inactive_bg = "#1F1F28",
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
				globalstatus = false,
			},
			sections = {
				lualine_a = { {
					"mode",
					fmt = function(str)
						return str:sub(1, 1)
					end,
				} },
				lualine_b = {
					{ "filename", path = 4, shorting_target = 110, symbols = { modified = "●" } },
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
			inactive_sections = {
				lualine_a = { {
					"mode",
					fmt = function(str)
						return str:sub(1, 1)
					end,
				} },
				lualine_b = {
					{ "filename", path = 1, shorting_target = 40, symbols = { modified = "●" } },
				},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = { { "location" } },
			},
		})
	end,
}
