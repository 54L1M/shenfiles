local M = {}

-- Configuration (adjust paths as needed)
M.config = {
	vault_path = "~/Documents/TheGreatLibrary/",
	tasks_file = "tasks.md",
	-- Exclude certain directories or files
	exclude_paths = {
		"attachments/",
		"02-Templates/",
		".git/",
		".obsidian/",
		"tasks.md", -- Exclude the tasks file itself
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

-- Extract checkbox tasks from a file
local function extract_tasks_from_file(filepath)
	local tasks = {}
	local file = io.open(filepath, "r")
	if not file then
		return tasks
	end

	for line in file:lines() do
		-- Match different checkbox formats
		local task_match = line:match("^%s*[-*]%s*%[[ x]%]%s*(.+)")
		if task_match then
			table.insert(tasks, {
				text = task_match,
				status = line:match("%[[ x]%]") == "[ ]" and "Incomplete" or "Complete",
				source = create_wiki_link(filepath),
			})
		end
	end
	file:close()
	return tasks
end

-- Recursively find markdown files
local function find_markdown_files(directory)
	local files = {}
	-- Use system find command for efficiency
	local expanded_dir = expand_path(directory)
	local cmd =
		string.format("find %s -type f \\( -name '*.md' -o -name '*.markdown' \\)", expanded_dir:gsub(" ", "\\ "))
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

-- Generate tasks report
function M.generate_tasks_report()
	local all_tasks = {}
	local markdown_files = find_markdown_files(M.config.vault_path)
	for _, filepath in ipairs(markdown_files) do
		local file_tasks = extract_tasks_from_file(filepath)
		for _, task in ipairs(file_tasks) do
			table.insert(all_tasks, task)
		end
	end
	return all_tasks
end

-- Write tasks to Tasks.md file
function M.update_tasks_file()
	local tasks = M.generate_tasks_report()
	-- Fully expand the vault path and tasks file path
	local full_vault_path = expand_path(M.config.vault_path)
	local full_tasks_path = full_vault_path .. "/" .. M.config.tasks_file

	-- Ensure the directory exists
	vim.fn.mkdir(full_vault_path, "p")

	local file, err = io.open(full_tasks_path, "w")
	if not file then
		-- Provide detailed error message
		print("Could not open tasks file for writing: " .. tostring(err))
		print("Attempted path: " .. full_tasks_path)
		return
	end

	-- Write header
	file:write("# Tasks Overview\n")
	file:write("Last Synced: " .. os.date("%Y-%m-%d %H:%M") .. "\n")

	-- Group tasks by status
	local grouped_tasks = {
		Incomplete = {},
		Complete = {},
	}

	for _, task in ipairs(tasks) do
		table.insert(grouped_tasks[task.status], task)
	end

	-- Write Incomplete Tasks
	file:write("\n## Incomplete Tasks\n")
	for _, task in ipairs(grouped_tasks.Incomplete) do
		file:write(string.format("- [ ] %s (from %s)\n", task.text, task.source))
	end

	-- Write Complete Tasks
	file:write("\n## Completed Tasks\n")
	for _, task in ipairs(grouped_tasks.Complete) do
		file:write(string.format("- [x] %s (from %s)\n", task.text, task.source))
	end

	file:close()
	print("Tasks file updated successfully!")
end

-- Create Neovim commands
vim.api.nvim_create_user_command("ObsidianUpdateTasks", M.update_tasks_file, {})

-- Optional: Add a keybinding
vim.keymap.set("n", "<leader>out", M.update_tasks_file, {
	desc = "Update Obsidian Tasks Overview",
})

return M
