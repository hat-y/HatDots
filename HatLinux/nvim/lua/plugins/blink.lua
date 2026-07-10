-- Blink.cmp configuration - MUST be compatible with LazyVim's blink extra
-- LazyVim's blink extra (from lazyvim.json) handles the base config,
-- we only override what we need here.
return {
	{
		"saghen/blink.cmp",
		dependencies = {
			"saghen/blink.lib",
		},
		build = "cargo build --release",

		opts = {
			-- Use super-tab preset: Tab accepts/cycles, Shift-Tab goes back
			keymap = {
				preset = "super-tab",
			},

			completion = {
				documentation = {
					auto_show = false,
				},
				menu = {
					auto_show = true,
				},
				ghost_text = {
					enabled = false,
				},
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					lsp = {
						name = "LSP",
						module = "blink.cmp.sources.lsp",
					},
				},
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

			snippets = {
				preset = "luasnip",
			},
		},

		config = function(_, opts)
			-- Clean custom fields that LazyVim injects for compat source processing
			-- These are consumed by LazyVim's own config fn; since we override config,
			-- we must strip them before blink.cmp.setup validation
			opts.sources.compat = nil

			require("blink.cmp").setup(opts)

			-- Connect autopairs if available
			local ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.blink")
			if ok then
				require("blink.cmp").accept:connect(function()
					cmp_autopairs.on_confirm_done()
				end)
			end
		end,
	},
}