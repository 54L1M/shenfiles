return {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "hl" },
			},
			completion = {
				callSnippet = "Replace",
			},
			workspace = {
				checkThirdParty = false, -- This can also help with performance
			},
		},
	},
}
