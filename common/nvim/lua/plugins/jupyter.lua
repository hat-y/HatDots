return {
	-- Jupyter notebook integration with Rust backend and Kitty graphics
	-- No Python remote plugin needed — just cargo build + ipykernel
	-- Buffer-local keymaps are provided by the plugin (<leader>n prefix)
	{
		"sheng-tse/jupynvim",
		build = function()
			local core_dir = vim.fn.stdpath("data") .. "/lazy/jupynvim/core"
			local binary = core_dir .. "/target/release/jupynvim-core"

			-- Skip build if binary already exists
			if vim.fn.executable(binary) == 1 then
				vim.notify("jupynvim-core already built, skipping cargo build", vim.log.levels.INFO)
				return
			end

			-- Check cargo availability
			if vim.fn.executable("cargo") == 0 then
				vim.notify(
					"jupynvim: 'cargo' not found in PATH — cannot build jupynvim-core. "
						.. "Install Rust (https://rustup.rs) and restart Neovim.",
					vim.log.levels.ERROR
				)
				return
			end

			local result = vim.fn.systemlist({
				"cargo", "build", "--release",
				"--manifest-path", core_dir .. "/Cargo.toml",
			})
			if vim.v.shell_error ~= 0 then
				local msg = table.concat(result, "\n"):sub(1, 500)
				vim.notify(
					"jupynvim: cargo build failed (shell_error=" .. vim.v.shell_error .. ")\n" .. msg,
					vim.log.levels.ERROR
				)
			else
				vim.notify("jupynvim-core built successfully", vim.log.levels.INFO)
			end
		end,
		config = function()
			require("jupynvim").setup({
				log_level = "info",
				image_renderer = "placeholder", -- Kitty Unicode placeholder protocol (works with Ghostty)
			})
		end,
	},
}
