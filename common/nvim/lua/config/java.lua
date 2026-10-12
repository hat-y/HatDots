-- Java (nvim-jdtls) tweaks layered on top of LazyVim's lang.java extra.
-- LazyVim already handles jdtls + lombok + dap + test runner; this file only
-- adds small Neovim-side adjustments.

-- Disable inlay hints: they error with jdtls on some Neovim builds.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("JavaLspSettings", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "jdtls" then
      client.server_capabilities.inlayHintProvider = nil
    end
  end,
})
