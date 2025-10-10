return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		lazy = false,
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
		},
		config = function(_, opts)
			local ok_cfg, configs = pcall(require, "nvim-treesitter.configs")
			if not ok_cfg then
				vim.notify("nvim-treesitter.configs no disponible", vim.log.levels.ERROR)
				return
			end
			configs.setup(opts)

			local ok_inst, ts_install = pcall(require, "nvim-treesitter.install")
			if ok_inst then
				local ok_utils, utils = pcall(require, "config.utils")
				local is_win = ok_utils and utils.is_win or vim.loop.os_uname().version:match("Windows") ~= nil
				ts_install.compilers = is_win and { "clang" } or { "clang", "gcc" }
			end
		end,
	},
}
