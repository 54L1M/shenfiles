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

		vim.lsp.buf.hover = vim.lsp.with(vim.lsp.buf.hover, {
			border = "rounded",
			max_width = 80,
			max_height = 20,
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
			callback = function(ev)
				-- Buffer-local map helper: only active where an LSP is attached.
				local map = function(keys, fn, desc, opts)
					opts = vim.tbl_extend("force", { buffer = ev.buf, silent = true, desc = desc }, opts or {})
					local mode = opts.mode or "n"
					opts.mode = nil
					vim.keymap.set(mode, keys, fn, opts)
				end

				-- Hover
				map("K", vim.lsp.buf.hover, "Hover")

				-- Goto (Snacks pickers)
				map("gd", function()
					Snacks.picker.lsp_definitions()
				end, "Goto Definition")
				map("gD", function()
					Snacks.picker.lsp_declarations()
				end, "Goto Declaration")
				map("gr", function()
					Snacks.picker.lsp_references()
				end, "References", { nowait = true })
				map("gI", function()
					Snacks.picker.lsp_implementations()
				end, "Goto Implementation")
				map("gy", function()
					Snacks.picker.lsp_type_definitions()
				end, "Goto Type Definition")
				map("gai", function()
					Snacks.picker.lsp_incoming_calls()
				end, "Calls Incoming")
				map("gao", function()
					Snacks.picker.lsp_outgoing_calls()
				end, "Calls Outgoing")

				-- Code (<leader>c)
				map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { mode = { "n", "v" } })
				map("<leader>cr", vim.lsp.buf.rename, "Rename Symbol")

				-- Symbols / info (<leader>l)
				map("<leader>ls", function()
					Snacks.picker.lsp_symbols()
				end, "Document Symbols")
				map("<leader>lS", function()
					Snacks.picker.lsp_workspace_symbols()
				end, "Workspace Symbols")
				map("<leader>lc", function()
					Snacks.picker.lsp_config()
				end, "LSP Info")
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
			"ts_ls",
		}

		-- Loop to enable all servers
		for _, server in ipairs(servers) do
			vim.lsp.enable(server)
		end
	end,
}
