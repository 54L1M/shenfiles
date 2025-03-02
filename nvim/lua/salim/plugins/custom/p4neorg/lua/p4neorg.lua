-- p4neorg: A Neovim plugin for Neorg templates

local M = {}

-- Dependency check
local has_plenary, plenary = pcall(require, "plenary")
local has_nui, Popup = pcall(require, "nui.popup")

if not has_plenary or not has_nui then
	vim.notify("p4neorg requires plenary.nvim and nui.nvim", vim.log.levels.ERROR)
	return M
end

-- Configuration with defaults
M.config = {
	templates_dir = vim.fn.expand("~/TheGreatLibrary/_templates"),
	library_root = vim.fn.expand("~/TheGreatLibrary"),
	default_template_ext = "norg",
	variable_pattern = "${([^:}]+)(:([^}]+))?}",
	date_format = "%Y%m%d%H%M%S",
}

-- Structure definitions for different note types
local note_types = {
	work = {
		base_dir = "Work",
		subtypes = {
			meeting = {
				dir = "Meetings",
				filename_format = function()
					return os.date(M.config.date_format)
				end,
			},
			doc = {
				dir = "Documentation",
				filename_format = function(name)
					return name or os.date(M.config.date_format)
				end,
			},
			task = {
				dir = "Tasks",
				filename_format = function(name)
					return name or os.date(M.config.date_format)
				end,
			},
			reference = {
				dir = "References",
				filename_format = function(name)
					return name or os.date(M.config.date_format)
				end,
			},
		},
		default_subtype = "meeting",
	},
	learning = {
		base_dir = "Learning",
		subtypes = {
			bash = { dir = "Bash" },
			python = { dir = "Python" },
			django = { dir = "Django" },
			js = { dir = "JavaScript" },
			golang = { dir = "Golang" },
			neovim = { dir = "Neovim" },
			book = { dir = "Books" },
			course = { dir = "Courses" },
		},
		default_subtype = nil,
		filename_format = function(name)
			return name or os.date(M.config.date_format)
		end,
	},
	project = {
		base_dir = "Projects",
		subtypes = {
			p4ndacode = { dir = "P4ndaCode" },
			p4ndalearn = { dir = "P4ndaLearn" },
			p4ndatools = { dir = "P4ndaTools" },
			archive = { dir = "Archive" },
		},
		default_subtype = nil,
		filename_format = function(name)
			return name or os.date(M.config.date_format)
		end,
	},
	personal = {
		base_dir = "Personal",
		subtypes = {
			goals = { dir = "Goals" },
			journal = { dir = "Journal" },
			notes = { dir = "Notes" },
			reference = { dir = "References" },
		},
		default_subtype = "notes",
		filename_format = function(name)
			return name or os.date(M.config.date_format)
		end,
	},
}

-- Parse template variables from file content
local function parse_template_variables(content)
	local variables = {}
	local count = 0

	-- Look for ${...} patterns
	for var_match in content:gmatch("%${([^}]+)}") do
		count = count + 1
		vim.notify("Found raw match: " .. var_match, vim.log.levels.INFO)

		-- Split into name and options if there's a colon
		local var_name, var_options = var_match:match("([^:]+):?(.*)")

		if var_name then
			vim.notify("Variable name: " .. var_name, vim.log.levels.INFO)

			local options = {}
			if var_options and var_options ~= "" then
				vim.notify("Has options: " .. var_options, vim.log.levels.INFO)
				for option in var_options:gmatch("([^|]+)") do
					-- Make sure option is trimmed and added as a string
					local trimmed_option = option:gsub("^%s*(.-)%s*$", "%1")
					table.insert(options, trimmed_option)
				end
			end

			variables[var_name] = {
				name = var_name,
				options = #options > 0 and options or nil,
				value = "", -- Default empty value
			}
		end
	end

	vim.notify("Total variables found: " .. count, vim.log.levels.INFO)
	return variables
