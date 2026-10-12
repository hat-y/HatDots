-- Custom which-key groups for HatDots.
-- Uses vim.keymap.set directly with `desc` (not wk.add). which-key detects
-- mappings with a `desc` automatically and shows them in the popup when the
-- prefix key is pressed. For groups, the desc starting with "[X] label" is
-- what which-key interprets as a group header.
return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		-- `config` runs AFTER which-key's own setup, so `vim.keymap.set` here
		-- registers mappings that which-key picks up via its <auto> triggers.
		config = function()
			local map = function(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
			end

			-- ── [H]erdr / HatDots ─────────────────────────────────────
			-- Same actions as the `[[keys.command]]` entries in herdr's
			-- config.toml, available from Neovim in any pane.
			map("<leader>hn", "<cmd>silent !hat-news<cr>", "[H]atDots: hat-news (RSS with notification)")
			if vim.fn.has("macunix") == 1 then
				-- `open -a` is macOS-only; Linux/Omarchy open Obsidian via
				-- the desktop launcher instead.
				map("<leader>ho", "<cmd>silent !open -a Obsidian<cr>", "[H]atDots: Open Obsidian")
			end
			map("<leader>hr", "<cmd>silent !herdr server reload-config<cr>", "[H]erdr: reload config.toml")
			map("<leader>hs", "<cmd>silent !herdr status<cr>", "[H]erdr: status (server + client)")
			map("<leader>hx", "<cmd>silent !herdr server stop<cr>", "[H]erdr: stop server")

			-- ── [S]alesforce ──────────────────────────────────────────
			-- Commands for the xixiaofinland/sf.nvim plugin (lazy-loaded
			-- via :SF). Capital S so this doesn't shadow LazyVim's `s`
			-- (search) group.
			map("<leader>So", "<cmd>SF org fetchList<cr>", "[S]alesforce: list all orgs")
			map("<leader>SO", "<cmd>SF org setTarget<cr>", "[S]alesforce: set target org")
			map("<leader>Sp", "<cmd>SF currentFile push<cr>", "[S]alesforce: push current file")
			map("<leader>Sr", "<cmd>SF currentFile retrieve<cr>", "[S]alesforce: retrieve current file")
			map("<leader>St", "<cmd>SF test allTestsInFile<cr>", "[S]alesforce: Apex tests for this file")
			map("<leader>Stt", "<cmd>SF test allTestsInClass<cr>", "[S]alesforce: tests for this class")
			map("<leader>Soo", "<cmd>SF org open<cr>", "[S]alesforce: open org in browser")
			map("<leader>Smd", "<cmd>SF md list<cr>", "[S]alesforce: list metadata")
			map("<leader>Smt", "<cmd>SF mdtype list<cr>", "[S]alesforce: retrieve metadata by type")
			map("<leader>Sa", "<cmd>SF currentFile RunAsAnonymous<cr>", "[S]alesforce: run file as anonymous Apex")
			map("<leader>Sc", "<cmd>check sf<cr>", "[S]alesforce: plugin health check")
		end,
	},
}
