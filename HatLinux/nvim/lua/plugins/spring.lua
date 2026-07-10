-- Spring Boot tooling on top of LazyVim's Java (nvim-jdtls) setup.
-- Adds:
--   * completion + navigation for application.yml / application.properties
--   * Spring annotation & dependency hints
--   * bean / endpoint discovery via workspace symbols
--     (e.g. :Telescope lsp_workspace_symbols)
--   * Spring Code Actions

return {
  -- Auto-install the Spring Boot language server and the jdtls extension jars.
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "vscode-spring-boot-tools" } },
  },

  -- Spring Boot language server + commands.
  -- `config` is explicit: lazy.nvim only calls setup() when a `config` exists,
  -- and spring_boot.setup() is idempotent (it guards on `initialized`).
  --
  -- No hard dependency on nvim-jdtls here: spring_boot.setup() is defensive
  -- (pcall around require("jdtls")) and the jdtls wiring lives in the
  -- nvim-jdtls spec below, which depends on THIS plugin to guarantee load
  -- order (avoids a dependency cycle).
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    opts = {},
    config = function(_, opts)
      require("spring_boot").setup(opts)
    end,
  },

  -- Inject Spring Boot's jdtls extension jars into jdtls' bundles.
  -- LazyVim builds `init_options.bundles` (debug + test jars) internally and
  -- lets us extend the final jdtls config via `opts.jdtls` as a function
  -- (see LazyVim's `extend_or_override`). Using that hook avoids duplicating
  -- LazyVim's entire jdtls config, and merging the bundle *list* (which
  -- tbl_deep_extend would clobber by index).
  --
  -- `dependencies` forces spring-boot.nvim to load before nvim-jdtls, so
  -- require("spring_boot") is available on the first jdtls attach.
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    dependencies = { "JavaHello/spring-boot.nvim" },
    opts = function(_, opts)
      opts.jdtls = function(config)
        config.init_options = config.init_options or {}
        config.init_options.bundles = vim.list_extend(
          config.init_options.bundles or {},
          require("spring_boot").java_extensions()
        )
        return config -- explicit return: survives lazy.nvim changes to its fallback
      end
    end,
  },
}