end
-- Replace variables in content
local function replace_variables(content, variables)
	-- Use a simpler approach to match variables
	local result = content:gsub("%${([^}]+)}", function(var_match)
		-- Split into name and options
		local var_name, var_options = var_match:match("([^:]+):?(.*)")

		if var_name and variables[var_name] and variables[var_name].value and variables[var_name].value ~= "" then
			-- Handle special "date" variable
			if var_name == "date" and var_options and var_options ~= "" then
				local format = var_options
				return os.date(format:gsub("YYYY", "%%Y"):gsub("MM", "%%m"):gsub("DD", "%%d"))
			else
				return variables[var_name].value
			end
		end

		-- Return original if not replaced
		return "${" .. var_match .. "}"
	end)

	return result
end
-- Create popup form for variables
function M.create_template_form(variables, callback)
	-- Check if we have any variables at all
	if vim.tbl_isempty(variables) then
		callback({})
		return
	end

	-- Debug - Show what variables were found
	vim.notify("Found " .. vim.tbl_count(variables) .. " variables in template", vim.log.levels.INFO)

	-- Set up the popup window
	local popup = Popup({
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
			text = {
				top = " Template Variables ",
				top_align = "center",
			},
		},
		position = "50%",
		size = {
			width = "80%",
			height = vim.tbl_count(variables) + 4,
		},
	})

	local form_items = {}
	local max_label_width = 0

	-- Calculate maximum label width for alignment
	for name, _ in pairs(variables) do
		max_label_width = math.max(max_label_width, #name)
	end

	-- Set up form fields
	local row = 1
	local sorted_vars = {}
	for name, var in pairs(variables) do
		table.insert(sorted_vars, { name = name, var = var })
	end

	-- Sort variables to keep a consistent order
	table.sort(sorted_vars, function(a, b)
		return a.name < b.name
	end)

	for _, item in ipairs(sorted_vars) do
		local name = item.name
		local var = item.var

		-- Create label
		popup:map("n", tostring(row), function()
			vim.api.nvim_win_set_cursor(popup.winid, { row, max_label_width + 2 })
			vim.cmd("startinsert")
		end, {})

		-- Create input field
		local input_field = {
			row = row,
			col = max_label_width + 2,
			width = popup._.size.width - max_label_width - 4,
			var_name = name,
			value = "",
		}

		if var.options then
			-- Dropdown for options
			input_field.options = var.options
			input_field.current_option = 1
		end

		table.insert(form_items, input_field)
		row = row + 1
	end

	-- Set up the buffer content
	local buffer_lines = {}
	for i, field in ipairs(form_items) do
		local line = string.format("%-" .. max_label_width .. "s: ", field.var_name)
		if field.options then
			line = line .. field.options[field.current_option]
		end
		table.insert(buffer_lines, line)
	end

	-- Add commit/cancel instructions
	table.insert(buffer_lines, "")
	table.insert(buffer_lines, "Press <Enter> to apply, <Esc> to cancel")

	vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, buffer_lines)

	-- Set up key mappings
	popup:map("n", "<CR>", function()
		local results = {}

		-- Collect values from each field
		for i, field in ipairs(form_items) do
			local line = vim.api.nvim_buf_get_lines(popup.bufnr, field.row - 1, field.row, false)[1]
			local value = ""

			if field.options then
				value = field.options[field.current_option]
			else
				-- Extract value after the colon and space
				local prefix_length = field.var_name:len() + 2 -- +2 for ": "
				value = line:sub(prefix_length + 1) -- +1 to skip the space after colon
			end

			results[field.var_name] = {
				name = field.var_name,
				value = value,
			}
		end

		-- Handle special variables like date
		for name, var in pairs(variables) do
			if name == "date" and not results[name] then
				local format = var.options and var.options[1] or "%Y-%m-%d"
				local formatted_date = os.date(format:gsub("YYYY", "%Y"):gsub("MM", "%m"):gsub("DD", "%d"))
				results[name] = {
					name = name,
					value = formatted_date,
				}
			end
		end

		popup:unmount()
		callback(results)
	end, {})

	popup:map("n", "<Esc>", function()
		popup:unmount()
		callback(nil)
	end, {})

	-- Add insert mode mappings
	popup:map("i", "<CR>", function()
		local results = {}

		-- Collect values from each field
		for i, field in ipairs(form_items) do
			local line = vim.api.nvim_buf_get_lines(popup.bufnr, field.row - 1, field.row, false)[1]
			local value = ""

			if field.options then
				value = field.options[field.current_option]
			else
				-- Extract value after the colon and space
				value = line:sub(field.var_name:len() + 3)
			end

			results[field.var_name] = {
				name = field.var_name,
				value = value,
			}
		end

		-- Handle special variables like date
		for name, var in pairs(variables) do
			if name == "date" and not results[name] then
				local format = var.options and var.options[1] or "%Y-%m-%d"
				local formatted_date = os.date(format:gsub("YYYY", "%Y"):gsub("MM", "%m"):gsub("DD", "%d"))
				results[name] = {
					name = name,
					value = formatted_date,
				}
			end
		end

		popup:unmount()
		callback(results)
	end, {})

	popup:map("i", "<Esc>", function()
		vim.cmd("stopinsert")
	end, {})

	-- Handle option selection for dropdown fields
	for i, field in ipairs(form_items) do
		if field.options then
			popup:map("n", "<Tab>", function()
				if vim.api.nvim_win_get_cursor(popup.winid)[1] == field.row then
					field.current_option = field.current_option % #field.options + 1
					local line = string.format(
						"%-" .. max_label_width .. "s: %s",
						field.var_name,
						field.options[field.current_option]
					)
					vim.api.nvim_buf_set_lines(popup.bufnr, field.row - 1, field.row, false, { line })
				end
			end, {})
		end
	end

	-- Open the popup
	popup:mount()

	-- Position cursor at the first field and enter insert mode
	vim.api.nvim_win_set_cursor(popup.winid, { 1, max_label_width + 2 })
	vim.cmd("startinsert")
