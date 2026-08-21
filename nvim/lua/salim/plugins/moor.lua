return {
	-- "54L1M/moor.nvim",
	dir = vim.fn.expand("~/Documents/pf4/moor.nvim"),
	event = "VeryLazy", -- setup() applies moor's default <leader>n keymaps
	-- Full config below — everything is at its default except notes_dir.
	opts = {
		-- ZenNotes vault inbox: notes/todos sync to the phone via iCloud.
		-- Everything moor writes lands under inbox/, where ZenNotes can see it.
		notes_dir = "~/Library/Mobile Documents/iCloud~md~zennotes/Documents/ZenNotes/BoxBox/inbox",
		-- Directory names skipped by every scan.
		ignore = { ".git", ".obsidian", "trash", "archive" },

		capture = {
			-- Destination for note captures, relative to notes_dir. os.date()
			-- tokens expand: "Daily Notes/%Y-%m-%d.md" turns captures into daily notes.
			note_file = "Captures.md",
			-- Heading above each capture, as an os.date() format. false = raw append.
			timestamp = "## %Y-%m-%d %H:%M",
			window = { width = 0.5, height = 0.3, border = "rounded", title = " moor " },
			-- Buffer-local maps inside the capture float (set one to false to disable).
			maps = { promote = "<C-p>", abort = "<C-c>" },
		},

		todo = {
			dir = "todo", -- todos live in <notes_dir>/todo/<project>.md
			toggle_states = { " ", "x" }, -- cycle order; add "-" for a cancelled state
		},

		dashboard = {
			window = { width = 0.7, height = 0.7, border = "rounded", title = " open todos " },
			-- View-only icons; files on disk keep plain "- [ ]" markdown.
			-- icons = false shows the raw brackets.
			icons = { open = "○", done = "✓" },
			maps = { toggle = "t", jump = "<CR>", jump_context = "gd", sort = "s", refresh = "r", close = "q" },
		},

		links = {
			new_note_dir = "", -- where notes created from [[missing links]] land, rel. to notes_dir
		},

		-- Global keymaps, applied by setup(). keymaps = false defines none;
		-- one entry = false skips just it; a different lhs rebinds it.
		keymaps = {
			capture_note = "<leader>nn",
			capture_todo = "<leader>nt",
			capture_todo_context = "<leader>nT",
			add_todo = "<leader>na", -- prompt, moored to the cursor position
			add_todo_plain = "<leader>nA", -- prompt, no file:line reference
			dashboard = "<leader>nd",
			toggle = "<leader>nx",
			follow_link = "<leader>nf",
			backlinks = "<leader>nb",
			open_todo = "<leader>no",
		},
	},
}
