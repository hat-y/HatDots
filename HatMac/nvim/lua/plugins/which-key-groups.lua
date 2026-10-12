-- Grupos personalizados de which-key para HatDots.
-- Usa vim.keymap.set directamente con `desc` (no wk.add). which-key detecta
-- los mappings con desc automáticamente y los muestra en el popup cuando
-- se aprieta el prefix. Para los grupos, el desc empieza con "[X] label"
-- que which-key interpreta como agrupador.
return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		-- `config` se ejecuta DESPUÉS del setup de which-key, así que
		-- `vim.keymap.set` registra mappings que which-key detecta vía
		-- sus triggers <auto> automáticamente.
		config = function()
			local map = function(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
			end

			-- ── [H]erdr / HatDots ─────────────────────────────────────
			-- Mismas acciones que los `[[keys.command]]` del config.toml
			-- de herdr, accesibles desde nvim (cualquier pane).
			map("<leader>hn", "<cmd>silent !hat-news<cr>", "[H]atDots: hat-news (RSS con notif)")
			map("<leader>ho", "<cmd>silent !open -a Obsidian<cr>", "[H]atDots: Abrir Obsidian")
			map("<leader>hr", "<cmd>silent !herdr server reload-config<cr>", "[H]erdr: reload config.toml")
			map("<leader>hs", "<cmd>silent !herdr status<cr>", "[H]erdr: status (server + client)")
			map("<leader>hx", "<cmd>silent !herdr server stop<cr>", "[H]erdr: stop server")

			-- ── [S]alesforce ──────────────────────────────────────────
			-- Comandos del plugin xixiaofinland/sf.nvim (lazy-load en :SF).
			-- S mayúscula para no pisar el grupo `s` (search) de LazyVim.
			map("<leader>So", "<cmd>SF org fetchList<cr>", "[S]alesforce: listar todas las orgs")
			map("<leader>SO", "<cmd>SF org setTarget<cr>", "[S]alesforce: setear target org")
			map("<leader>Sp", "<cmd>SF currentFile push<cr>", "[S]alesforce: push archivo actual")
			map("<leader>Sr", "<cmd>SF currentFile retrieve<cr>", "[S]alesforce: retrieve archivo actual")
			map("<leader>St", "<cmd>SF test allTestsInFile<cr>", "[S]alesforce: Apex tests del archivo")
			map("<leader>Stt", "<cmd>SF test allTestsInClass<cr>", "[S]alesforce: tests de la clase")
			map("<leader>Soo", "<cmd>SF org open<cr>", "[S]alesforce: abrir org en browser")
			map("<leader>Smd", "<cmd>SF md list<cr>", "[S]alesforce: listar metadata")
			map("<leader>Sc", "<cmd>check sf<cr>", "[S]alesforce: health check del plugin")
		end,
	},
}
