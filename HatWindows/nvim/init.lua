-- Carga config y arranca Lazy
require("config.lazy")
require("config.obsidian_maps").setup_autocmd()

vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
