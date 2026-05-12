return {
	-- Jupyter notebook integration with Rust backend and Kitty graphics
	-- No Python remote plugin needed — just cargo build + ipykernel
	-- Buffer-local keymaps are provided by the plugin (<leader>n prefix)
	{
		"sheng-tse/jupynvim",
		build = function()
			local core = vim.fn.stdpath("data") .. "/lazy/jupynvim/core"
			vim.fn.system({
				"cargo",
				"build",
				"--release",
				"--manifest-path",
				core .. "/Cargo.toml",
			})
		end,
		config = function()
			require("jupynvim").setup({
				log_level = "info",
				image_renderer = "placeholder", -- Kitty Unicode placeholder protocol (works with Ghostty)
			})
		end,
	},
}
