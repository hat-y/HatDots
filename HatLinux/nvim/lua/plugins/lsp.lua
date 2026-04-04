return {
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = { "vtsls", "pyright", "ruff", "lua_ls", "cssls", "html", "emmet_ls" },
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
				ruff = {
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
				cssls = {
					settings = {
						css = {
							validate = true,
							lint = {
								unknownProperties = "warning",
								important = "warning",
								duplicateProperties = "warning",
							},
						},
						scss = {
							validate = true,
							lint = {
								unknownProperties = "warning",
							},
						},
						less = {
							validate = true,
							lint = {
								unknownProperties = "warning",
							},
						},
					},
				},
				html = {
					settings = {
						html = {
							hover = {
								documentation = true,
								references = true,
							},
							validate = {
								enabled = true,
								styles = true,
								scripts = true,
							},
							format = {
								enabled = true,
								wrapLineLength = 120,
								wrapAttributes = "auto",
							},
						},
					},
				},
				emmet_ls = {
					settings = {
						emmet = {
							showSuggestionsAsSnippets = true,
							expandAbbreviation = true,
							showExpandedAbbreviation = "always",
						},
					},
				},
			},
		},
	},
}
