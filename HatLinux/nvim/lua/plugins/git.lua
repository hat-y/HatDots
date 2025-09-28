return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▎" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
      },
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
    },
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitConfig" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit (repo)" },
      { "<leader>gB", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (archivo)" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      vim.g.lazygit_floating_window_use_plenary = 1
    end,
  },
}

