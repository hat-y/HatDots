return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make", -- en Arch suele compilar sin drama
      },
    },
    opts = {
      defaults = {
        mappings = {
          i = { ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" },
        },
        file_ignore_patterns = { "%.git/", "node_modules/", "target/", "venv/" },
      },
      pickers = { find_files = { hidden = true } },
    },
    config = function(_, opts)
      local t = require("telescope")
      t.setup(opts)
      pcall(t.load_extension, "fzf")
      -- atajos
      local map = vim.keymap.set
      map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Files" })
      map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Grep" })
      map("n", "<leader>fb", "<cmd>Telescope buffers<cr>",    { desc = "Buffers" })
      map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>",  { desc = "Help" })
    end,
  },
}

