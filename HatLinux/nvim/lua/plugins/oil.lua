return {
  "stevearc/oil.nvim",
  lazy = false,
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Oil: parent dir" },
    { "<leader>E", "<CMD>Oil --float<CR>", desc = "Oil: float" },
  },
  opts = {
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name) return name == ".." or name == ".git" end,
      natural_order = true,
      sort = { { "type", "asc" }, { "name", "asc" } },
    },
    keymaps = {
      ["q"] = "actions.close",
      ["<CR>"] = "actions.select",
      ["-"] = "actions.parent",
      ["g."] = "actions.toggle_hidden",
      ["<C-r>"] = "actions.refresh",
    },
    use_default_keymaps = false,
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
}
