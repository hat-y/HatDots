-- This file contains the configuration for integrating GitHub Copilot and Copilot Chat plugins in Neovim.

-- Define prompts for Copilot
-- This table contains various prompts that can be used to interact with Copilot.
local prompts = {
	Explain = "Please explain how the following code works.", -- Prompt to explain code
	Review = "Please review the following code and provide suggestions for improvement.", -- Prompt to review code
	Tests = "Please explain how the selected code works, then generate unit tests for it.", -- Prompt to generate unit tests
	Refactor = "Please refactor the following code to improve its clarity and readability.", -- Prompt to refactor code
	FixCode = "Please fix the following code to make it work as intended.", -- Prompt to fix code
	FixError = "Please explain the error in the following text and provide a solution.", -- Prompt to fix errors
	BetterNamings = "Please provide better names for the following variables and functions.", -- Prompt to suggest better names
	Documentation = "Please provide documentation for the following code.", -- Prompt to generate documentation
	JsDocs = "Please provide JsDocs for the following code.", -- Prompt to generate JsDocs
	DocumentationForGithub = "Please provide documentation for the following code ready for GitHub using markdown.", -- Prompt to generate GitHub documentation
	CreateAPost = "Please provide documentation for the following code to post it in social media, like Linkedin, it has be deep, well explained and easy to understand. Also do it in a fun and engaging way.", -- Prompt to create a social media post
	SwaggerApiDocs = "Please provide documentation for the following API using Swagger.", -- Prompt to generate Swagger API docs
	SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.", -- Prompt to generate Swagger JsDocs
	Summarize = "Please summarize the following text.", -- Prompt to summarize text
	Spelling = "Please correct any grammar and spelling errors in the following text.", -- Prompt to correct spelling and grammar
	Wording = "Please improve the grammar and wording of the following text.", -- Prompt to improve wording
	Concise = "Please rewrite the following text to make it more concise.", -- Prompt to make text concise
}

return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		cmd = "CopilotChat",
		opts = {
			prompts = prompts,
			system_prompt = "....",
			model = "claude-3.5-sonnet",
			answer_header = "󱗞  The Gentleman 󱗞",
			auto_insert_mode = true,
			window = { layout = "horizontal" },
			mappings = {
				complete = { insert = "<Tab>" },
				close = { normal = "q", insert = "<C-c>" },
				reset = { normal = "<C-l>", insert = "<C-l>" },
				submit_prompt = { normal = "<CR>", insert = "<C-s>" },
				toggle_sticky = { normal = "grr" },
				clear_stickies = { normal = "grx" },
				accept_diff = { normal = "<C-y>", insert = "<C-y>" },
				jump_to_diff = { normal = "gj" },
				quickfix_answers = { normal = "gqa" },
				quickfix_diffs = { normal = "gqd" },
				yank_diff = { normal = "gy", register = '"' },
				show_diff = { normal = "gd", full_diff = false }, -- <-- cerrar aquí
				show_info = { normal = "gi" }, -- <-- hermanos correctos
				show_context = { normal = "gc" },
				show_help = { normal = "gh" },
			},
		},
		config = function(_, opts)
			local chat = require("CopilotChat")
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "copilot-chat",
				callback = function()
					vim.opt_local.relativenumber = true
					vim.opt_local.number = false
				end,
			})
			chat.setup(opts)
		end,
	},

	{
		"saghen/blink.cmp",
		optional = true,
		---@type table  -- o define una clase abajo
		-- ---@diagnostic disable-next-line: undefined-doc-name
		-- ---@type blink.cmp.Config
		opts = {
			sources = {
				providers = {
					path = {
						enabled = function()
							return vim.bo.filetype ~= "copilot-chat"
						end,
					},
				},
			},
		},
	},
}
