return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"leoluz/nvim-dap-go",
		"mfussenegger/nvim-dap-python",
		"theHamsta/nvim-dap-virtual-text",
	},
	keys = {
		{
			"<leader>Dc",
			function()
				require("dap").continue()
			end,
			desc = "Debug: Start/Continue",
		},
		{
			"<leader>Dsi",
			function()
				require("dap").step_into()
			end,
			desc = "Debug: Step Into",
		},
		{
			"<leader>DsO",
			function()
				require("dap").step_over()
			end,
			desc = "Debug: Step Over",
		},
		{
			"<leader>Dso",
			function()
				require("dap").step_out()
			end,
			desc = "Debug: Step Out",
		},
		{
			"<leader>Db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Debug: Toggle Breakpoint",
		},
		{
			"<leader>DB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Debug: Set Conditional Breakpoint",
		},
		{
			"<leader>Dt",
			function()
				require("dapui").toggle()
			end,
			desc = "Debug: Toggle UI",
		},
		{
			"<leader>Dl",
			function()
				require("dap").run_last()
			end,
			desc = "Debug: Run Last Configuration",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- 1. Setup UI
		dapui.setup({
			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
			controls = {
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},
		})

		-- 2. Auto-open UI listeners
		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		dap.listeners.before.event_exited["dapui_config"] = dapui.close

		-- 3. Virtual Text Setup
		require("nvim-dap-virtual-text").setup()

		-- 4. Go Setup
		require("dap-go").setup()

		-- 5. Python Setup (Core)
		require("dap-python").setup("python")

		-- 6. Custom Django Configurations
		-- "Launch Runserver" - Good for web requests
		table.insert(dap.configurations.python, {
			type = "python",
			request = "launch",
			name = "Django: Launch Runserver",
			program = function()
				return vim.loop.cwd() .. "/manage.py"
			end,
			args = { "runserver", "--noreload" },
			django = true,
			justMyCode = true,
			console = "integratedTerminal",
		})

		-- "Launch Shell" - Good for interacting inside Neovim
		table.insert(dap.configurations.python, {
			type = "python",
			request = "launch",
			name = "Django: Launch Shell",
			program = function()
				return vim.loop.cwd() .. "/manage.py"
			end,
			args = { "shell" },
			django = true,
			justMyCode = true,
			console = "integratedTerminal",
		})

		-- "Attach Local" - BEST FOR YOUR TMUX WORKFLOW
		table.insert(dap.configurations.python, {
			type = "python",
			request = "attach",
			name = "Django: Attach Local",
			connect = {
				host = "127.0.0.1",
				port = 5678,
			},
		})
	end,
}
