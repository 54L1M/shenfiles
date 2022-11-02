return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		vim.diagnostic.config({
			virtual_text = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
			float = { border = "rounded", source = true },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.INFO] = " ",
					[vim.diagnostic.severity.HINT] = " ",
				},
			},
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }

				opts.desc = "Code Action"
				vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Rename Symbol"
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "LSP Hover"
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			end,
		})

		-- INJECT BLINK CAPABILITIES GLOBALLY (The 0.11+ way)
		-- This merges with every server config you enable below.
		local blink = require("blink.cmp")
		vim.lsp.config("*", {
			capabilities = blink.get_lsp_capabilities(),
		})

		local servers = {
			"lua_ls",
			"pyright",
			"ruff",
			"gopls",
			"dockerls",
			"docker_compose_language_service",
			"bashls",
			"clangd",
		}

		-- Loop to enable all servers
		for _, server in ipairs(servers) do
			vim.lsp.enable(server)
		end
	end,
}
