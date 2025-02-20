return {
	"vim-ctrlspace/vim-ctrlspace",
	lazy = false, -- Load immediately
	init = function()
		-- Remap <Leader>fe to open CtrlSpace
		vim.g.CtrlSpaceDefaultMappingKey = "<Nop>" -- Disable default mappings
		vim.keymap.set("n", "<Leader>fe", ":CtrlSpace<CR>", { silent = true, noremap = true, desc = "Open CtrlSpace" })
	end,
}
