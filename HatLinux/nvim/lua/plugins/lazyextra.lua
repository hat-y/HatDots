return {
  -- Python extra con configuración personalizada
  {
    "LazyVim/LazyVim",
    opts = {
      -- Python settings
      python = {
        -- Configuración adicional para pyright si es necesaria
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
        },
      },
    },
  },

  -- TypeScript extra con configuración personalizada
  {
    "LazyVim/LazyVim",
    opts = {
      -- TypeScript settings
      typescript = {
        -- Configuración adicional para vtsls si es necesaria
        inlayHints = {
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = false },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
        suggest = { completeFunctionCalls = true },
        updateImportsOnFileMove = { enabled = "always" },
      },
      javascript = {
        inlayHints = {
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = false },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
        suggest = { completeFunctionCalls = true },
        updateImportsOnFileMove = { enabled = "always" },
      },
    },
  },
}