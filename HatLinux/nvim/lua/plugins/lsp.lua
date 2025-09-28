return {
  { "mason-org/mason.nvim", config = true },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "neovim/nvim-lspconfig", "mason-org/mason.nvim" },
    opts = {
      ensure_installed = { "lua_ls", "ts_ls", "pyright", "rust_analyzer" },
    },
    config = function(_, opts)
      require("mason").setup()
      require("mason-lspconfig").setup(opts)

      -- capabilities (cmp opcional)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then capabilities = cmp.default_capabilities(capabilities) end

      local function on_attach(_, bufnr)
        local map = function(m, lhs, rhs, desc)
          vim.keymap.set(m, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "gd", vim.lsp.buf.definition, "Goto Def")
        map("n", "gr", vim.lsp.buf.references, "References")
        map("n", "K", vim.lsp.buf.hover, "Hover")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "[d", vim.diagnostic.goto_prev, "Prev Diag")
        map("n", "]d", vim.diagnostic.goto_next, "Next Diag")
      end

      if vim.lsp.config and vim.lsp.enable then
        -- Neovim ≥ 0.11
        vim.lsp.config("lua_ls", {
          on_attach = on_attach,
          capabilities = capabilities,
          settings = { Lua = { diagnostics = { globals = { "vim" } } } },
        })
        vim.lsp.config("ts_ls", { on_attach = on_attach, capabilities = capabilities })
        vim.lsp.config("pyright", { on_attach = on_attach, capabilities = capabilities })
        vim.lsp.config("rust_analyzer", { on_attach = on_attach, capabilities = capabilities })
        vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "rust_analyzer" })
      else
        -- Neovim 0.10 (lspconfig)
        local lsp = require("lspconfig")
        lsp.lua_ls.setup({
          on_attach = on_attach,
          capabilities = capabilities,
          settings = { Lua = { diagnostics = { globals = { "vim" } } } },
        })
        if lsp.ts_ls then
          lsp.ts_ls.setup({ on_attach = on_attach, capabilities = capabilities })
        else
          lsp.tsserver.setup({ on_attach = on_attach, capabilities = capabilities }) -- fallback
        end
        lsp.pyright.setup({ on_attach = on_attach, capabilities = capabilities })
        lsp.rust_analyzer.setup({ on_attach = on_attach, capabilities = capabilities })
      end
    end,
  },
}
