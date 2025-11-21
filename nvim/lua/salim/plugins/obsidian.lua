return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		-- FIX 1: Disable legacy commands to silence the warning
		legacy_commands = false,

		workspaces = {
			{
				name = "TheGreatLibrary",
				path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/TheGreatLibrary",
			},
		},
		daily_notes = {
			folder = "00-Notes/Daily",
			date_format = "%d-%m-%Y-%a",
			default_tags = { "daily" },
			template = "daily-note-template",
		},
		templates = {
			folder = "02-Templates",
			date_format = "%d-%m-%Y",
			time_format = "%H:%M",
		},
		notes_subdir = "00-Notes",
		new_notes_location = "notes_subdir",
		attachments = {
			folder = "attachments",
		},
		wiki_link_func = "prepend_note_id",
		preferred_link_style = "wiki",

		-- FIX 2: Replaced deprecated 'open_app_foreground' with 'open.func'
		open = {
			func = function(uri)
				vim.ui.open(uri, { cmd = { "open", "-a", "/Applications/Obsidian.app" } })
			end,
		},

		-- FIX 3: Checkboxes are now strictly for UI/Display
		ui = {
			enable = true,
			update_debounce = 200,
		},

		-- FIX 4: Define the order here to resolve the 'checkbox.order' warning
		sort = {
			-- Sort order for tasks (and cycling order)
			checkboxes = {
				[" "] = { char = "☐", hl_group = "ObsidianTodo" },
				["x"] = { char = "☑", hl_group = "ObsidianDone" },
			},
		},

		completion = {
			blink = true,
			min_chars = 2,
		},

		-- Initialize frontmatter table
		frontmatter = {},
	},
	config = function(_, opts)
		-- =========================================
		-- HELPER FUNCTIONS
		-- =========================================
		local function sanitize_string(str)
			if not str then
				return ""
			end
			return str:lower():gsub(" ", "-"):gsub("[^%w%-_]", "")
		end

		local function parse_structured_title(title)
			if not title then
				return { type = "inbox", title = nil, details = nil, original = title }
			end
			local result = { type = nil, title = nil, details = nil, original = title }
			local parts = {}
			for part in title:gmatch("[^:]+") do
				table.insert(parts, vim.trim(part))
			end

			if #parts >= 3 then
				result.type = parts[1]:lower()
				result.title = parts[2]
				result.details = table.concat(parts, " ", 3)
			elseif #parts == 2 then
				result.type = parts[1]:lower()
				result.title = parts[2]
			else
				result.type = "note"
				result.title = title
			end
			return result
		end

		-- =========================================
		-- CONFIGURATION INJECTION
		-- =========================================
		local dashboard_id = "00-dashboard"
		local daily_notes_hub_id = "01-daily-notes-hub"
		local hub_ids = {
			work = "07-work-hub",
			project = "06-project-hub",
			learning = "04-learning-hub",
			contact = "03-contact-hub",
			personal = "05-personal-hub",
		}

		-- 1. Note ID Function
		opts.note_id_func = function(title)
			local parsed = parse_structured_title(title)
			local filename = parsed.type
			if parsed.title then
				filename = filename .. "-" .. sanitize_string(parsed.title)
			end
			if parsed.details then
				filename = filename .. "-" .. sanitize_string(parsed.details)
			end
			local timestamp = os.date("%d-%m-%Y-%a")
			return filename .. "--" .. timestamp
		end

		-- FIX 5: Replaced 'note_frontmatter_func' with 'frontmatter.func'
		opts.frontmatter = opts.frontmatter or {}
		opts.frontmatter.func = function(note)
			local current_date = os.date("%d-%m-%Y")

			-- A) Handling Existing Notes
			if note.metadata ~= nil then
				local frontmatter = {}
				for k, v in pairs(note.metadata) do
					frontmatter[k] = v
				end
				frontmatter.modified = current_date
				frontmatter.id = note.id
				frontmatter.tags = note.tags
				return frontmatter
			end

			-- B) Dashboard
			if note.id == dashboard_id then
				return {
					id = note.id,
					title = "Dashboard",
					created = current_date,
					modified = current_date,
					is_dashboard = true,
				}
			end

			-- C) Hubs
			for type_key, id in pairs(hub_ids) do
				if note.id == id then
					return {
						id = note.id,
						title = type_key:gsub("^%l", string.upper) .. " Hub",
						created = current_date,
						modified = current_date,
						is_hub = true,
						hub_type = type_key,
						up = "[[" .. dashboard_id .. "]]",
					}
				end
			end

			-- D) Daily Notes
			local is_daily_note = false
			local date_pattern = "^%d%d%-%d%d%-%d%d%d%d%-%a%a%a$"
			if note.path and type(note.path) == "string" and note.path:match("^" .. opts.daily_notes.folder) then
				is_daily_note = true
			elseif note.id and type(note.id) == "string" and note.id:match(date_pattern) then
				is_daily_note = true
			end

			if is_daily_note then
				local date_str, day_of_week
				if note.id and note.id:match(date_pattern) then
					date_str, day_of_week = note.id:match("^(%d%d%-%d%d%-%d%d%d%d)%-(%a%a%a)$")
				else
					date_str = current_date
					local day, month, year = date_str:match("^(%d%d)%-(%d%d)%-(%d%d%d%d)$")
					local timestamp = os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
					day_of_week = os.date("%a", timestamp)
				end
				return {
					id = note.id,
					title = "Daily Note: " .. date_str .. " (" .. day_of_week .. ")",
					date = date_str,
					created = current_date,
					modified = current_date,
					tags = opts.daily_notes.default_tags or { "daily" },
					up = "[[" .. daily_notes_hub_id .. "]]",
				}
			end

			-- E) Regular New Notes
			local parsed = parse_structured_title(note.title)
			local tags = {}
			if parsed.type and parsed.type ~= "note" then
				table.insert(tags, parsed.type)
			end
			if parsed.title then
				table.insert(tags, sanitize_string(parsed.title))
			end

			local up_link = ""
			if hub_ids[parsed.type] then
				up_link = "[[" .. hub_ids[parsed.type] .. "]]"
			elseif parsed.type == "daily" then
				up_link = "[[" .. daily_notes_hub_id .. "]]"
			end

			return {
				id = note.id,
				type = parsed.type,
				title = (parsed.title or "")
					.. (parsed.details and #parsed.details > 0 and ": " .. parsed.details or ""),
				created = current_date,
				modified = current_date,
				tags = tags,
				up = up_link,
				prev = "",
				next = "",
			}
		end

		require("obsidian").setup(opts)

		-- =========================================
		-- KEYMAPS (New non-legacy syntax)
		-- =========================================
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { desc = desc })
		end

		-- Note Operations (Commands are now space separated)
		map("n", "<leader>on", "<cmd>Obsidian new<CR>", "New note")
		map("n", "<leader>of", "<cmd>Obsidian search<CR>", "Find notes")
		map("n", "<leader>ob", "<cmd>Obsidian backlinks<CR>", "Show backlinks")
		map("n", "<leader>ot", "<cmd>Obsidian template<CR>", "Insert template")

		-- Hub Navigation
		map("n", "<leader>ohd", "<cmd>Obsidian open 00-dashboard<CR>", "Open dashboard")
		map("n", "<leader>ohw", "<cmd>Obsidian open 07-work-hub<CR>", "Open work hub")
		map("n", "<leader>ohp", "<cmd>Obsidian open 06-project-hub<CR>", "Open project hub")
		map("n", "<leader>ohl", "<cmd>Obsidian open 04-learning-hub<CR>", "Open learning hub")

		-- Tools
		map("n", "<leader>oc", "<cmd>Obsidian quick_switch<CR>", "Quick switch")
		map("n", "<leader>og", "<cmd>Obsidian follow<CR>", "Follow link")

		-- Daily Notes
		map("n", "<leader>od", "<cmd>Obsidian today<CR>", "Open today")
		map("n", "<leader>oy", "<cmd>Obsidian yesterday<CR>", "Open yesterday")
		map("n", "<leader>om", "<cmd>Obsidian tomorrow<CR>", "Open tomorrow")

		-- Maintenance
		map("n", "<leader>oq", function()
			vim.cmd("bufdo if &filetype == 'markdown' && &modified | write | endif")
			vim.cmd("bufdo if &filetype == 'markdown' | bd! | endif")
		end, "Save and close all markdown")
	end,
}
