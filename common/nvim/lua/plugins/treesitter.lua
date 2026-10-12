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
        "python", "rust", "java", "tsx",
        "apex", "soql", "sosl", "sflog", -- Salesforce (xixiaofinland/sf.nvim)
        -- visualforce: no official nvim-treesitter parser. Alias to html in
        -- after/ftplugin/visualforce.lua if you need it.
      },
      highlight = { enable = true },
      indent = { enable = true },
      -- Auto-install missing parsers (apex/soql/sosl/sflog and future ones)
      -- without having to run `:TSInstall` by hand.
      auto_install = true,
    },
    config = function(_, opts)
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      require("nvim-treesitter.install").prefer_git = true
      configs.setup(opts)
    end,
  },
  { "windwp/nvim-ts-autotag", ft = { "html", "xml", "javascriptreact", "typescriptreact" } },
}
