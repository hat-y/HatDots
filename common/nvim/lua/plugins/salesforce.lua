-- salesforce.lua — lazy plugin spec.
-- toggleterm is declared as a dependency so lazy.nvim tracks it.
-- The Salesforce integration itself is a local module (lua/salesforce/) that
-- auto-initializes via autocmds registered in salesforce/init.lua.

return {
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm" },
    -- Triggered on the FIRST BufReadPre (any file) so the Salesforce module
    -- is loaded before any .cls/.trigger/.apex file is opened. The init
    -- callback pulls in salesforce, which registers its own BufReadPre
    -- autocmd scoped to Apex files.
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    init = function()
      -- Trigger salesforce module load. This runs the top-level of
      -- lua/salesforce/init.lua which registers the BufReadPre *.cls
      -- autocmd and the SfSalesforceReady event.
      pcall(require, "salesforce")
    end,
    opts = {
      -- LazyVim-style toggleterm defaults; the Salesforce module wraps it.
      size = 20,
      open_mapping = nil, -- LazyVim keymaps.lua binds <leader>tt/<leader>tn already
      shade_filetypes = {},
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
    end,
  },
}