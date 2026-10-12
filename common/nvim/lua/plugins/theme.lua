return {
	{
		"bjarneo/aether.nvim",
		branch = "v3",
		name = "aether",
		priority = 1000,
		opts = {
			colors = {
				bg         = "#1e1e2e",
				dark_bg    = "#171723",
				darker_bg  = "#0f0f17",
				lighter_bg = "#353543",

				fg         = "#cdd6f4",
				dark_fg    = "#9aa1b7",
				light_fg   = "#d5dcf6",
				bright_fg  = "#dae0f7",
				muted      = "#45475a",

				red        = "#f38ba8",
				yellow     = "#f9e2af",
				orange     = "#f59cb5",
				green      = "#a6e3a1",
				cyan       = "#94e2d5",
				blue       = "#89b4fa",
				purple     = "#cba6f7",
				brown      = "#935e6d",

				bright_red    = "#f38ba8",
				bright_yellow = "#f9e2af",
				bright_green  = "#a6e3a1",
				bright_cyan   = "#94e2d5",
				bright_blue   = "#89b4fa",
				bright_purple = "#cba6f7",

				accent               = "#89b4fa",
				cursor               = "#cdd6f4",
				foreground           = "#cdd6f4",
				background           = "#1e1e2e",
				selection             = "#353543",
				selection_foreground = "#cdd6f4",
				selection_background = "#353543",
			},
		},
		config = function()
			local bg     = "#1e1e2e"
			local fg     = "#cdd6f4"
			local muted  = "#45475a"
			local accent = "#89b4fa"
			local dim    = "#313244"
			local hl = vim.api.nvim_set_hl

			-- Core transparency
			for _, g in ipairs({
				"Normal", "NormalFloat", "NormalNC", "SignColumn",
				"LineNr", "CursorLineNr", "FoldColumn", "EndOfBuffer",
			}) do
				pcall(hl, 0, g, { bg = "none" })
			end

			-- Floats and popups
			for _, g in ipairs({
				"FloatBorder", "Pmenu", "PmenuSbar", "PmenuThumb",
				"FloatTitle", "FloatShadowThrough",
			}) do
				pcall(hl, 0, g, { bg = "none" })
			end

			-- Sidebars and panels
			for _, g in ipairs({
				"NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer",
				"NvimTreeVertSplit", "NvimTreeWinSeparator",
				"NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeEndOfBuffer",
				"NeoTreeVertSplit", "NeoTreeWinSeparator",
				"oil.nvim", "OilNormal",
			}) do
				pcall(hl, 0, g, { bg = "none" })
			end

			-- Telescope
			for _, g in ipairs({
				"TelescopeNormal", "TelescopeBorder", "TelescopePreviewNormal",
				"TelescopePreviewBorder", "TelescopeResultsNormal",
				"TelescopeResultsBorder", "TelescopePromptNormal",
				"TelescopePromptBorder", "TelescopeSelection",
				"TelescopeSelectionCaret",
			}) do
				pcall(hl, 0, g, { bg = "none" })
			end

			-- Notifications
			for _, g in ipairs({
				"NotifyBackground", "NotifyERROR", "NotifyWARN",
				"NotifyINFO", "NotifyDEBUG", "NotifyTRACE",
				"NotifyERRORBody", "NotifyWARNBody", "NotifyINFOBody",
				"NotifyDEBUGBody", "NotifyTRACEBody",
				"NotifyERRORTitle", "NotifyWARNTitle", "NotifyINFOTitle",
				"NotifyDEBUGTitle", "NotifyTRACETitle",
				"NotifyERRORBorder", "NotifyWARNBorder", "NotifyINFOBorder",
				"NotifyDEBUGBorder", "NotifyTRACEBorder",
			}) do
				pcall(hl, 0, g, { bg = "none" })
			end

			-- Which-key
			for _, g in ipairs({
				"WhichKeyNormal", "WhichKeyFloat", "WhichKeyBorder",
				"WhichKeyDesc", "WhichKeyGroup",
			}) do
				pcall(hl, 0, g, { bg = "none" })
			end

			-- ─── Command line & status line ───────────────────────────────
			-- Status line (top bar per window)
			pcall(hl, 0, "StatusLine",     { bg = "none", fg = fg })
			pcall(hl, 0, "StatusLineNC",   { bg = "none", fg = muted })
			pcall(hl, 0, "StatusLineTerm",  { bg = "none", fg = fg })
			pcall(hl, 0, "StatusLineTermNC", { bg = "none", fg = muted })

			-- Command line area (bottom)
			pcall(hl, 0, "CmdLine",     { bg = "none", fg = fg })
			pcall(hl, 0, "CmdLineFill", { bg = "none", fg = fg })
			pcall(hl, 0, "CmdLinePopup", { bg = dim, fg = fg })
			pcall(hl, 0, "CmdLinePopupBorder", { bg = "none", fg = muted })
			pcall(hl, 0, "CmdLinePopupSel", { bg = dim, fg = accent, bold = true })

			-- Message area (below cmdline)
			pcall(hl, 0, "MsgArea",     { bg = "none", fg = fg })
			pcall(hl, 0, "MsgSeparator", { bg = "none", fg = muted })

			-- Echo / messages
			pcall(hl, 0, "MoreMsg",   { fg = accent })
			pcall(hl, 0, "ModeMsg",   { fg = fg, bold = true })
			pcall(hl, 0, "MsgTitle",  { fg = accent, bold = true })
			pcall(hl, 0, "MsgBlank",  { bg = "none", fg = muted })

			-- Wild menu / completion
			pcall(hl, 0, "WildMenu",   { bg = dim, fg = accent })
			pcall(hl, 0, "WildMenuSel", { bg = accent, fg = bg, bold = true })
			pcall(hl, 0, "WildGuide",  { fg = muted })
			pcall(hl, 0, "WildKill",   { fg = muted })

			-- Search cmdline
			pcall(hl, 0, "IncSearch",   { bg = accent, fg = bg })
			pcall(hl, 0, "IncSearchTail", { bg = accent, fg = bg })
			pcall(hl, 0, "Search",      { bg = dim, fg = fg, underline = true })
			pcall(hl, 0, "SearchMatch",  { bg = dim, fg = fg })

			-- Question / confirm
			pcall(hl, 0, "Question", { fg = accent, bold = true })

			-- Quickfix
			pcall(hl, 0, "qfLineNr", { fg = muted })
			pcall(hl, 0, "qfFileName", { fg = fg })
			pcall(hl, 0, "qfDirectory", { fg = accent })
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "aether",
		},
	},
}