-- lua/plugins/lsp.lua
return {

	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = { "vtsls", "pyright", "ruff", "lua_ls" },
			automatic_installation = true,
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				vtsls = {
					settings = {
						typescript = {
							preferences = {
								includeCompletionsForModuleExports = true,
								includeCompletionsWithSnippetText = true,
							},
						},
						vtsls = { tsserver = { maxTsServerMemory = 4096 } },
					},
				},
				pyright = {
					settings = { python = { analysis = { typeCheckingMode = "basic" } } },
				},
				ruff = { -- ← nombre correcto
					-- evita solapar el hover de Pyright
					on_attach = function(client)
						client.server_capabilities.hoverProvider = false
					end,
					init_options = { settings = { args = {} } },
				},
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = { checkThirdParty = false },
							telemetry = { enable = false },
						},
					},
				},
			},
		},
	},
}
