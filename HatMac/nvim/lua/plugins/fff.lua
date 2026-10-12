return {
	"dmtrKovalenko/fff.nvim",
	-- Neovim 0.10.0+ required
	version = ">=0.10.0",
	build = function()
		require("fff.download").download_or_build_binary()
	end,
	cmd = { "FFF", "FFFScan", "FFFRefreshGit", "FFFClearCache", "FFFHealth", "FFFDebug", "FFFOpenLog" },
	keys = {
		{
			"<leader>ff",
			function()
				require("fff").find_files()
			end,
			desc = "fff: Find files",
		},
		{
			"<leader>fg",
			function()
				require("fff").live_grep()
			end,
			desc = "fff: Live grep",
		},
		{
			"<leader>fc",
			function()
				require("fff").live_grep({ query = vim.fn.expand("<cword>") })
			end,
			desc = "fff: Grep current word",
		},
		{
			"<leader>fr",
			function()
				require("fff").scan_files()
			end,
			desc = "fff: Rescan files",
		},
	},
	opts = {
		-- Frecency: remember which files you open most
		frecency = {
			enabled = true,
			db_path = vim.fn.stdpath("cache") .. "/fff_nvim",
		},
		-- History: remember successful queries
		history = {
			enabled = true,
			db_path = vim.fn.stdpath("data") .. "/fff_queries",
			min_combo_count = 3,
			combo_boost_score_multiplier = 100,
		},
		-- Layout config
		layout = {
			height = 0.8,
			width = 0.8,
			prompt_position = "bottom",
			preview_position = "right",
			preview_size = 0.5,
			flex = {
				size = 130,
				wrap = "top",
			},
		},
		-- Grep config
		grep = {
			max_file_size = 10 * 1024 * 1024, -- 10MB
			max_matches_per_file = 100,
			smart_case = true,
			time_budget_ms = 150, -- prevents UI freeze
			modes = { "plain", "regex", "fuzzy" },
		},
		-- Git integration
		git = {
			status_text_color = true, -- show git status colors on filename
		},
		-- Debug (enable only if needed)
		-- debug = {
		--   enabled = false,
		--   show_scores = false,
		-- },
	},
}