-- Windows-only AI code completion
return {
	{
		"supermaven-inc/supermaven-nvim",
		enabled = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1,
		event = "InsertEnter",
		config = function()
			local supermaven_api = require("supermaven-nvim.api")

			require("supermaven-nvim").setup({
				keymaps = {
					clear_suggestion = "<C-]>",
					accept_word = "<C-w>",
				},
				ignore_filetypes = { "cpp", "c", "h", "lua" },
			})

			-- Reliable toggle using the API directly
			vim.keymap.set("n", "<leader>us", function()
				if supermaven_api.is_running() then
					supermaven_api.stop()
					vim.notify("Supermaven disabled", vim.log.levels.INFO)
				else
					supermaven_api.start()
					vim.notify("Supermaven enabled", vim.log.levels.INFO)
				end
			end, { desc = "Toggle Supermaven" })
		end,
	},
}
