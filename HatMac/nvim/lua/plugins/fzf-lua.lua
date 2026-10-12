return {
	-- fzf-lua — Solo lo necesitamos para que xixiaofinland/sf.nvim
	-- pueda ejecutar `:SF md list` (su UI preferida para listar metadata).
	-- El plugin de SF lo detecta automáticamente y lo usa cuando está
	-- disponible; sin él, el check reportaba "fzf-lua not found".
	--
	-- NO activamos keybindings ni reemplazamos snacks: snacks sigue siendo
	-- el picker default para find_files, live_grep, etc.
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = true,
		-- Solo carga cuando alguien lo invoca explícitamente (sf.nvim, snacks,
		-- o un :FzfLua command). Evita carga innecesaria al startup.
		cmd = { "FzfLua" },
	},
}
