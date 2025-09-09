return {
	"yetone/avante.nvim",
	-- ⚠️ En Windows usar el build de PowerShell (descarga binarios precompilados)
	build = (vim.fn.has("win32") ~= 0) and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
		or "make",
	event = "VeryLazy",
	version = false, -- No uses "*" (el autor lo desaconseja)
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		-- selectores y UI (tenés ambos)
		"nvim-telescope/telescope.nvim",
		"folke/snacks.nvim",
		-- opcionales para inputs bonitos y devicons
		"stevearc/dressing.nvim",
		"nvim-tree/nvim-web-devicons",
		-- opcional: cmp sólo para completar comandos de Avante (no es autocompletado inline)
		"hrsh7th/nvim-cmp",
	},
	opts = {
		--- Dónde guardar prompt/políticas de tu proyecto
		instructions_file = "avante.md",

		--- Proveedor de LLM que vamos a usar
		provider = "gemini",
		providers = {
			openai = {
				endpoint = "https://api.openai.com/v1",
				-- Elegí un modelo que tengas disponible. Estos suelen ser buenos compromisos costo/latencia:
				model = "gpt-4o-mini",
				timeout = 30000,
				extra_request_body = {
					temperature = 0.3,
					-- max_tokens = 16384, -- si querés limitar
				},
			},
		},

		selector = {
			provider = "telescope",
		},

		input = { provider = "snacks" },

		shortcuts = {
			{
				name = "refactor",
				description = "Refactor con buenas prácticas y claridad.",
				prompt = "Refactor this code improving readability, maintainability, and keeping behavior. Explain the changes briefly.",
			},
			{
				name = "tests",
				description = "Generar tests con casos borde.",
				prompt = "Generate comprehensive unit tests including edge cases and error conditions for the selected code.",
			},
			{
				name = "docs-es",
				description = "Documentar en español de manera clara y concisa.",
				prompt = "Escribe documentación clara y concisa en español para el siguiente código: funciones, parámetros, retorno y ejemplos.",
			},
		},

		behaviour = {
			enable_fastapply = false,
		},
	},

	keys = {
		{ "<leader>aa", "<cmd>AvanteToggle<cr>", desc = "Avante: abrir/cerrar sidebar" },
		{ "<leader>an", "<cmd>AvanteAsk<cr>", desc = "Avante: preguntar (chat)" },
		{ "<leader>ae", "<cmd>AvanteEdit<cr>", mode = { "v", "n" }, desc = "Avante: editar selección" },
		{ "<leader>am", "<cmd>AvanteModels<cr>", desc = "Avante: elegir modelo" },
		{ "<leader>ah", "<cmd>AvanteHistory<cr>", desc = "Avante: sesiones previas" },
		{
			"<leader>as",
			"<cmd>lua require('avante').keymaps.toggle_suggestion()<cr>",
			desc = "Avante: toggle sugerencias",
		},
	},
}
