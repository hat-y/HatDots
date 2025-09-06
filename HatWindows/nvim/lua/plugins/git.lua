return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			current_line_blame = true,
			current_line_blame_opts = { delay = 400, virt_text_pos = "eol" },
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. (desc or "") })
				end
				map("n", "]c", gs.next_hunk, "Next hunk")
				map("n", "[c", gs.prev_hunk, "Prev hunk")
				map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
				map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
				map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
				map("n", "<leader>hb", gs.toggle_current_line_blame, "Toggle blame line")
				map("n", "<leader>hd", gs.diffthis, "Diff this")
			end,
		},
	},

	-- LazyGit
	{
		"kdheepak/lazygit.nvim",
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" }, -- repo actual
			{ "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (file)" }, -- enfocado en el archivo
		},
	},
}
