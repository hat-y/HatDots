return {
  -- Disable inlay hints: bug en nvim 0.12.3 (issue #39772) causa
  -- "Invalid 'col': out of range" en nvim_buf_set_extmark cuando se edita
  -- el buffer. Se puede rehabilitar cuando se actualice a 0.13.
  {
    "LazyVim/LazyVim",
    opts = {
      inlay_hints = {
        enabled = false,
        exclude = {},
      },
    },
  },

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