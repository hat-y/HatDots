return {
	-- lua/plugins/lsp.lua
	{
		"stevearc/conform.nvim",
		opts = function(_, opts)
			opts = opts or {}

			opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
				lua = { "stylua" },
				javascript = { "prettierd", "prettier" },
				typescript = { "prettierd", "prettier" },
				tsx = { "prettierd", "prettier" },
				json = { "prettierd", "prettier" },
				css = { "prettierd", "prettier" },
				markdown = { "prettierd", "prettier" },
				python = { "ruff_format" }, -- only ruff
				sh = { "shfmt" },
			})

			opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
				prettier = { prefer_local = "node_modules/.bin" },
				shfmt = { extra_args = { "-i", "2", "-ci" } },
			})
			return opts
		end,

		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format()
				end,
				desc = "Format buffer",
			},
		},
	},
}
