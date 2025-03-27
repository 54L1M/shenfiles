local M = {}

-- Configuration (adjust paths as needed)
M.config = {
	vault_path = "~/Documents/TheGreatLibrary/",
	inbox_file = "inbox.md",
	-- Exclude certain directories or files
	exclude_paths = {
		"attachments/",
		"02-Templates/",
		".git/",
		".obsidian/",
		"inbox.md", -- Exclude the inbox file itself
	},
}

-- Utility function to check if a path should be excluded
local function is_path_excluded(path)
	for _, exclude_path in ipairs(M.config.exclude_paths) do
		if path:match(exclude_path) then
			return true
		end
	end
	return false
end

-- Expand and normalize paths
local function expand_path(path)
	-- Use Vim's expand to handle ~ and other path expansions
	return vim.fn.expand(path)
end

-- Create a friendly wiki-style link from a full path
local function create_wiki_link(filepath)
	local vault_path = expand_path(M.config.vault_path)
	-- Remove vault path prefix and convert to wiki link
	local relative_path = filepath:gsub(vault_path .. "/", ""):gsub("%.md$", "")
	local filename = vim.fn.fnamemodify(filepath, ":t:r")
	return string.format("[[%s|%s]]", relative_path, filename)
end

-- Recursively find inbox notes
local function find_inbox_notes(directory)
	local files = {}
	-- Use system find command for efficiency
	local expanded_dir = expand_path(directory)
	local cmd = string.format(
		"find %s -type f -name 'inbox-*' \\( -name '*.md' -o -name '*.markdown' \\)",
		expanded_dir:gsub(" ", "\\ ")
	)
	local handle = io.popen(cmd)
	if not handle then
		return files
	end
	for filepath in handle:lines() do
		if not is_path_excluded(filepath) then
			table.insert(files, filepath)
		end
	end
	handle:close()
	return files
end

-- Generate inbox notes report
function M.generate_inbox_report()
	local inbox_notes = find_inbox_notes(M.config.vault_path)
	local formatted_notes = {}

	for _, filepath in ipairs(inbox_notes) do
		table.insert(formatted_notes, create_wiki_link(filepath))
	end

	return formatted_notes
end

-- Write inbox notes to inbox.md file
function M.update_inbox_file()
	local inbox_notes = M.generate_inbox_report()
	-- Fully expand the vault path and inbox file path
	local full_vault_path = expand_path(M.config.vault_path)
	local full_inbox_path = full_vault_path .. "/" .. M.config.inbox_file

	-- Ensure the directory exists
	vim.fn.mkdir(full_vault_path, "p")

	local file, err = io.open(full_inbox_path, "w")
	if not file then
		-- Provide detailed error message
		print("Could not open inbox file for writing: " .. tostring(err))
		print("Attempted path: " .. full_inbox_path)
		return
	end

	-- Write header
	file:write("# Inbox Notes\n")
	file:write("Last Synced: " .. os.date("%Y-%m-%d %H:%M") .. "\n\n")

	-- Write inbox notes
	for _, note in ipairs(inbox_notes) do
		file:write("- " .. note .. "\n")
	end

	file:close()
	print("Inbox file updated successfully!")
end

-- Create Neovim commands
vim.api.nvim_create_user_command("ObsidianUpdateInbox", M.update_inbox_file, {})

-- Optional: Add a keybinding
vim.keymap.set("n", "<leader>oui", M.update_inbox_file, {
	desc = "Update Obsidian Inbox Notes",
})

return M
