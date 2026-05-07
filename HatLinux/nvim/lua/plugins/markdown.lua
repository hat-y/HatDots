return {
	-- Markdown Preview (Reading Mode)
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		config = function()
			vim.g.mkdp_auto_start = 0
			vim.g.mkdp_auto_close = 1
			vim.g.mkdp_preview_options = {
				mkit = {},
				katex = {},
				uml = {},
				maid = {},
				disable_sync_scroll = 0,
				hide_yaml_meta = 1,
				sequence_diagrams = {},
				flowchart_diagrams = {},
				content_editable = false,
				disable_filename = 0,
				toc = {},
			}
			vim.g.mkdp_page_title = "${name}"
			vim.g.mkdp_theme = "dark"
		end,
	},

	-- Inline markdown rendering
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		opts = {},
	},

	-- Telescope Media Files for media preview
	-- NOTE: unmaintained — consider replacing in future
	{
		"nvim-telescope/telescope-media-files.nvim",
		ft = "markdown",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("telescope").load_extension("media_files")
			vim.keymap.set("n", "<leader>fp", function()
				require("telescope").extensions.media_files.media_files()
			end, { desc = "Preview media files" })
		end,
	},

	-- Which-key markdown groups + buffer keymap autocmds
	{
		"folke/which-key.nvim",
		opts = function(_, opts)
			opts.spec = opts.spec or {}

			local spec = {
				{ "<leader>m", group = "Markdown & Obsidian", icon = "📝" },

				-- Headings (insert mode: ,1 to ,6)
				{ "<leader>m1", desc = "Heading 1  (,1)", icon = "#" },
				{ "<leader>m2", desc = "Heading 2  (,2)", icon = "##" },
				{ "<leader>m3", desc = "Heading 3  (,3)", icon = "###" },
				{ "<leader>m4", desc = "Heading 4  (,4)", icon = "####" },
				{ "<leader>m5", desc = "Heading 5  (,5)", icon = "#####" },
				{ "<leader>m6", desc = "Heading 6  (,6)", icon = "######" },

				-- Formatting via mini.surround (visual mode: select + sa X)
				{ "<leader>mf", group = "Format  (visual: sa)", icon = "✨" },
				{ "<leader>mfb", desc = "Bold  (sa b)", icon = "**" },
				{ "<leader>mfi", desc = "Italic  (sa i)", icon = "*" },
				{ "<leader>mfl", desc = "Link  (sa l)", icon = "[]" },
				{ "<leader>mfc", desc = "Code  (sa c)", icon = "`" },
				{ "<leader>mfC", desc = "Code block  (sa C)", icon = "```" },

				-- Quick insert
				{ "<leader>mq", desc = "Blockquote  (,q)", icon = ">" },
				{ "<leader>mc", desc = "Toggle checkbox  (,c)", icon = "☑" },
				{ "<leader>mt", desc = "Generate TOC  (<leader>mt)", icon = "📋" },

				-- Spell & UI
				{ "<leader>ms", desc = "Spell correct  (<leader>sz)", icon = "✓" },
				{ "<leader>mz", desc = "Zen mode  (<leader>zz)", icon = "🧘" },
				{ "<leader>mu", desc = "Toggle Supermaven  (<leader>us)", icon = "🤖" },
				{ "<leader>mp", desc = "Paste image  (Ctrl+V)", icon = "🖼" },
				{ "<leader>mP", desc = "Markdown preview  (:MarkdownPreview)", icon = "👁" },

				-- Obsidian (actual keymaps: <leader>o*)
				{ "<leader>mo", group = "Obsidian  (<leader>o)", icon = "📁" },
				{ "<leader>moo", desc = "Open in Obsidian app  (oo)" },
				{ "<leader>mon", desc = "New note  (on)" },
				{ "<leader>moq", desc = "Quick switch  (oq)" },
				{ "<leader>moQ", desc = "Today's log  (oQ)" },
				{ "<leader>mos", desc = "Search  (os)" },
				{ "<leader>mot", desc = "Insert template  (ot)" },
				{ "<leader>mol", desc = "Buffer links  (ol)" },
				{ "<leader>molT", desc = "Log template  (olT)" },
				{ "<leader>mob", desc = "Backlinks  (ob)" },
				{ "<leader>mod", desc = "Daily (today)  (od)" },
				{ "<leader>moD", desc = "Daily (tomorrow)  (oD)" },
				{ "<leader>moy", desc = "Daily (yesterday)  (oy)" },
				{ "<leader>mor", desc = "Rename note  (or)" },
				{ "<leader>moO", desc = "Force open Obsidian  (oO)" },
			}

			vim.list_extend(opts.spec, spec)
		end,
		config = function()
			-- Buffer-local markdown keymaps
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "markdown", "markdown.mdx" },
				callback = function()
					local buf = vim.api.nvim_get_current_buf()
					local km = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
					end
					local mu = require("config.markdown_utils")

					km("i", ",1", function()
						mu.insert_heading({ level = 1 })
					end, "Insert H1")
					km("i", ",2", function()
						mu.insert_heading({ level = 2 })
					end, "Insert H2")
					km("i", ",3", function()
						mu.insert_heading({ level = 3 })
					end, "Insert H3")
					km("i", ",4", function()
						mu.insert_heading({ level = 4 })
					end, "Insert H4")
					km("i", ",5", function()
						mu.insert_heading({ level = 5 })
					end, "Insert H5")
					km("i", ",6", function()
						mu.insert_heading({ level = 6 })
					end, "Insert H6")
					km("i", ",q", mu.insert_blockquote, "Insert blockquote")
					km("n", ",c", mu.toggle_checkbox, "Toggle checkbox")
					km("n", "<leader>mt", mu.generate_toc, "Generate TOC")
				end,
			})
		end,
	},
}
