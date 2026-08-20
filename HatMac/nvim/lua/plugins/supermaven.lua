-- Multi-platform AI code completion
return {
	{
		"supermaven-inc/supermaven-nvim",
		enabled = true,
		event = "InsertEnter",
		config = function()
			local supermaven_api = require("supermaven-nvim.api")

			require("supermaven-nvim").setup({
				keymaps = {
					accept_suggestion = "<Tab>", -- Recomendado para paridad
					clear_suggestion = "<C-]>",
					accept_word = "<C-j>",
				},
				ignore_filetypes = { "cpp", "c", "h" }, -- Removido 'lua' para permitir config
			})

			-- Toggle agnóstico al SO
			vim.keymap.set("n", "<leader>us", function()
				if supermaven_api.is_running() then
					supermaven_api.stop()
					print("Supermaven: OFF")
				else
					supermaven_api.start()
					print("Supermaven: ON")
				end
			end, { desc = "Toggle Supermaven" })
		end,
	},
}
