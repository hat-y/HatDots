return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			-- Configuración para pyright con uv
			pyright = {
				settings = {
					python = {
						-- Buscar automáticamente entornos virtuales de uv
						venvPath = ".",
						venv = ".venv",
						analysis = {
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							diagnosticMode = "openFilesOnly",
							-- Importar configuración de uv si existe
							pythonPath = function()
								local function find_python_path()
									-- Intentar con .venv local (uv default)
									local local_venv = vim.fn.fnamemodify(vim.fn.getcwd(), ":p") .. ".venv"
									if vim.fn.isdirectory(local_venv) == 1 then
										local python_exe = local_venv .. "/bin/python"
										if vim.fn.executable(python_exe) == 1 then
											return python_exe
										end
										-- Windows compatibility
										python_exe = local_venv .. "\\Scripts\\python.exe"
										if vim.fn.executable(python_exe) == 1 then
											return python_exe
										end
									end

									-- Usar el Python actual
									return vim.fn.exepath("python3") or vim.fn.exepath("python")
								end

								return find_python_path()
							end,
						},
					},
				},
			},
		},
	},

	-- Integración con uv para instalación de paquetes
	{
		"nvim-neotest/neotest",
		optional = true,
		opts = {
			adapters = {
				["python"] = {
					python = function()
						-- Buscar intérprete Python con uv
						local local_venv = vim.fn.fnamemodify(vim.fn.getcwd(), ":p") .. ".venv"
						if vim.fn.isdirectory(local_venv) == 1 then
							return local_venv .. "/bin/python"
						end
						return "python3"
					end,
				},
			},
		},
	},

	-- DAP (Debug Adapter Protocol) para Python con uv
	{
		"mfussenegger/nvim-dap",
		optional = true,
		opts = {
			setup = {
				python = function()
					require("dap-python").setup("python3")

					-- Configurar para usar entornos virtuales uv
					table.insert(require("dap").configurations.python, {
						type = "python",
						request = "launch",
						name = "Launch with uv venv",
						program = function()
							return vim.fn.input("Path to script: ", vim.fn.getcwd() .. "/", "file")
						end,
						python = function()
							local local_venv = vim.fn.fnamemodify(vim.fn.getcwd(), ":p") .. ".venv"
							if vim.fn.isdirectory(local_venv) == 1 then
								return local_venv .. "/bin/python"
							end
							return "python3"
						end,
						console = "integratedTerminal",
					})
				end,
			},
		},
	},

	-- Configuración de treesitter para Python
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, { "python" })
			end
		end,
	},
}

