return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      compile = false,
      transparent = false,
      background = { dark = "dragon", light = "lotus" },
      theme = "dragon",
      overrides = function(colors)
        local p = colors.palette
        return {
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none", fg = p.sumiInk2 },
          Visual = { bg = p.waveBlue1 },
        }
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },
}

