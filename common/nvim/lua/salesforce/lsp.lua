-- salesforce.lsp — apex-ls setup.
-- Resolves apex-ls JAR via globpath over well-known candidate locations,
-- then calls require('lspconfig').apex_ls.setup({...}).
-- Linux-only.

local M = {}
local util = require("salesforce.util")
local health = require("salesforce.health")

local function resolve_apex_ls_jar()
  -- Allow override
  if vim.g.sf_apex_ls_path and vim.uv.fs_stat(vim.g.sf_apex_ls_path) then
    return vim.g.sf_apex_ls_path
  end

  local candidates = {
    vim.fn.expand("~/.local/share/sf/client/plugins/apex"),
    vim.fn.expand("~/Library/Caches/sf/client/plugins/apex"),
    vim.fn.expand("~/.cache/sf/client/plugins/apex"),
  }

  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then
      local matches = vim.fn.globpath(dir, "apex-ls*.jar", false, true)
      if matches and #matches > 0 then
        return matches[1]
      end
    end
  end
  return nil
end

function M.setup()
  if vim.fn.has("linux") ~= 1 then
    return
  end

  local s = health.check()
  if not s.sf then
    util.notify("warn", "apex-ls: sf CLI not on PATH; skipping LSP setup")
    return
  end
  if not s.apex_ls then
    util.notify(
      "warn",
      "apex-ls: Salesforce CLI plugin not installed. Run: sf plugins install apex"
    )
    return
  end

  local jar = resolve_apex_ls_jar()
  if not jar then
    util.notify(
      "warn",
      "apex-ls: JAR not found. Set vim.g.sf_apex_ls_path manually or run `sf plugins install apex` and check ~/.local/share/sf/client/plugins/apex/"
    )
    return
  end

  local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
  if not ok_lspconfig then
    util.notify("warn", "apex-ls: nvim-lspconfig not loaded")
    return
  end

  local ok_attach, attach = pcall(require, "config.lsp_on_attach")
  if not ok_attach then
    util.notify("warn", "apex-ls: config.lsp_on_attach not available; using empty on_attach")
    attach = { on_attach = function() end }
  end

  lspconfig.apex_ls.setup({
    cmd = { "java", "-jar", jar },
    filetypes = { "apex" },
    on_attach = attach.on_attach,
  })

  vim.g.sf_apex_ls_version = "resolved-at-" .. os.date("%Y-%m-%d")
end

return M