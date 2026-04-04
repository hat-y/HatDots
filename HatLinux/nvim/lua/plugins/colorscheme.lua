return {
	{ "folke/tokyonight.nvim", enabled = false },

	{
		"rebelot/kanagawa.nvim",
		lazy = false, -- immediate load
		priority = 1000, -- ensure theme loads first
		opts = {
			compile = false, -- no disk compilation (you can enable later)
			transparent = true, -- no background; lets terminal background show
			dimInactive = false, -- don't dim inactive windows
			terminalColors = true,
			theme = "dragon", -- styles: "wave", "dragon", "lotus" (light)
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
				-- Paleta y helpers de Kanagawa
				local palette = colors.palette
				local theme = colors.theme
				return {
					Normal = { bg = "none" },
					NormalNC = { bg = "none" },
					NormalFloat = { bg = "none" },
					SignColumn = { bg = "none" },
					LineNr = { bg = "none" },
					FoldColumn = { bg = "none" },

					-- Floats y bordes
					FloatBorder = { bg = "none", fg = theme.ui.float.fg_border },
					Pmenu = { bg = "none" },
					PmenuSel = { bg = palette.waveBlue1 },

					-- CursorLine: you can set to "none" if you want it ultra flat
					CursorLine = { bg = "none" },

					-- Visual (selection)
					Visual = { bg = palette.waveBlue1 },

					-- Telescope (if you want to keep it transparent)
					TelescopeNormal = { bg = "none" },
					TelescopeBorder = { bg = "none", fg = theme.ui.float.fg_border },
				}
			end,
		},
		config = function(_, opts)
			require("kanagawa").setup(opts)
			vim.cmd.colorscheme("kanagawa")
		end,
	},

	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "kanagawa",
		},
	},
}