end

-- Ensure directory exists
local function ensure_dir_exists(dir)
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
	return dir
end

-- Debug function to print table contents
local function debug_print_table(tbl, indent)
	indent = indent or 0
	local indent_str = string.rep("  ", indent)

	for k, v in pairs(tbl) do
		if type(v) == "table" then
			vim.notify(indent_str .. k .. " = {", vim.log.levels.INFO)
			debug_print_table(v, indent + 1)
			vim.notify(indent_str .. "}", vim.log.levels.INFO)
		else
			vim.notify(indent_str .. k .. " = " .. tostring(v), vim.log.levels.INFO)
		end
	end
end

-- Create a new note from template
function M.new_note(note_type, subtype, name)
	-- Validate note type
	local type_config = note_types[note_type]
	if not type_config then
		vim.notify("Unknown note type: " .. tostring(note_type), vim.log.levels.ERROR)
		return
	end

	-- Determine subtype
	subtype = subtype or type_config.default_subtype
	if not subtype and vim.tbl_count(type_config.subtypes) > 0 then
		vim.ui.select(vim.tbl_keys(type_config.subtypes), {
			prompt = "Select " .. note_type .. " subtype:",
		}, function(choice)
			if choice then
				M.new_note(note_type, choice, name)
			end
		end)
		return
	elseif subtype and not type_config.subtypes[subtype] then
		vim.notify("Unknown subtype: " .. subtype .. " for " .. note_type, vim.log.levels.ERROR)
		return
	end

	-- Build template path
	local template_path = M.config.templates_dir .. "/" .. note_type .. "." .. M.config.default_template_ext

	-- Check if template exists
	if vim.fn.filereadable(template_path) == 0 then
		vim.notify("Template not found: " .. template_path, vim.log.levels.ERROR)
		return
	end

	-- Determine target directory
	local base_dir = M.config.library_root .. "/" .. type_config.base_dir
	local target_dir = base_dir

	if subtype and type_config.subtypes[subtype] then
		target_dir = base_dir .. "/" .. type_config.subtypes[subtype].dir
	end

	ensure_dir_exists(target_dir)

	-- Read template content
	local template_content = table.concat(vim.fn.readfile(template_path), "\n")

	-- Debug - Show template content
	vim.notify("Template loaded, length: " .. #template_content, vim.log.levels.INFO)

	-- Parse variables
	local variables = parse_template_variables(template_content)

	-- Debug - Show variables
	vim.notify("Found " .. vim.tbl_count(variables) .. " variables", vim.log.levels.INFO)

	-- Show form for variables
	M.create_template_form(variables, function(results)
		if not results then
			vim.notify("Template creation cancelled", vim.log.levels.INFO)
			return
		end

		-- Replace variables in content
		local new_content = replace_variables(template_content, results)

		-- Determine filename
		local filename = nil
		if subtype and type_config.subtypes[subtype] and type_config.subtypes[subtype].filename_format then
			filename = type_config.subtypes[subtype].filename_format(name)
		elseif type_config.filename_format then
			filename = type_config.filename_format(name)
		else
			filename = (results.title and results.title.value) or name or os.date(M.config.date_format)
		end

		-- Clean filename and add extension
		filename = filename:gsub(" ", "-"):gsub("[^%w%-]", ""):lower()
		if not filename:match("%." .. M.config.default_template_ext .. "$") then
			filename = filename .. "." .. M.config.default_template_ext
		end

		-- Full path
		local full_path = target_dir .. "/" .. filename

		-- Create new buffer with content
		local bufnr = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn.split(new_content, "\n"))
		vim.api.nvim_buf_set_name(bufnr, full_path)
		vim.api.nvim_set_current_buf(bufnr)
		-- Set the filetype to norg
		vim.api.nvim_buf_set_option(bufnr, "filetype", "norg")
		vim.cmd("write")

		vim.notify("Created new note: " .. filename .. " in " .. target_dir, vim.log.levels.INFO)
	end)
