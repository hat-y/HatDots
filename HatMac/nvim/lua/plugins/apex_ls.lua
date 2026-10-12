return {
	-- Apex Language Server — setup minimal usando nvim-lspconfig built-in.
	--
	-- nvim-lspconfig ya provee un spec completo para `apex_ls` que:
	--   - detecta JAVA_HOME automáticamente
	--   - usa sfdx-project.json como root marker
	--   - arma el cmd con `-cp`, `-Xmx`, main class, etc.
	--
	-- Solo necesitamos setear `apex_jar_path` (path al JAR bajado por
	-- `hat-sf-install`) y activar el LSP con `vim.lsp.enable`.
	--
	-- Docs: https://github.com/forcedotcom/salesforcedx-vscode
	-- nvim-lspconfig spec: ~/.local/share/nvim/lazy/nvim-lspconfig/lsp/apex_ls.lua
	{
		"neovim/nvim-lspconfig",
		ft = { "apex" },
		opts = {
			-- Path al JAR bajado por `hat-sf-install`. Mason path por default.
			-- Si no usás Mason, apuntá al path absoluto de tu JAR.
			apex_jar_path = vim.fn.expand(
				"$MASON/share/apex-language-server/apex-jorje-lsp.jar"
			),

			-- Surface errores semánticos de Apex (requiere sObject stubs).
			apex_enable_semantic_errors = true,

			-- No subir telemetría de completion.
			apex_enable_completion_statistics = false,

			-- LWC typegeneration deshabilitado (no estamos en LWC project).
			apex_jvm_max_heap = "4g",
		},
	},
}
