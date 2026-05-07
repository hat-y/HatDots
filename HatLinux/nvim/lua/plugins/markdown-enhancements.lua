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
			-- Configuration for markdown preview
			vim.g.mkdp_auto_start = 0
			vim.g.mkdp_auto_close = 1
			vim.g.mkdp_preview_options = {
				mkit = {},
				katex = {},
				uml = {},
				maid = {},
				disable_sync_scroll = 0,
				-- sync_scroll_type = "middle",
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

	-- Telescope Media Files for media preview
	{
		"nvim-telescope/telescope-media-files.nvim",
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

	-- Markdown Commenting
	{
		"numToStr/Comment.nvim",
		event = "BufReadPost",
		keys = { "gc", "gcc", "gbc" },
		config = function()
			require("Comment").setup({
				toggler = {
					line = "gcc",
					block = "gbc",
				},
				padding = true,
				sticky = true,
				keys = {
					comment = "gc",
					ecomment = "gc",
					multiline_comment = "gbc",
				},
			})
		end,
	},

	-- render-markdown.nvim - Inline markdown rendering
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		opts = {}, -- use defaults — no custom opts to avoid version incompatibilities
	},

	-- vim-markdown - Markdown power features
	{
		"plasticboy/vim-markdown",
		ft = { "markdown" },
		config = function()
			-- Configure vim-markdown
			vim.g.vim_markdown_folding_style_pythonic = 1
			vim.g.vim_markdown_folding_level = 10
			vim.g.vim_markdown_strikethrough = 1
			vim.g.vim_markdown_fenced_code_blocks = 1
			vim.g.vim_markdown_frontmatter = 1
			vim.g.vim_markdown_header_syntax_overrides = {}

			-- Disable default keymaps to avoid conflicts
			vim.g.vim_markdown_no_default_keymaps = 1

			-- Enable conceal for markdown
			vim.opt.conceallevel = 2
			vim.opt.concealcursor = "n"

			-- Folding is handled by nvim-treesitter
			-- (removed broken foldexpr that referenced non-existent v:lua.vim.markdown#foldlevel())

			-- Create TOC command
			local function generate_toc()
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
				local toc = {}

				for i, line in ipairs(lines) do
					local level = line:match("^#*")
					if level then
						local heading = line:gsub("^#+%s*", "")
						local heading_id = heading:lower():gsub("%s+", "-"):gsub("[^%a%-]", "")
						table.insert(toc, string.rep("  ", (#level / 2) - 1) .. "- [" .. heading .. "](#" .. heading_id .. ")")
					end
				end

				local current_line = vim.api.nvim_win_get_cursor(0)[1]
				table.insert(toc, 1, "---")
				table.insert(toc, 1, "## Table of Contents")
				table.insert(toc, 1, "---")

				vim.api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, toc)
				vim.cmd("normal! zz")
			end

			vim.keymap.set("n", "<leader>mt", generate_toc, { desc = "Generate TOC" })
		end,
	},
}
