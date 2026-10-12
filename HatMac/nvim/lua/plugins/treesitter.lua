return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    cmd = { "TSInstall", "TSInstallSync", "TSUpdate", "TSUpdateSync", "TSUninstall" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "markdown", "markdown_inline",
        "bash", "html", "css", "javascript", "typescript", "json", "yaml", "toml",
        "python", "rust",
        "apex", "soql", "sosl", "sflog",
        -- visualforce: NO existe parser oficial en nvim-treesitter.
        -- Si lo necesitás, alias a html en after/ftplugin/visualforce.lua.
      },
      highlight = { enable = true },
      indent = { enable = true },
      -- Auto-instalar parsers faltantes al abrir un archivo del filetype.
      -- Default de nvim-treesitter es `true`; lo dejamos explícito para
      -- que apex/soql/sosl/sflog (y futuros) se bajen solos sin tener que
      -- correr `:TSInstall` a mano.
      auto_install = true,
    },
    config = function(_, opts)
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      -- Nota: en nvim-treesitter moderno (reescrito desde cero) no hay
      -- opción de parsers pre-compilados. SIEMPRE compila desde source.
      -- Por eso necesitás `tree-sitter` CLI instalada:
      --   npm install -g tree-sitter-cli
      -- (o `brew install tree-sitter-cli`).
      -- Sin la CLI, los parsers no se pueden compilar.
      require("nvim-treesitter.install").prefer_git = false  -- no-op, kept for clarity
      configs.setup(opts)
    end,
  },
  { "windwp/nvim-ts-autotag", ft = { "html", "xml", "javascriptreact", "typescriptreact" } },
}
