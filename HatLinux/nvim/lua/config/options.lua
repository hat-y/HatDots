-- Linux-specific Neovim options

-- Clipboard configuration for Linux
-- Use wl-copy/wl-paste for Wayland, xclip for X11
if vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1 then
  vim.g.clipboard = {
    name = "wl-clip",
    copy = { ["+"] = "wl-copy", ["*"] = "wl-copy" },
    paste = { ["+"] = "wl-paste", ["*"] = "wl-paste" },
    cache_enabled = 0,
  }
elseif vim.fn.executable("xclip") == 1 then
  vim.g.clipboard = {
    name = "xclip",
    copy = { ["+"] = "xclip -selection clipboard", ["*"] = "xclip -selection primary" },
    paste = { ["+"] = "xclip -selection clipboard -o", ["*"] = "xclip -selection primary -o" },
    cache_enabled = 0,
  }
elseif vim.fn.executable("xsel") == 1 then
  vim.g.clipboard = {
    name = "xsel",
    copy = { ["+"] = "xsel --clipboard --input", ["*"] = "xsel --primary --input" },
    paste = { ["+"] = "xsel --clipboard --output", ["*"] = "xsel --primary --output" },
    cache_enabled = 0,
  }
end

vim.opt.clipboard = "unnamedplus"

-- Shell configuration for Linux (zsh/bash)
if vim.fn.executable("zsh") == 1 then
  vim.opt.shell = "zsh"
else
  vim.opt.shell = "bash"
end
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""
vim.opt.shellpipe = "2>&1 | tee %s"
vim.opt.shellredir = "> %s 2>&1"

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

-- Kill inlay hints: bug en nvim 0.12.3 (issue #39772) causa
-- "Invalid 'col': out of range". Rehabilitar cuando se actualice a 0.13+.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("KillInlayHints", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
      client.server_capabilities.inlayHintProvider = false
    end
  end,
})
