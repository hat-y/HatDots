return {
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- opcional, para iconos
		lazy = false, -- oil recomienda no lazy-load complicado
		opts = {
			default_file_explorer = false, -- mantenemos Neo-tree si lo usas
			view_options = { show_hidden = true },
			columns = { "icon", "size", "mtime" },

			use_default_keymaps = true,

			keymaps = {
				["q"] = { "actions.close", mode = "n" },
				["<esc>"] = { "actions.close", mode = "n" },
				["gr"] = { "actions.refresh", mode = "n" },
			},

			float = { padding = 2, max_width = 90, max_height = 30, border = "rounded" },
		},

		keys = {
			{
				"-",
				function()
					require("oil").open_float()
				end,
				desc = "Oil (cwd float)",
			},
			{ "<leader>-", "<cmd>Oil<cr>", desc = "Oil (cwd en buffer)" },
		},
	},
}
