local config_path = vim.uv.fs_realpath(vim.fn.stdpath("config"))
if not config_path then
  error("HatDots shared Neovim runtimepath: cannot resolve stdpath('config')")
end
local repo_root = vim.fs.dirname(vim.fs.dirname(config_path))
vim.opt.runtimepath:append(vim.fs.joinpath(repo_root, "shared", "nvim"))

-- Carga config y arranca Lazy
require("config.lazy")
require("config.obsidian_maps").setup_autocmd()

vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
