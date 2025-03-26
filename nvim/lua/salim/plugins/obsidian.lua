--- plugins/obsidian.lua
return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
		"nvim-telescope/telescope.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "TheGreatLibrary",
				path = "~/Documents/TheGreatLibrary/",
			},
		},
		-- Template directory name
		templates = {
			folder = "02-Templates",
			date_format = "%d-%m-%Y",
			time_format = "%H:%M",
		},
		notes_subdir = "00-Notes",
		attachments = {
			folder = "attachments",
		},
		-- Configure wiki link display
		wiki_link_func = function(opts)
			if opts.id == nil then
				return string.format("[[%s]]", opts.label)
			elseif opts.label ~= opts.id then
				return string.format("[[%s|%s]]", opts.id, opts.label)
			else
				-- Extract title part from ID (everything before the timestamp marker)
				local title = opts.id:match("(.+)%-%-[%d%-]+%-%a+$") or opts.id
				-- Format work meeting notes specially
				if title:match("^work%-(.+)%-meeting$") then
					local meeting_type = title:match("^work%-(.+)%-meeting$")
					title = meeting_type:gsub("^%l", string.upper) .. " Meeting"
				else
					-- Convert dashes to spaces and capitalize words
					title = title:gsub("%-", " "):gsub("(%a)([%w_']*)", function(first, rest)
						return first:upper() .. rest:lower()
					end)
				end
				return string.format("[[%s|%s]]", opts.id, title)
			end
		end,
		ui = {
			enable = true,
			update_debounce = 200,
			checkboxes = {
				[" "] = { char = "☐", hl_group = "ObsidianTodo" },
				["x"] = { char = "☑", hl_group = "ObsidianDone" },
			},
		},
		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},
	},
	config = function(_, opts)
		-- Define shared utility functions
		local function parse_structured_title(title)
			if not title then
				return {
					type = "note",
					name = nil,
					details = nil,
					original = title,
				}
			end

			local title_lower = title:lower()
			local result = {
				type = nil,
				name = nil,
				details = nil,
				original = title,
			}

			-- Handle project:name:details format
			if string.find(title_lower, "project%s*:") then
				result.type = "project"
				result.name, result.details = title:match("project%s*:%s*([^:]+)%s*:%s*(.+)")
				if not result.details and result.name then
					-- Handle case with just project:name (no details)
					result.name = title:match("project%s*:%s*(.+)")
				end

			-- Handle work:topic:details format
			elseif string.find(title_lower, "work%s*:") then
				result.type = "work"
				result.name, result.details = title:match("work%s*:%s*([^:]+)%s*:%s*(.+)")
				if not result.details and result.name then
					result.name = title:match("work%s*:%s*(.+)")
				end

			-- Handle learning:topic:details format
			elseif string.find(title_lower, "learning%s*:") then
				result.type = "learning"
				result.name, result.details = title:match("learning%s*:%s*([^:]+)%s*:%s*(.+)")
				if not result.details and result.name then
					result.name = title:match("learning%s*:%s*(.+)")
				end

			-- Handle meeting:context:details format
			elseif string.find(title_lower, "meeting%s*:") then
				result.type = "meeting"
				result.name, result.details = title:match("meeting%s*:%s*([^:]+)%s*:%s*(.+)")
				if not result.details and result.name then
					result.name = title:match("meeting%s*:%s*(.+)")
				end

			-- Handle special meeting cases (work meetings)
			elseif string.find(title_lower, "meeting") then
				result.type = "meeting"
				-- Check for work-related meeting types
				local work_meetings = { "standup", "sprint", "retro", "planning", "demo", "review" }

				for _, meeting_type in ipairs(work_meetings) do
					if string.find(title_lower, meeting_type) then
						result.name = meeting_type
						result.work_related = true
						break
					end
				end

			-- Handle person:name:details format
			elseif string.find(title_lower, "person%s*:") then
				result.type = "person"
				result.name, result.details = title:match("person%s*:%s*([^:]+)%s*:%s*(.+)")
				if not result.details and result.name then
					result.name = title:match("person%s*:%s*(.+)")
				end

			-- Handle contact:name:details format
			elseif string.find(title_lower, "contact%s*:") then
				result.type = "person"
				result.name, result.details = title:match("contact%s*:%s*([^:]+)%s*:%s*(.+)")
				if not result.details and result.name then
					result.name = title:match("contact%s*:%s*(.+)")
				end

			-- Handle daily/journal notes
			elseif string.find(title_lower, "daily") or string.find(title_lower, "journal") then
				result.type = "daily"

			-- Default case for other notes
			else
				result.type = "general"
				result.details = title
			end

			return result
		end

		-- Function to sanitize strings for filenames/tags
		local function sanitize_string(str)
			if not str then
				return ""
			end
			return str:lower():gsub(" ", "-"):gsub("[^%w%-_]", "")
		end

		-- Define hub note IDs
		local dashboard_id = "dashboard"
		local work_hub_id = "work-hub"
		local project_hub_id = "project-hub"
		local learning_hub_id = "learning-hub"

		-- Set the note_id_func
		opts.note_id_func = function(title)
			-- Parse the title
			local parsed = parse_structured_title(title)
			local filename = ""

			-- Build filename based on parsed components
			if parsed.type == "meeting" and parsed.work_related then
				filename = "work-" .. parsed.name .. "-meeting"
			elseif parsed.type ~= "general" and parsed.type ~= "daily" then
				-- For structured notes (project, learning, work, person)
				if parsed.name and parsed.details then
					filename = parsed.type
						.. "-"
						.. sanitize_string(parsed.name)
						.. "-"
						.. sanitize_string(parsed.details)
				elseif parsed.name then
					filename = parsed.type .. "-" .. sanitize_string(parsed.name)
				else
					filename = parsed.type
				end
			elseif parsed.type == "daily" then
				filename = "daily"
			else
				-- For general notes
				filename = sanitize_string(parsed.details or "note")
			end

			-- Create timestamp
			local timestamp = os.date("%d-%m-%Y-%a")

			-- Combine filename with timestamp
			return filename .. "--" .. timestamp
		end

		-- Set the note_frontmatter_func
		opts.note_frontmatter_func = function(note)
			-- Get current date for modifications
			local current_date = os.date("%d-%m-%Y")

			-- Check if note exists (has metadata)
			local note_exists = (note.metadata ~= nil)

			-- For existing notes, just update the modified date and preserve everything else
			if note_exists then
				-- Create a deep copy of the existing metadata
				local frontmatter = {}
				for k, v in pairs(note.metadata) do
					frontmatter[k] = v
				end

				-- Only update the modified date
				frontmatter.modified = current_date
				frontmatter.id = note.id -- needs special handling
				frontmatter.tags = note.tags -- needs special handling
				return frontmatter
			end

			-- For new notes, create appropriate frontmatter

			-- Special case for dashboard
			if note.id == dashboard_id then
				return {
					id = note.id,
					title = "Dashboard",
					created = current_date,
					modified = current_date,
					is_dashboard = true,
				}
			-- Special case for hub notes
			elseif note.id == work_hub_id or note.id == project_hub_id or note.id == learning_hub_id then
				local hub_type = note.id:match("^([^-]+)")
				return {
					id = note.id,
					title = hub_type:gsub("^%l", string.upper) .. " Hub",
					created = current_date,
					modified = current_date,
					is_hub = true,
					hub_type = hub_type,
					up = "[[" .. dashboard_id .. "]]",
				}
			end

			-- Parse the title for regular new notes
			local parsed = parse_structured_title(note.title)

			-- Determine frontmatter title
			local frontmatter_title = parsed.details or parsed.original or "Untitled Note"

			-- Define all tags first to avoid table.insert issues
			local tags = {}
			if parsed.type and parsed.type ~= "general" then
				tags[#tags + 1] = parsed.type
			end
			if parsed.name then
				tags[#tags + 1] = sanitize_string(parsed.name)
			end
			if parsed.type == "meeting" and parsed.work_related and parsed.name then
				tags[#tags + 1] = parsed.name
			end

			-- Initialize topics if needed
			local topics = {}
			if parsed.type == "learning" and parsed.name then
				topics[#topics + 1] = sanitize_string(parsed.name)
			end

			-- Determine up link based on note type
			local up_link = "" -- Default
			if parsed.type == "work" or (parsed.type == "meeting" and parsed.work_related) then
				up_link = "[[" .. work_hub_id .. "]]"
			elseif parsed.type == "project" then
				up_link = "[[" .. project_hub_id .. "]]"
			elseif parsed.type == "learning" then
				up_link = "[[" .. learning_hub_id .. "]]"
			end

			-- Base frontmatter for all regular new notes
			local frontmatter = {
				id = note.id,
				title = frontmatter_title,
				created = current_date,
				modified = current_date,
				tags = tags,
				up = up_link,
				prev = "",
				next = "",
			}

			-- Type-specific frontmatter for new notes
			if parsed.type == "meeting" then
				frontmatter.type = "meeting"
				frontmatter.attendees = {} -- Empty array
				frontmatter.meeting_date = current_date

				-- Special handling for work meetings
				if parsed.work_related then
					frontmatter.meeting_type = parsed.name
				end
			elseif parsed.type == "project" then
				frontmatter.type = "project"

				-- Add GitHub field for your P4nda projects
				if parsed.name and string.find(parsed.name:lower(), "p4nda") then
					frontmatter.github = "https://github.com/P4ndaF4ce/" .. sanitize_string(parsed.name)
				end
			elseif parsed.type == "learning" then
				frontmatter.type = "learning"
				frontmatter.topics = topics
			elseif parsed.type == "work" then
				frontmatter.type = "work"
				if parsed.name then
					frontmatter.work_topic = parsed.name
				end
				if parsed.details then
					frontmatter.work_details = parsed.details
				end
			elseif parsed.type == "person" then
				frontmatter.type = "person"
				if parsed.name then
					frontmatter.person_name = parsed.name
				end
			end

			return frontmatter
		end

		-- Initialize Obsidian with updated opts
		require("obsidian").setup(opts)

		-- Basic note operations
		vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "New note" })
		-- Search and note management
		vim.keymap.set("n", "<leader>of", "<cmd>ObsidianSearch<CR>", { desc = "Find notes" })
		vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Show backlinks" })
		vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>", { desc = "Insert template" })
		-- Quick meeting notes
		vim.keymap.set(
			"n",
			"<leader>oms",
			"<cmd>ObsidianNew Standup Meeting<CR>",
			{ desc = "Create standup meeting note" }
		)
		vim.keymap.set("n", "<leader>omr", "<cmd>ObsidianNew Retro Meeting<CR>", { desc = "Create retro meeting note" })
		vim.keymap.set(
			"n",
			"<leader>omp",
			"<cmd>ObsidianNew Planning Meeting<CR>",
			{ desc = "Create planning meeting note" }
		)
		vim.keymap.set("n", "<leader>omd", "<cmd>ObsidianNew Demo Meeting<CR>", { desc = "Create demo meeting note" })
		vim.keymap.set(
			"n",
			"<leader>omg",
			"<cmd>ObsidianNew General Meeting<CR>",
			{ desc = "Create general meeting note" }
		)
		-- Quick hub access
		vim.keymap.set("n", "<leader>ohd", "<cmd>ObsidianOpen dashboard<CR>", { desc = "Open dashboard" })
		vim.keymap.set("n", "<leader>ohw", "<cmd>ObsidianOpen work-hub<CR>", { desc = "Open work hub" })
		vim.keymap.set("n", "<leader>ohp", "<cmd>ObsidianOpen project-hub<CR>", { desc = "Open project hub" })
		vim.keymap.set("n", "<leader>ohl", "<cmd>ObsidianOpen learning-hub<CR>", { desc = "Open learning hub" })
		-- Quick capture
		vim.keymap.set("n", "<leader>oc", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Quick switch" })
		-- Follow link under cursor
		vim.keymap.set("n", "<leader>og", "<cmd>ObsidianFollowLink<CR>", { desc = "Follow link" })
		-- Close all markdown files - Only save markdown files
		vim.keymap.set("n", "<leader>oq", function()
			-- Save all modified markdown buffers
			vim.cmd("bufdo if &filetype == 'markdown' && &modified | write | endif")
			-- Close all markdown buffers
			vim.cmd("bufdo if &filetype == 'markdown' | bd! | endif")
		end, { desc = "Save and close all markdown files" })
	end,
}
