-- Cross-platform Neovim options.
-- Clipboard and shell are OS-specific and self-guarded with vim.fn.has(...);
-- everything below that is a generic editor setting that applies everywhere.

local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_mac = vim.fn.has("macunix") == 1

if is_win then
  -- Windows clipboard: win32yank via scoop if present, else PowerShell.
  local home = vim.fn.expand("~")
  local scoop_shim = home .. "\\scoop\\shims\\win32yank.exe"
  local scoop_app = home .. "\\scoop\\apps\\win32yank\\current\\win32yank.exe"
  local function exists(p)
    return (vim.uv or vim.loop).fs_stat(p) ~= nil
  end

  if exists(scoop_shim) or exists(scoop_app) then
    local yank = exists(scoop_shim) and scoop_shim or scoop_app
    vim.g.clipboard = {
      name = "win32yank (scoop)",
      copy = { ["+"] = yank .. " -i --crlf", ["*"] = yank .. " -i --crlf" },
      paste = { ["+"] = yank .. " -o --lf", ["*"] = yank .. " -o --lf" },
      cache_enabled = 0,
    }
  else
    vim.g.clipboard = {
      name = "powershell-clipboard",
      copy = {
        ["+"] = "powershell -NoProfile -Command Set-Clipboard",
        ["*"] = "powershell -NoProfile -Command Set-Clipboard",
      },
      paste = {
        ["+"] = "powershell -NoProfile -Command Get-Clipboard",
        ["*"] = "powershell -NoProfile -Command Get-Clipboard",
      },
      cache_enabled = 0,
    }
  end
elseif is_mac then
  -- macOS clipboard: pbcopy/pbpaste, falling back to reattach-to-user-namespace
  -- (needed inside tmux on older macOS/tmux combinations).
  if vim.fn.executable("pbcopy") == 1 and vim.fn.executable("pbpaste") == 1 then
    vim.g.clipboard = {
      name = "pbcopy",
      copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
      paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
      cache_enabled = 0,
    }
  elseif vim.fn.executable("reattach-to-user-namespace") == 1 then
    vim.g.clipboard = {
      name = "reattach-to-user-namespace",
      copy = {
        ["+"] = "reattach-to-user-namespace pbcopy",
        ["*"] = "reattach-to-user-namespace pbcopy",
      },
      paste = {
        ["+"] = "reattach-to-user-namespace pbpaste",
        ["*"] = "reattach-to-user-namespace pbpaste",
      },
      cache_enabled = 0,
    }
  end
else
  -- Linux clipboard: wl-copy/wl-paste for Wayland, xclip/xsel for X11.
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
end

vim.opt.clipboard = "unnamedplus"

-- Shell configuration. Windows keeps Neovim's own default shell (cmd/pwsh);
-- Linux and macOS prefer zsh, falling back to bash.
if not is_win then
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
end

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
