return {
	"stevearc/oil.nvim",
	event = "VeryLazy",
	cmd = "Oil",
	keys = {
		{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
	},
	opts = {
		default_file_explorer = true,
		restore_win_options = true,
		skip_confirm_for_simple_edits = true,
		prompt_save_on_select_new_entry = false,

		view_options = {
			show_hidden = true,
			is_hidden_file = function(name)
				return vim.startswith(name, ".")
			end,
			is_always_hidden = function(name)
				return name == ".."
			end,
			natural_order = true,
		},
	},
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
}
