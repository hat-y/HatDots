-- Windows-only distraction-free writing mode
return {
	{
		"folke/zen-mode.nvim",
		enabled = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1,
		dependencies = {
			"folke/twilight.nvim", -- Optional: dim inactive code
		},

		keys = {
			-- Toggle zen-mode with <leader>zz (avoids conflict with <leader>sz spell check)
			{
				"<leader>zz",
				function()
					require("zen-mode").toggle()
				end,
				desc = "Toggle zen-mode (distraction-free writing)",
			},
		},

		opts = {
			-- What to hide: statusline, tabline, signcolumn, foldcolumn, number column
			-- When enabled, many UI elements will be hidden
			---@type table
			enabled = true,

			-- Window styling
			---@type table
			window = {
				-- Width of zen-mode window
				---@type number
				width = 120,

				-- Padding around the content
				---@type table
				padding = 2,

				-- Whether to center the window
				---@type boolean
				centered = true,
			},

			-- Configuration for transparency (dark semi-transparent background)
			---@type table
			opacity = 0.95,
			---@type string | nil
			backdrop = "#000000", -- Optional: solid black backdrop

			-- Plugins to integrate with
			---@type table
			plugins = {
				-- Enable integration with gitsigns (will dim signs)
				gitsigns = true,

				-- Enable integration with tmux (if using tmux)
				tmux = false,

				-- Disable cursorline (zen-mode hides it by default)
				cursorline = false,
			},

			-- Execute this before entering zen-mode
			---@type function | nil
			on_enter = nil,

			-- Execute this before leaving zen-mode
			---@type function | nil
			on_exit = nil,
		},

		-- Optional: Configure twilight.nvim for dimming inactive code
		config = function(_, opts)
			local zen = require("zen-mode")
			local twilight = require("twilight")

			-- Configure twilight to work with zen-mode
			twilight.setup({
				dimming = {
					alpha = 0.25, -- Dim inactive code to 25% opacity
					termguicolors = true,
				},
				-- Optionally, use a darker color for the dimming effect
				color = { outer = "#000000" },
				termcolors = { outer = "black" },
			})

			-- Customize zen-mode options if needed
			-- vim.tbl_deep_extend("force", zen.default_config, opts)
		end,
	},
}
