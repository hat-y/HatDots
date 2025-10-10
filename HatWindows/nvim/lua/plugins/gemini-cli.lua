return {
	"marcinjahn/gemini-cli.nvim",
	cmd = "Gemini",
	keys = {
		{ "<leader>g", group = "Gemini" },
		{ "<leader>gt", "<cmd>Gemini toggle<cr>", desc = "Toggle Gemini" },
		{ "<leader>ga", "<cmd>Gemini ask<cr>", desc = "Ask Gemini", mode = { "n", "v" } },
		{ "<leader>gf", "<cmd>Gemini add_file<cr>", desc = "Add File" },
	},
	dependencies = {
		"folke/snacks.nvim",
	},
	config = function()
		require("gemini_cli").setup({
			args = {
				"--model",
				"gemini-2.5-flash",
			},
			win_opts = {
				width = 0.8, -- 80% del ancho de la ventana de Neovim
				height = 0.8, -- 80% del alto de la ventana de Neovim
				wrap = true, -- Asegura que el texto se ajuste a la ventana
			},
			code_highlighting = true, -- Asegura el resaltado de sintaxis para el código
		})
	end,
}
