return {
	"yetone/avante.nvim",
	build = (vim.fn.has("win32") ~= 0) and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
		or "make",
	event = "VeryLazy",
	version = false, -- no usar "*"
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",

		-- Selectores / UI (ya usás telescope y snacks)
		"nvim-telescope/telescope.nvim",
		"folke/snacks.nvim",

		-- UI nice-to-have
		"stevearc/dressing.nvim",
		"nvim-tree/nvim-web-devicons",

		-- Opcional: solo para completar comandos de Avante (no “ghost text”)
		"hrsh7th/nvim-cmp",

		-- Pegar imágenes (opcional pero útil)
		{
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = { insert_mode = true },
					use_absolute_path = true, -- Windows
				},
			},
		},

		-- Markdown render en paneles de Avante (opcional)
		{
			"MeanderingProgrammer/render-markdown.nvim",
			ft = { "markdown", "Avante" },
			opts = { file_types = { "markdown", "Avante" } },
		},
	},

	opts = {
		-- Archivo con tus reglas y prompts del proyecto
		instructions_file = "avante.md",

		-- === Proveedor por defecto ===
		provider = "gemini",

		-- Config específica de Gemini
		gemini = {
			model = "gemini-2.5-flash",
			-- Afinado de generación (opcional)
			generationConfig = {
				temperature = 0.3,
				-- maxOutputTokens = 8192,
			},
			-- por defecto usa GEMINI_API_KEY
			-- api_key_name = "GEMINI_API_KEY",
		},

		-- (Opcional) Dejar preconfigurado OpenAI por si cambiás en runtime con :AvanteModels
		openai = {
			endpoint = "https://api.openai.com/v1",
			model = "gpt-4o-mini",
			timeout = 30000,
			extra_request_body = {
				temperature = 0.3,
			},
			-- usa OPENAI_API_KEY
		},

		-- Pickers e inputs
		selector = { provider = "telescope" },
		input = { provider = "snacks" },

		-- Sin autosugerencias “fantasma”: no configuramos nada tipo inline
		-- (Avante no impone ghost text por defecto; se activa sólo si lo mapeás)

		-- Atajos (presets) de acciones
		shortcuts = {
			{
				name = "refactor",
				description = "Refactor con buenas prácticas y claridad.",
				prompt = "Refactor this code improving readability, maintainability, and keeping behavior. Explain briefly.",
			},
			{
				name = "tests",
				description = "Generar tests con casos borde.",
				prompt = "Generate comprehensive unit tests including edge cases and error conditions.",
			},
			{
				name = "docs-es",
				description = "Documentar en español.",
				prompt = "Escribe documentación clara en español: propósito, funciones, parámetros, retorno y ejemplos.",
			},
		},

		behaviour = {
			enable_fastapply = false, -- aplicá cambios de forma revisada
		},
	},

	keys = {
		{ "<leader>aa", "<cmd>AvanteToggle<cr>", desc = "Avante: abrir/cerrar panel" },
		{ "<leader>an", "<cmd>AvanteAsk<cr>", desc = "Avante: preguntar (chat)" },
		{ "<leader>ae", "<cmd>AvanteEdit<cr>", mode = { "x", "n" }, desc = "Avante: editar selección/archivo" },
		{ "<leader>am", "<cmd>AvanteModels<cr>", desc = "Avante: elegir modelo" },
		{ "<leader>ah", "<cmd>AvanteHistory<cr>", desc = "Avante: historial sesiones" },
	},
}
