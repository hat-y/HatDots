return {
	-- Disable default tokyonight
	{ "folke/tokyonight.nvim", enabled = false },

	-- Active: oxocarbon
	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = false,
		priority = 1000,
	},

	-- Available: kanagawa (switch with :colorscheme kanagawa)
	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		opts = {
			compile = false,
			transparent = true,
			dimInactive = false,
			terminalColors = true,
			theme = "dragon",
			background = {
				dark = "dragon",
				light = "lotus",
			},
			colors = {
				theme = {
					all = {
						ui = {
							bg_gutter = "none",
						},
					},
				},
			},
			overrides = function(colors)
				local palette = colors.palette
				local theme = colors.theme
				return {
					Normal = { bg = "none" },
					NormalNC = { bg = "none" },
					NormalFloat = { bg = "none" },
					SignColumn = { bg = "none" },
					LineNr = { bg = "none" },
					FoldColumn = { bg = "none" },
					FloatBorder = { bg = "none", fg = theme.ui.float.fg_border },
					Pmenu = { bg = "none" },
					PmenuSel = { bg = palette.waveBlue1 },
					CursorLine = { bg = "none" },
					Visual = { bg = palette.waveBlue1 },
					TelescopeNormal = { bg = "none" },
					TelescopeBorder = { bg = "none", fg = theme.ui.float.fg_border },
				}
			end,
		},
	},

	-- Set default colorscheme
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "oxocarbon",
		},
	},
}
