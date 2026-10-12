return {
	-- overseer.nvim — Task runner async para nvim.
	-- Usado por xixiaofinland/sf.nvim cuando `terminal = "overseer"`
	-- está configurado en su opts.
	--
	-- Features:
	--   - Tasks en background (deploy, retrieve, test) sin bloquear el editor
	--   - Notificaciones cuando completan
	--   - Output navegable
	--   - Cancel con <C-c> desde cualquier lado
	--
	-- Docs: https://github.com/stevearc/overseer.nvim
	{
		"stevearc/overseer.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		-- Sin `opts` ni `config`: las defaults son razonables. sf.nvim
		-- usa overseer internamente para sus tasks cuando está disponible.
	},
}
