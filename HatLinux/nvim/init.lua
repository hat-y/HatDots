-- Platform detection
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and vim.fn.has("macunix") == 0

-- Set leader
vim.g.mapleader = " "

-- Clipboard (Linux-specific)
if is_linux then
  vim.opt.clipboard = "unnamedplus"
end

-- Load LazyVim
require("config.lazy")

-- Platform-specific config modules
if is_linux then
  -- Linux-specific configs
  pcall(function()
    require("config.python")
  end)
  pcall(function()
    require("config.python-lsp")
  end)
  pcall(function()
    require("config.keybinds")
  end)
  pcall(function()
    require("config.options")
  end)
elseif is_windows then
  -- Windows-specific configs
  pcall(function()
    require("config.obsidian_maps").setup_autocmd()
  end)
  pcall(function()
    require("config.dap")
  end)
end

-- Common configs (both platforms)
pcall(function()
  require("config.keymaps")
end)

-- Timeout configurations
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
