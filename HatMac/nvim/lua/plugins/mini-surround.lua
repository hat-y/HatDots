return {
  {
    "nvim-mini/mini.surround",
    opts = {
      custom_surroundings = {
        b = {
          input = { '%*%*().-%*%*' },
          output = { left = '**', right = '**' },
        },
        i = {
          input = { '%*.-%*' },
          output = { left = '*', right = '*' },
        },
        l = {
          input = { '%[().-()%]%(.-%)' },
          output = function()
            local url = vim.fn.input("URL: ")
            return { left = '[', right = '](' .. url .. ')' }
          end,
        },
        c = {
          input = { '`().-()`' },
          output = { left = '`', right = '`' },
        },
        C = {
          input = { '```\n().-\n```' },
          output = { left = '```\n', right = '\n```' },
        },
      },
      mappings = {
        add = 'sa',
        delete = 'sd',
        find = 'sf',
        find_left = 'sF',
        highlight = 'sh',
        replace = 'sr',
        update_n_lines = 'sn',
      },
      n_lines = 50,
    },
  },
}
