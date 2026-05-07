-- Noice: cmdline + LSP docs only, snacks.notifier handles notifications
return {
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			-- Use vim.notify (snacks.notifier) for all messages
			messages = {
				enabled = true,
				view = "notify",
				view_error = "notify",
				view_warn = "notify",
				view_history = "messages",
				view_search = false,
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
			routes = {
				-- Skip noisy "written" messages on save
				{
					filter = {
						event = "msg_show",
						any = {
							{ find = "written" },
							{ find = "%d+L, %d+B" },
							{ find = "; after #%d+" },
							{ find = "; before #%d+" },
							{ find = "lines changed" },
							{ find = "lines yanked" },
							{ find = "lines to change" },
							{ find = "fewer lines" },
							{ find = "more lines" },
							{ find = "%d+ more lines" },
							{ find = "%d+ fewer lines" },
							{ find = "Already at newest change" },
						},
					},
					opts = { skip = true },
				},
				-- Skip search count messages
				{
					filter = { event = "msg_show", kind = "search_count" },
					opts = { skip = true },
				},
				-- Skip LSP progress noise
				{
					filter = { event = "lsp", kind = "progress" },
					opts = { skip = true },
				},
			},
		},
		keys = {
			{ "<leader>sn", "", desc = "+noice" },
			{ "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
			{ "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
			{ "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
			{ "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
		},
	},
}
