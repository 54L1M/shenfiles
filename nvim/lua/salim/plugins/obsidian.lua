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
				path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/TheGreatLibrary",
			},
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
		-- open_notes_in = "vsplit",
		open_app_foreground = true,
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
		-- Enhanced utility function for parsing structured titles
		local function parse_structured_title(title)
			if not title then
				return {
					type = "inbox",
					title = nil,
					details = nil,
					original = title,
				}
			end

			local result = {
				type = nil,
				title = nil,
				details = nil,
				original = title,
			}

			-- Use a more generic parsing approach
			local parts = {}
			for part in title:gmatch("[^:]+") do
				table.insert(parts, vim.trim(part))
			end

			if #parts >= 3 then
				-- Ensure we have at least type:title:details
				result.type = parts[1]:lower()
				result.title = parts[2]
				result.details = table.concat(parts, " ", 3)
			elseif #parts == 2 then
				-- type:title format
				result.type = parts[1]:lower()
				result.title = parts[2]
			else
				-- Fallback to general note
				result.type = "note"
				result.title = title
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

		-- Define hub note IDs (keeping your existing hub notes)
		local dashboard_id = "dashboard"
		local work_hub_id = "work-hub"
		local project_hub_id = "project-hub"
		local learning_hub_id = "learning-hub"

		-- Updated note_id_func
		opts.note_id_func = function(title)
			-- Parse the title
			local parsed = parse_structured_title(title)

			-- Build filename with type and sanitized title/details
			local filename = parsed.type
			if parsed.title then
				filename = filename .. "-" .. sanitize_string(parsed.title)
			end
			if parsed.details then
				filename = filename .. "-" .. sanitize_string(parsed.details)
			end

			-- Create timestamp
			local timestamp = os.date("%d-%m-%Y-%a")

			-- Combine filename with timestamp
			return filename .. "--" .. timestamp
		end

		-- Updated note_frontmatter_func
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

			-- Special case for hub and dashboard notes
			if note.id == dashboard_id then
				return {
					id = note.id,
					title = "Dashboard",
					created = current_date,
					modified = current_date,
					is_dashboard = true,
				}
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

			-- Determine frontmatter title and details
			local frontmatter_title = parsed.title or parsed.original or "Untitled Note"
			local frontmatter_details = parsed.details or ""

			-- Define tags
			local tags = {}
			if parsed.type and parsed.type ~= "note" then
				tags[#tags + 1] = parsed.type
			end
			if parsed.title then
				tags[#tags + 1] = sanitize_string(parsed.title)
			end

			-- Determine up link based on type
			local up_link = ""
			local type_to_hub = {
				work = work_hub_id,
				project = project_hub_id,
				learning = learning_hub_id,
				contact = work_hub_id, -- Added contact type
			}
			if type_to_hub[parsed.type] then
				up_link = "[[" .. type_to_hub[parsed.type] .. "]]"
			end

			-- Base frontmatter for all regular new notes
			local frontmatter = {
				id = note.id,
				type = parsed.type,
				title = frontmatter_title .. (frontmatter_details ~= "" and ": " .. frontmatter_details or ""),
				created = current_date,
				modified = current_date,
				tags = tags,
				up = up_link,
				prev = "",
				next = "",
			}

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
