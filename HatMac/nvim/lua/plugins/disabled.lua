-- This file contains the configuration for disabling specific Neovim plugins.

return {
	{
		-- Plugin: bufferline.nvim
		-- URL: https://github.com/akinsho/bufferline.nvim
		-- Description: A snazzy buffer line (with tabpage integration) for Neovim.
		"akinsho/bufferline.nvim",
		enabled = false, -- Disable this plugin
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		enabled = false,
	},
	{
		"sudo-tee/opencode.nvim",
		enabled = false, -- Requires OPENAI_API_KEY which is not configured
	},
	{
		"olimorris/codecompanion.nvim",
		enabled = false,
	},
	{
		"tris203/precognition.nvim",
		enabled = false,
	},
	{
		"marcinjahn/gemini-cli.nvim",
		enabled = false,
	},
	}
