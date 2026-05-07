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

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
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
