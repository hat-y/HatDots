return {
	{ "folke/tokyonight.nvim", enabled = false },

	{
		"rebelot/kanagawa.nvim",
		lazy = false, -- carga inmediata
		priority = 1000, -- asegúrate de que el tema carga primero
		opts = {
			compile = false, -- sin compilación a disco (puedes activar luego)
			transparent = true, -- sin fondo; deja ver el del terminal
			dimInactive = false, -- no oscurecer ventanas inactivas
			terminalColors = true,
			theme = "dragon", -- estilos: "wave", "dragon", "lotus" (light)
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

					-- CursorLine: puedes dejar “none” si lo quieres ultra plano
					CursorLine = { bg = "none" },

					-- Visual (selección)
					Visual = { bg = palette.waveBlue1 },

					-- Telescope (si quieres mantenerlo transparente)
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
