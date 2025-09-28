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
      },
      highlight = { enable = true },
      indent = { enable = true },
      auto_install = false,
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
