return {
	-- Disable default tokyonight
	{ "folke/tokyonight.nvim", enabled = false },

	-- Active: oxocarbon
	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.opt.background = "dark"
			vim.cmd.colorscheme("oxocarbon")

			-- Transparency
			local hl = vim.api.nvim_set_hl
			hl(0, "Normal", { bg = "none" })
			hl(0, "NormalFloat", { bg = "none" })
			hl(0, "NormalNC", { bg = "none" })
			hl(0, "SignColumn", { bg = "none" })
			hl(0, "LineNr", { bg = "none" })
			hl(0, "FoldColumn", { bg = "none" })
			hl(0, "CursorLineNr", { bg = "none" })

			-- Floats and popups
			hl(0, "FloatBorder", { bg = "none" })
			hl(0, "Pmenu", { bg = "none" })
			hl(0, "PmenuSbar", { bg = "none" })

			-- Sidebars
			hl(0, "NvimTreeNormal", { bg = "none" })
			hl(0, "NvimTreeEndOfBuffer", { bg = "none" })

			-- Telescope
			hl(0, "TelescopeNormal", { bg = "none" })
			hl(0, "TelescopeBorder", { bg = "none" })
			hl(0, "TelescopePromptNormal", { bg = "none" })
			hl(0, "TelescopeResultsNormal", { bg = "none" })
			hl(0, "TelescopePreviewNormal", { bg = "none" })

			-- Notifications
			hl(0, "NotifyBackground", { bg = "none" })

			-- Which-key
			hl(0, "WhichKeyNormal", { bg = "none" })
		end,
	},

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
