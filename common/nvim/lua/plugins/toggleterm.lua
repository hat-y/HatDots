-- toggleterm.nvim — previously declared only as a dependency of the
-- now-removed custom Salesforce module (lua/plugins/salesforce.lua), but
-- lua/config/keymaps.lua's <leader>tt/<leader>tn call
-- require("toggleterm.terminal").Terminal:new(...) directly (not through a
-- lazy.nvim `keys` trigger), so the plugin must already be loaded by the
-- time either mapping is pressed. Loading on BufReadPre/BufNewFile (fires
-- for the very first buffer at startup) rather than `keys` avoids a race
-- where keymaps.lua's own vim.keymap.set would otherwise overwrite a
-- `keys`-based lazy-load trigger for the same <leader>tt/<leader>tn lhs.
return {
	{
		"akinsho/toggleterm.nvim",
		cmd = { "ToggleTerm" },
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			size = 20,
			open_mapping = nil, -- lua/config/keymaps.lua already binds <leader>tt/<leader>tn
			shade_filetypes = {},
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)
		end,
	},
}
