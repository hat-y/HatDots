return {
	"stevearc/oil.nvim",
	event = "VeryLazy",
	cmd = "Oil",
	keys = {
		{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
		{ "<leader>E", "<cmd>Oil --float<cr>", desc = "Open Oil (floating)" },
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
				return name == ".." or name == ".git"
			end,
			natural_order = true,
			case_insensitive = false,
			sort = {
				{ "type", "asc" },
				{ "name", "asc" },
			},
		},

		-- Floating window used by <leader>E.
		float = {
			padding = 2,
			max_width = 100,
			max_height = 30,
			border = "rounded",
			win_options = { winblend = 0 },
			preview_split = "auto",
			override = function(conf)
				return conf
			end,
		},
		preview = {
			max_width = 0.9,
			min_width = { 40, 0.4 },
			max_height = 0.9,
			min_height = { 5, 0.1 },
			border = "rounded",
			win_options = { winblend = 0 },
			update_on_cursor_moved = true,
		},
		progress = {
			max_width = 0.9,
			min_width = { 40, 0.4 },
			max_height = { 10, 0.9 },
			min_height = { 5, 0.1 },
			border = "rounded",
			minimized_border = "none",
			win_options = { winblend = 0 },
		},
	},
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function(_, opts)
		require("oil").setup(opts)

		-- Auto-save when leaving an oil buffer with pending changes.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "oil",
			callback = function()
				vim.api.nvim_create_autocmd("BufLeave", {
					buffer = 0,
					callback = function()
						if vim.bo.modified then
							vim.cmd("silent! write")
						end
					end,
				})
			end,
		})
	end,
}