end

-- Get subtypes for a note type (for completion)
local function get_subtypes(note_type)
	if note_types[note_type] and note_types[note_type].subtypes then
		return vim.tbl_keys(note_types[note_type].subtypes)
	end
	return {}
end

-- Setup function
function M.setup(opts)
	-- Merge configs
	if opts then
		M.config = vim.tbl_deep_extend("force", M.config, opts)
	end

	-- Create generic command for all templates
	vim.api.nvim_create_user_command("P4Neorg", function(args)
		local split_args = vim.split(args.args, " ", { trimempty = true })
		local note_type = split_args[1]
		local subtype = split_args[2]
		local name = split_args[3]

		if not note_type or note_type == "" then
			vim.ui.select(vim.tbl_keys(note_types), {
				prompt = "Select note type:",
			}, function(choice)
				if choice then
					M.new_note(choice)
				end
			end)
		else
			M.new_note(note_type, subtype, name)
		end
	end, {
		nargs = "*",
		complete = function(arg_lead, cmd_line, cursor_pos)
			local args = vim.split(cmd_line, " ", { trimempty = true })
			local num_args = #args

			-- Remove command name from count
			if args[1] == "P4Neorg" then
				num_args = num_args - 1
			end

			if num_args <= 1 then
				-- Complete note types
				return vim.tbl_filter(function(item)
					return item:find(arg_lead, 1, true) == 1
				end, vim.tbl_keys(note_types))
			elseif num_args == 2 then
				-- Complete subtypes
				local note_type = args[#args - 1]
				return vim.tbl_filter(function(item)
					return item:find(arg_lead, 1, true) == 1
				end, get_subtypes(note_type))
			end

			return {}
		end,
	})

	-- Create shortcut commands for each note type
	for note_type, config in pairs(note_types) do
		local cmd_name = "P4n" .. note_type

		vim.api.nvim_create_user_command(cmd_name, function(args)
			local split_args = vim.split(args.args, " ", { trimempty = true })
			local subtype = split_args[1]
			local name = split_args[2]

			M.new_note(note_type, subtype, name)
		end, {
			nargs = "*",
			complete = function(arg_lead, cmd_line, cursor_pos)
				local args = vim.split(cmd_line, " ", { trimempty = true })
				local num_args = #args

				-- Remove command name from count
				if args[1] == cmd_name then
					num_args = num_args - 1
				end

				if num_args <= 1 then
					-- Complete subtypes
					return vim.tbl_filter(function(item)
						return item:find(arg_lead, 1, true) == 1
					end, get_subtypes(note_type))
				end

				return {}
			end,
		})
	end

	return M
end

return M
