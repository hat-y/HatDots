return {
	{ "mason-org/mason.nvim", config = true },

	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = { "neovim/nvim-lspconfig", "mason-org/mason.nvim" },
		opts = {
			ensure_installed = { "lua_ls", "pyright", "rust_analyzer", "vtsls" },
		},
		config = function(_, opts)
			require("mason").setup()
			require("mason-lspconfig").setup(opts)

			local lsp = require("lspconfig")

			-- capacidades (cmp opcional) + forzar UTF-16 (evita bugs de col con hints)
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
			if ok_cmp then
				capabilities = cmp.default_capabilities(capabilities)
			end
			capabilities.general = capabilities.general or {}
			capabilities.general.positionEncodings = { "utf-16" }

			-- helpers
			local function map(bufnr, mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
			end
			local function diag_prev()
				if vim.diagnostic.jump then
					vim.diagnostic.jump({ count = -1 })
				else
					vim.diagnostic.goto_prev()
				end
			end
			local function diag_next()
				if vim.diagnostic.jump then
					vim.diagnostic.jump({ count = 1 })
				else
					vim.diagnostic.goto_next()
				end
			end
			local function enable_inlay(bufnr, enable, mode)
				if not (vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable) then
					return
				end
				mode = mode or "eol"
				if
					not pcall(function()
						vim.lsp.inlay_hint.enable(enable, { bufnr = bufnr, mode = mode })
					end)
				then
					pcall(vim.lsp.inlay_hint.enable, bufnr, enable)
				end
			end

			local function on_attach(client, bufnr)
				map(bufnr, "n", "gd", vim.lsp.buf.definition, "Goto Def")
				map(bufnr, "n", "gr", vim.lsp.buf.references, "References")
				map(bufnr, "n", "K", vim.lsp.buf.hover, "Hover")
				map(bufnr, "n", "<leader>rn", vim.lsp.buf.rename, "Rename")
				map(bufnr, "n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
				map(bufnr, "n", "[d", diag_prev, "Prev Diag")
				map(bufnr, "n", "]d", diag_next, "Next Diag")

				if client and (client.name == "vtsls" or client.name == "rust_analyzer" or client.name == "lua_ls") then
					enable_inlay(bufnr, true, "eol")
				end
			end

			-- Evitar doble cliente TS (tsserver/ts_ls vs vtsls)
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local c = vim.lsp.get_client_by_id(args.data.client_id)
					if not c then
						return
					end
					if c.name == "tsserver" or c.name == "ts_ls" then
						for _, other in pairs(vim.lsp.get_clients({ bufnr = args.buf })) do
							if other.name == "vtsls" then
								vim.schedule(function()
									c.stop(true)
								end)
							end
						end
					end
				end,
			})

			-- Toggle de inlay hints (siempre en EOL)
			vim.keymap.set("n", "<leader>uh", function()
				local buf = vim.api.nvim_get_current_buf()
				local ok, enabled = pcall(vim.lsp.inlay_hint.is_enabled, { bufnr = buf })
				if not ok then
					ok, enabled = pcall(vim.lsp.inlay_hint.is_enabled, buf)
				end
				enable_inlay(buf, not enabled, "eol")
			end, { desc = "Toggle Inlay Hints (EOL)" })

			-- lua_ls
			lsp.lua_ls.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						hint = { enable = true, arrayIndex = "Disable", paramName = "Disable", paramType = true },
						workspace = { checkThirdParty = false },
					},
				},
			})

			-- vtsls (JS/TS)
			if lsp.vtsls then
				lsp.vtsls.setup({
					on_attach = on_attach,
					capabilities = capabilities,
					settings = {
						complete_function_calls = true,
						vtsls = {
							autoUseWorkspaceTsdk = true,
							enableMoveToFileCodeAction = true,
							experimental = {
								completion = { enableServerSideFuzzyMatch = true },
								maxInlayHintLength = 30,
							},
						},
						typescript = {
							inlayHints = {
								parameterNames = { enabled = "literals" },
								parameterTypes = { enabled = true },
								variableTypes = { enabled = false },
								propertyDeclarationTypes = { enabled = true },
								functionLikeReturnTypes = { enabled = true },
								enumMemberValues = { enabled = true },
							},
							suggest = { completeFunctionCalls = true },
							updateImportsOnFileMove = { enabled = "always" },
						},
						javascript = {
							inlayHints = {
								parameterNames = { enabled = "literals" },
								parameterTypes = { enabled = true },
								variableTypes = { enabled = false },
								propertyDeclarationTypes = { enabled = true },
								functionLikeReturnTypes = { enabled = true },
								enumMemberValues = { enabled = true },
							},
							suggest = { completeFunctionCalls = true },
							updateImportsOnFileMove = { enabled = "always" },
						},
					},
				})
			end

			-- pyright
			lsp.pyright.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					python = {
						analysis = {
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							diagnosticMode = "openFilesOnly",
						},
					},
				},
			})

			-- rust_analyzer
			lsp.rust_analyzer.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						inlayHints = { enable = true },
					},
				},
			})
		end,
	},
}
