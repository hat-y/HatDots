local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },

		-- Useful extras:
		{ import = "lazyvim.plugins.extras.lang.typescript" },
		{ import = "lazyvim.plugins.extras.lang.python" },
		{ import = "lazyvim.plugins.extras.lang.rust" },
		{ import = "lazyvim.plugins.extras.dap" },

		-- local plugins:
		{ import = "plugins" },
		{ "LazyVim/LazyVim", opts = { colorscheme = "kanagawa" } },

		-- Markdown enhancements
		{ import = "plugins.markdown-enhancements" },
	},
	defaults = { lazy = false, version = false },
	checker = { enabled = false },
	rocks = { enabled = false },
})
