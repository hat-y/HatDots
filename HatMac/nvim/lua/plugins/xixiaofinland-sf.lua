return {
	-- sf.nvim — Integración Salesforce para Neovim.
	-- Features: push/retrieve para Apex/LWC/Aura, Apex tests con coverage,
	-- jump-to-def mejorado, diff local vs org, target org indicator.
	-- Docs: https://github.com/xixiaofinland/sf.nvim
	--
	-- Requiere:
	--   - sf CLI instalado (`brew install sf`)
	--   - Treesitter parsers: apex, soql, sosl, sflog
	--   - nvim >= 0.11
	{
		"xixiaofinland/sf.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/overseer.nvim",  -- para terminal = "overseer"
		},
		-- Eager load: cargar al startup en vez de lazy. El plugin es chico
		-- (~few hundred ms de overhead) y queremos que los user commands `:SF`
		-- estén disponibles inmediatamente, incluso fuera de un SF project.
		-- Sin esto, las which-key mappings como `<leader>So` fallan con
		-- "Command SF not found" porque los autocmds que registran los
		-- commands solo corren cuando entrás a un SF project.
		lazy = false,
		opts = {
			-- Desactivamos los default hotkeys — el user los va a configurar
			-- en keymaps si los necesita. Sin esto, el plugin puede pisar
			-- atajos existentes.
			enable_hotkeys = false,

			-- Auto-fetch org list al iniciar nvim.
			fetch_org_list_at_nvim_start = true,

			-- Tipos de metadata que el plugin puede listar/retrievar.
			types_to_retrieve = {
				"ApexClass",
				"ApexTrigger",
				"StaticResource",
				"LightningComponentBundle",
			},

			-- Terminal async via overseer (deploy/retrieve/test corren en
			-- background sin bloquear el editor). Requiere overseer.nvim
			-- instalado — está en dependencies arriba.
			terminal = "overseer",
			term_config = {
				blend = 10,
				dimensions = { height = 0.4, width = 0.8, x = 0.5, y = 0.9 },
			},

			-- Default package dir (SFDX project structure).
			default_dir = "/force-app/main/default/",

			-- Code coverage highlights.
			code_sign_highlight = {
				covered = { fg = "#b7cc85" },   -- match Gentleman theme green
				uncovered = { fg = "#cb7c94" }, -- match Gentleman theme red
			},
		},
		-- Forzar registro de user commands `:SF` siempre, no solo en SF projects.
		-- Sin esto, `<leader>So` falla con "Command SF not found" cuando
		-- estás en un buffer que no es SF.
		config = function(_, opts)
			require("sf").setup(opts)
			-- Inline error reporting en vez de pcall: si algo falla,
			-- lo vemos en :messages.
			local ok, err = pcall(function()
				require("sf.sub.config_user_command").create_user_commands()
			end)
			if not ok then
				vim.notify(
					"sf.nvim: failed to register user commands: " .. tostring(err),
					vim.log.levels.WARN
				)
			end
		end,
	},
}
