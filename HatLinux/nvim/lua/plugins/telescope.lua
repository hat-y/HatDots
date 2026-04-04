return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local lga_actions = require("telescope-live-grep-args.actions")

			telescope.setup({
				defaults = {
					-- Search options
					file_ignore_patterns = {
						".git/",
						"node_modules/",
						"dist/",
						"build/",
						"target/",
						"__pycache__/",
						".venv/",
						"venv/",
						".vscode/",
						"*.lock",
						"package-lock.json",
						"yarn.lock",
						"pnpm-lock.yaml",
						".DS_Store",
						"Thumbs.db",
						"*.tmp",
						"*.temp"
					},
					layout_strategy = "horizontal",
					layout_config = {
						prompt_position = "top",
						width = 0.9,
						height = 0.85,
						horizontal = {
							preview_width = 0.6,
						},
					},
					borderchars = {
						prompt = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
						results = { "─", "│", "─", "│", "├", "┤", "┴", "└" },
						preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
					},
					mappings = {
						i = {
							["<C-j>"] = "move_selection_next",
							["<C-k>"] = "move_selection_previous",
							["<Down>"] = "move_selection_next",
							["<Up>"] = "move_selection_previous",
							["<C-n>"] = "cycle_history_next",
							["<C-p>"] = "cycle_history_prev",
							["<C-c>"] = "close",
							["<CR>"] = "select_default",
							["<C-x>"] = "select_horizontal",
							["<C-v>"] = "select_vertical",
							["<C-t>"] = "select_tab",
							["<C-q>"] = "send_to_qflist",
							["<M-q>"] = "send_selected_to_qflist",
							["<Tab>"] = "select_default",
							["<S-Tab>"] = "results_scrolling_up",
							["<C-u>"] = "results_scrolling_up",
							["<C-d>"] = "results_scrolling_down",
							["<PageUp>"] = "preview_scrolling_up",
							["<PageDown>"] = "preview_scrolling_down",
						},
						n = {
							["<ESC>"] = "close",
							["<CR>"] = "select_default",
							["<C-x>"] = "select_horizontal",
							["<C-v>"] = "select_vertical",
							["<C-t>"] = "select_tab",
							["<C-n>"] = "cycle_history_next",
							["<C-p>"] = "cycle_history_prev",
							["<C-q>"] = "send_to_qflist",
							["<M-q>"] = "send_selected_to_qflist",
							["j"] = "move_selection_next",
							["k"] = "move_selection_previous",
							["<Down>"] = "move_selection_next",
							["<Up>"] = "move_selection_previous",
							["<Tab>"] = "select_default",
							["<S-Tab>"] = "results_scrolling_up",
							["<C-u>"] = "results_scrolling_up",
							["<C-d>"] = "results_scrolling_down",
							["<PageUp>"] = "preview_scrolling_up",
							["<PageDown>"] = "preview_scrolling_down",
						},
					},
					prompt_prefix = "   ",
					selection_caret = "  ",
					entry_prefix = "  ",
					initial_mode = "insert",
					selection_strategy = "reset",
					sorting_strategy = "descending",
					winblend = 0,
					border = {},
					borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
					color_devicons = true,
					use_less = true,
					set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
				},
				pickers = {
					-- Find files
					find_files = {
						find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" },
						theme = "dropdown",
						previewer = false,
						layout_config = {
							width = 0.8,
							prompt_position = "top",
						},
					},
					-- Live grep
					live_grep = {
						theme = "ivy",
						additional_args = function()
							return { "--hidden", "--glob", "!{.git,node_modules}" }
						end,
					},
					-- Git files
					git_files = {
						show_untracked = true,
						theme = "dropdown",
						previewer = false,
						layout_config = {
							width = 0.8,
							prompt_position = "top",
						},
					},
					-- LSP symbols
					lsp_document_symbols = {
						theme = "ivy",
						symbols = {
							File = { icon = "", color = "fg" },
							Module = { icon = "", color = "fg" },
							Namespace = { icon = "", color = "fg" },
							Package = { icon = "", color = "fg" },
							Class = { icon = "", color = "fg" },
							Method = { icon = "", color = "fg" },
							Property = { icon = "", color = "fg" },
							Field = { icon = "", color = "fg" },
							Constructor = { icon = "", color = "fg" },
							Enum = { icon = "", color = "fg" },
							Interface = { icon = "", color = "fg" },
							Function = { icon = "", color = "fg" },
							Variable = { icon = "", color = "fg" },
							Constant = { icon = "", color = "fg" },
							String = { icon = "", color = "fg" },
							Number = { icon = "", color = "fg" },
							Boolean = { icon = "", color = "fg" },
							Array = { icon = "", color = "fg" },
							Object = { icon = "", color = "fg" },
							Key = { icon = "", color = "fg" },
							Null = { icon = "", color = "fg" },
							EnumMember = { icon = "", color = "fg" },
							Struct = { icon = "", color = "fg" },
							Event = { icon = "", color = "fg" },
							Operator = { icon = "", color = "fg" },
							TypeParameter = { icon = "", color = "fg" },
						},
					},
					-- LSP references
					lsp_references = {
						theme = "dropdown",
						initial_mode = "normal",
						layout_config = {
							width = 0.8,
							prompt_position = "top",
						},
					},
					-- LSP implementations
					lsp_implementations = {
						theme = "dropdown",
						initial_mode = "normal",
						layout_config = {
							width = 0.8,
							prompt_position = "top",
						},
					},
					-- LSP definitions
					lsp_definitions = {
						theme = "dropdown",
						initial_mode = "normal",
						layout_config = {
							width = 0.8,
							prompt_position = "top",
						},
					},
					-- LSP type definitions
					lsp_type_definitions = {
						theme = "dropdown",
						initial_mode = "normal",
						layout_config = {
							width = 0.8,
							prompt_position = "top",
						},
					},
					-- Buffers
					buffers = {
						theme = "dropdown",
						previewer = false,
						initial_mode = "normal",
						layout_config = {
							width = 0.8,
							prompt_position = "top",
						},
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
					live_grep_args = {
						auto_quoting = true, -- enable/disable auto-quoting
					 mappings = { -- extend mappings
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
								["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
								["<C-t>"] = lga_actions.quote_prompt({ postfix = " --type " }),
								["<C-u>"] = lga_actions.quote_prompt({ postfix = " -u" }),
								["<C-w>"] = lga_actions.quote_prompt({ postfix = " -w" }),
							},
						},
					},
				},
			})

			-- Load extensions only if they are available
			pcall(function() telescope.load_extension("fzf") end)
			pcall(function() telescope.load_extension("live_grep_args") end)
			pcall(function() telescope.load_extension("ui-select") end)

			-- Syntax highlighting configuration in preview
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")
			local transform_mod = require("telescope.actions.mt").transform_mod

			-- Custom actions
			local open_with_trouble = function(prompt_bufnr)
				local action = require("trouble.sources.telescope").open
				action(prompt_bufnr)
			end
		end,
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},
	{
		"nvim-telescope/telescope-live-grep-args.nvim",
		-- This will not install any needed dependencies. To install,
		-- please run the following make command. make install_deps
	},
}
