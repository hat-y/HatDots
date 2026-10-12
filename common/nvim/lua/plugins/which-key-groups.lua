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

			-- NOTE: a Salesforce `<leader>S*` group existed here on macOS,
			-- bound to xixiaofinland/sf.nvim's `:SF` commands. Dropped: it
			-- collides with the active Linux lua/salesforce/* module, which
			-- already owns the whole <leader>S* namespace (<leader>So,
			-- <leader>Sp, <leader>Sr, <leader>St, <leader>SO, ...) and whose
			-- implementation is the one phase 3 decided to keep active. See
			-- odd/tasks/hatdots-unify.md, "Phase 3 decisions".
		end,
	},
}
