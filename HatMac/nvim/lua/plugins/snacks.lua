-- Cross-platform utility plugin
return {
	-- bigfile: must load early to detect large files before they fully open
	{
		"folke/snacks.nvim",
		priority = 1000,
		opts = {
			bigfile = { enabled = true },
		},
	},

	-- Lazy components: notifier, quickfile, scroll, statuscolumn, words, terminal
	{
		"folke/snacks.nvim",
		event = "VeryLazy",
		opts = {
			notifier = {
				enabled = true,
				style = "compact",
				top_down = true, -- new notifications appear at top
			},
			quickfile = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
		keys = {
			{ "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
			{ "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal" },
			{ "<c-_>", function() Snacks.terminal() end, desc = "which_key_ignore" },
			{ "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
			{ "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
		},
	},
}
