local M = {}

local ns_id = vim.api.nvim_create_namespace("python_scratch")
local scratch_win = nil
local scratch_buf = nil

-- Create a floating window
local function create_floating_win()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.7)
	local height = math.floor(vim.o.lines * 0.6)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)
	vim.bo[buf].filetype = "python"
	vim.bo[buf].bufhidden = "wipe"
	return buf, win
end

-- Execute Python code and display results
local function run_python(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local code = table.concat(lines, "\n")

	local output = vim.fn.system("python3 -c " .. vim.fn.shellescape(code))
	-- Trim trailing whitespace and null characters
	output = output:gsub("%s+$", "")
	-- Clear previous extmarks in the namespace
	vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

	-- Place the output as virtual text at the end of the buffer
	local line_count = vim.api.nvim_buf_line_count(buf)
	vim.api.nvim_buf_set_extmark(buf, ns_id, line_count - 1, 0, {
		virt_text = { { output, "Comment" } },
		virt_text_pos = "eol",
	})
end

function M.toggle_scratch()
	if scratch_win and vim.api.nvim_win_is_valid(scratch_win) then
		vim.api.nvim_win_close(scratch_win, true)
		scratch_win = nil
		scratch_buf = nil
	else
		scratch_buf, scratch_win = create_floating_win()

		vim.keymap.set("n", "<leader>r", function()
			run_python(scratch_buf)
		end, { buffer = scratch_buf, desc = "Run Python Code" })

		vim.api.nvim_buf_set_lines(scratch_buf, 0, -1, false, {
			"# Write 🐍 Python code here...",
			"",
		})
	end
end

vim.api.nvim_create_user_command("PythonScratch", M.toggle_scratch, { desc = "Toggle Python Scratch Buffer" })

vim.keymap.set("n", "<leader>ps", M.toggle_scratch, { desc = "Toggle Python Scratch" })

return M
