-- Shared LSP on_attach handler. Extracted from lua/plugins/lsp.lua so it can be
-- reused by other modules (e.g. salesforce/lsp.lua) without duplication.

local M = {}

function M.on_attach(client, bufnr)
  local map = function(mode, keys, func, desc)
    if desc then
      desc = "LSP: " .. desc
    end
    vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = desc })
  end

  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gr", vim.lsp.buf.references, "References")
  map("n", "gi", vim.lsp.buf.implementation, "Implementation")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
  map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")

  if client.name == "ruff" then
    client.server_capabilities.hoverProvider = false
  end
end

return M