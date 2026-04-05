-- Platform detection
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_linux = vim.fn.has("unix") == 1 and vim.fn.has("macunix") == 0
local is_mac = vim.fn.has("macunix") == 1

-- Set leader
vim.g.mapleader = " "

-- Load LazyVim
require("config.lazy")

-- Platform-specific config modules
if is_linux then
  -- Linux-specific configs
  require("config.options")       -- Linux clipboard & shell
  require("config.python")        -- Python + uv
  require("config.python-lsp")    -- Python LSP config
  require("config.keybinds")      -- Linux keybinds
elseif is_windows then
  -- Windows-specific configs
  require("config.options")       -- Windows clipboard & shell
  require("config.obsidian_maps").setup_autocmd()
  require("config.dap")
end

-- Common configs (both platforms)
pcall(require, "config.keymaps")

-- Timeout configurations
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
