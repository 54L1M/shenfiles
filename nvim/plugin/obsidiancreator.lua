local M = {}

-- Create a floating window for note creation
local function create_floating_win()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.7)
	local height = 10 -- Fixed height for simplicity
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

	-- Set buffer options
	vim.bo[buf].buftype = "nofile" -- Changed to nofile to avoid save errors
	vim.bo[buf].bufhidden = "wipe"

	return buf, win
end

-- Validate and parse the note input
local function parse_note_input(input)
	-- Split the input by ':'
	local parts = {}
	for part in input:gmatch("[^:]+") do
		table.insert(parts, vim.trim(part))
	end

	-- Validate input
	if #parts < 2 then
		vim.notify("Invalid format. Use type:title:details", vim.log.levels.ERROR)
		return nil
	end

	local note_type = parts[1]:lower()
	local title = parts[2]
	local details = #parts > 2 and table.concat(parts, " ", 3) or nil

	-- Construct the full note title
	local full_title = details and string.format("%s:%s:%s", note_type, title, details)
		or string.format("%s:%s", note_type, title)

	return full_title
end

-- Create a new Obsidian note
local function create_obsidian_note(title)
	-- Use ObsidianNew command with the parsed title
	vim.cmd(string.format("ObsidianNew %s", title))
end

-- Main function to show note creation prompt
function M.create_note()
	local buf, win = create_floating_win()

	-- Set up the initial content
	local initial_content = {
		"-- Enter note in format: type:title:details",
		"-- Examples:",
		"-- work:meeting:planning about new project",
		"-- project:P4ndaLit:new feature development",
		"-- learning:golang:concurrency patterns",
		"",
		"> ",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_content)

	-- Position cursor at input line
	vim.api.nvim_win_set_cursor(win, { 7, 2 })

	-- Function to process the note
	local function process_note()
		-- Get the input line
		local lines = vim.api.nvim_buf_get_lines(buf, 6, 7, false)
		local input = lines[1] and lines[1]:sub(3) or ""

		-- Close the window
		pcall(vim.api.nvim_win_close, win, true)

		-- Parse and create note if input is valid
		if input and input ~= "" then
			local parsed_title = parse_note_input(input)
			if parsed_title then
				create_obsidian_note(parsed_title)
			end
		end
	end

	-- Set buffer-local keymaps
	vim.keymap.set("n", "<CR>", process_note, { buffer = buf })
	vim.keymap.set("i", "<CR>", function()
		-- Exit insert mode and trigger note processing
		vim.cmd("stopinsert")
		process_note()
	end, { buffer = buf })

	-- Escape to cancel
	vim.keymap.set("n", "<Esc>", function()
		pcall(vim.api.nvim_win_close, win, true)
	end, { buffer = buf })

	-- Enter insert mode
	vim.cmd("startinsert!")
end

-- Create user command
vim.api.nvim_create_user_command("ObsidianNoteCreator", M.create_note, {
	desc = "Create Obsidian note with type:title:details format",
})

-- Optional: Add a keymap
-- vim.keymap.set("n", "<leader>on", M.create_note, { desc = "Create Obsidian Note" })

return M
