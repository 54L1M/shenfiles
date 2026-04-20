return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		-- Standard Harpoon Adding & Navigation
		{
			"<leader>ma",
			function()
				require("harpoon"):list():add()
			end,
			desc = "Harpoon Add",
		},
		{
			"<leader>md",
			function()
				require("harpoon"):list():remove()
			end,
			desc = "Harpoon Remove Current",
		},
		{
			"<leader>m1",
			function()
				require("harpoon"):list():select(1)
			end,
			desc = "Harpoon 1",
		},
		{
			"<leader>m2",
			function()
				require("harpoon"):list():select(2)
			end,
			desc = "Harpoon 2",
		},
		{
			"<leader>m3",
			function()
				require("harpoon"):list():select(3)
			end,
			desc = "Harpoon 3",
		},
		{
			"<leader>m4",
			function()
				require("harpoon"):list():select(4)
			end,
			desc = "Harpoon 4",
		},
		{
			"<leader>mp",
			function()
				require("harpoon"):list():prev()
			end,
			desc = "Harpoon Prev",
		},
		{
			"<leader>mn",
			function()
				require("harpoon"):list():next()
			end,
			desc = "Harpoon Next",
		},

		-- Native Harpoon UI (Useful for reordering/deleting marks visually)
		{
			"<leader>me",
			function()
				local harpoon = require("harpoon")
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end,
			desc = "Harpoon Menu (Edit)",
		},

		-- Snacks Picker Integration
		{
			"<leader>mm",
			function()
				local harpoon = require("harpoon")
				Snacks.picker({
					focus = "list",
					title = "Harpoon",
					finder = function()
						local paths = {}
						for _, item in ipairs(harpoon:list().items) do
							if item and item.value ~= "" then
								-- Map the harpoon items to snacks.picker file objects
								table.insert(paths, { text = item.value, file = item.value })
							end
						end
						return paths
					end,
					-- Setting format to "file" delegates icons and styling to Snacks natively
					format = "file",
					-- You can inherit any of your custom layouts here, e.g.:
					-- layout = { preset = "vscode" }
				})
			end,
			desc = "Harpoon Marks (Snacks Picker)",
		},
	},
	config = function()
		require("harpoon"):setup()
	end,
}
