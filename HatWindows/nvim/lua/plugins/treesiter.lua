return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"query",
				"typescript",
				"tsx",
				"javascript",
				"python",
				"json",
				"yaml",
				"toml",
				"bash",
				"regex",
				"markdown",
				"markdown_inline",
			},
			highlight = { enable = true },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "gnn",
					node_incremental = "grn",
					node_decremental = "grm",
					scope_incremental = "grc",
				},
			},
			-- auto_install = true,
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)

			local utils = require("config.utils")
			local ts_install = require("nvim-treesitter.install")
			if utils.is_win then
				ts_install.compilers = { "clang" }
			else
				ts_install.compilers = { "clang", "gcc" }
			end
		end,
	},
}
