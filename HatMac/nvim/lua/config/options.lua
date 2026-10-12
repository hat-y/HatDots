-- macOS-specific Neovim options (HatMac)

-- Clipboard configuration for macOS
-- Prefer pbcopy/pbpaste (nativos). Fallback: reattach-to-user-namespace o cmd en PATH.
if vim.fn.executable("pbcopy") == 1 and vim.fn.executable("pbpaste") == 1 then
  vim.g.clipboard = {
    name = "pbcopy",
    copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
    paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
    cache_enabled = 0,
  }
elseif vim.fn.executable("reattach-to-user-namespace") == 1 then
  -- Para tmux en macOS, reattach-to-user-namespace expone el pasteboard
  vim.g.clipboard = {
    name = "reattach-to-user-namespace",
    copy = { ["+"] = "reattach-to-user-namespace pbcopy", ["*"] = "reattach-to-user-namespace pbcopy" },
    paste = { ["+"] = "reattach-to-user-namespace pbpaste", ["*"] = "reattach-to-user-namespace pbpaste" },
    cache_enabled = 0,
  }
end

vim.opt.clipboard = "unnamedplus"

-- Shell configuration for macOS (zsh por defecto en /bin/zsh)
if vim.fn.executable("zsh") == 1 then
  vim.opt.shell = "zsh"
elseif vim.fn.executable("bash") == 1 then
  vim.opt.shell = "bash"
end
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""
vim.opt.shellpipe = "2>&1 | tee %s"
vim.opt.shellredir = "> %s 2>&1"

-- HatDots: keep relative numbers off
vim.opt.relativenumber = false

-- Better performance settings
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.redrawtime = 1500

-- Disable unused features for better performance
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99

-- Better undo history
vim.opt.undofile = true
vim.opt.undolevels = 10000

-- Better search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- Better splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Better terminal integration
vim.opt.ttyfast = true
vim.opt.shortmess = "filnxtToO"

-- Startup performance
vim.opt.lazyredraw = false
vim.opt.synmaxcol = 240
