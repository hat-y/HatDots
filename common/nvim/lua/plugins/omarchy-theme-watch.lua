-- On Omarchy only: lazy.nvim's own change detection doesn't fire when the
-- Omarchy theme changes, because plugins/theme.lua is no longer a symlink
-- into ~/.config/omarchy (it's a regular file that calls into
-- config.omarchy_theme at require time - see plugins/theme.lua). Without
-- this, `omarchy-theme-set` would update Ghostty and every other app but
-- leave Neovim's colors stale until the user manually restarts it.
--
-- This starts the fs-event watcher from config.omarchy_theme and reuses the
-- same `User LazyReload` autocmd that plugins/theme-hotreload.lua already
-- listens on, so the reload path is identical to a manual `:Lazy reload`.
local omarchy_theme = require("config.omarchy_theme")

return {
	{
		name = "omarchy-theme-watch",
		dir = vim.fn.stdpath("config"),
		lazy = false,
		priority = 1000,
		cond = omarchy_theme.is_omarchy,
		config = function()
			local handle = omarchy_theme.watch(function()
				vim.api.nvim_exec_autocmds("User", { pattern = "LazyReload" })
			end)

			if handle then
				vim.api.nvim_create_autocmd("VimLeavePre", {
					once = true,
					callback = function()
						handle.stop()
					end,
				})
			end
		end,
	},
}
