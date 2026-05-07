return {
	{
		"saghen/blink.cmp",
		dependencies = {
			"saghen/blink.lib",
		},
		build = function()
			require("blink.cmp").build():wait(60000)
		end,

		opts = {
			keymap = { preset = "default" },

			completion = {
				documentation = { auto_show = false },
			},

			cmdline = {
				enabled = true,
				sources = function()
					local type = vim.fn.getcmdtype()
					if type == "/" or type == "?" then
						return { "buffer" }
					end
					return { "cmdline", "path" }
				end,
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					cmdline = {
						name = "cmdline",
						module = "blink.cmp.sources.cmdline",
					},
				},
			},

			fuzzy = {
				implementation = "rust",
			},

			snippets = {
				preset = "luasnip",
			},
		},

		config = function()
			local ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.blink")
			if ok then
				require("blink.cmp").accept:connect(function()
					cmp_autopairs.on_confirm_done()
				end)
			end
		end,
	},
}
