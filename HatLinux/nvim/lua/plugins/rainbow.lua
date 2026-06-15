-- Rainbow delimiters with Aether theme colors
return {
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "VeryLazy",
		opts = {
			query = {
				[""] = "rainbow-delimiters",
				lua = "rainbow-blocks",
				latex = "rainbow-blocks",
				html = "rainbow-blocks",
				typescript = "rainbow-delimiters",
				javascript = "rainbow-delimiters",
				java = "rainbow-delimiters",
			},
		},
		config = function(_, opts)
			require("rainbow-delimiters.setup")(opts)

			-- Aether theme palette
			local aether_colors = {
				"#89b4fa", -- blue
				"#f9e2af", -- yellow
				"#a6e3a1", -- green
				"#94e2d5", -- cyan
				"#cba6f7", -- purple
				"#f59cb5", -- orange/pink
				"#f38ba8", -- red
				"#935e6d", -- brown
			}

			local hl = vim.api.nvim_set_hl
			local rainbow_groups = {
				"RainbowDelimiterRed",
				"RainbowDelimiterYellow",
				"RainbowDelimiterBlue",
				"RainbowDelimiterOrange",
				"RainbowDelimiterGreen",
				"RainbowDelimiterViolet",
				"RainbowDelimiterCyan",
			}

			for i, group in ipairs(rainbow_groups) do
				pcall(hl, 0, group, { fg = aether_colors[i], bold = true })
			end
		end,
	},
}