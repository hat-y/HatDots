return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},

	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = {
				"vtsls",
				"pyright",
				"ruff",
				"lua_ls",
				"cssls",
				"emmet_ls",
			},
			automatic_installation = true,
		},
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
		},
		opts = {
			on_attach = require("config.lsp_on_attach").on_attach,

			servers = {
				-- NOTE: blink.cmp capabilities are automatically negotiated by LazyVim's blink extra
				-- No need for manual get_lsp_capabilities here
				vtsls = {
					settings = {
						typescript = {
							preferences = {
								includeCompletionsForModuleExports = true,
								includeCompletionsWithSnippetText = true,
							},
						},
						vtsls = {
							tsserver = {
								maxTsServerMemory = 4096,
							},
						},
					},
				},

				pyright = {
					settings = {
						python = {
							analysis = {
								typeCheckingMode = "basic",
							},
						},
					},
				},

				ruff = {
					init_options = {
						settings = {
							args = {},
						},
					},
				},

				lua_ls = {
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								checkThirdParty = false,
							},
							telemetry = {
								enable = false,
							},
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

	{
		"folke/lazydev.nvim",
		opts = {
			enable = true,
		},
	},
}
