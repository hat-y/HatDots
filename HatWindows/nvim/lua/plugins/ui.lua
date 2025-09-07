-- Modo compacto para lualine
local mode = {
	"mode",
	fmt = function(s)
		local m = {
			["NORMAL"] = "N",
			["O-PENDING"] = "N?",
			["INSERT"] = "I",
			["VISUAL"] = "V",
			["V-BLOCK"] = "VB",
			["V-LINE"] = "VL",
			["V-REPLACE"] = "VR",
			["REPLACE"] = "R",
			["COMMAND"] = "!",
			["SHELL"] = "SH",
			["TERMINAL"] = "T",
			["EX"] = "X",
			["S-BLOCK"] = "SB",
			["S-LINE"] = "SL",
			["SELECT"] = "S",
			["CONFIRM"] = "Y?",
			["MORE"] = "M",
		}
		return m[s] or s
	end,
}

return {
	{ "folke/todo-comments.nvim", version = "*" },

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = { preset = "classic", win = { border = "single" } },
	},

	{
		"amrbashir/nvim-docs-view",
		lazy = true,
		cmd = "DocsViewToggle",
		opts = { position = "right", width = 60 },
	},

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = { theme = "kanagawa", icons_enabled = true },
			sections = {
				lualine_a = {
					{ "mode", icon = "ރ" },
				},
			},
			extensions = {
				"quickfix",
				{
					filetypes = { "oil" },
					sections = {
						lualine_a = { mode },
						lualine_b = {
							function()
								local ok, oil = pcall(require, "oil")
								if not ok then
									return ""
								end
								local path = vim.fn.fnamemodify(oil.get_current_dir(), ":~")
								return path .. " %m"
							end,
						},
					},
				},
			},
		},
	},

	{
		"b0o/incline.nvim",
		event = "BufReadPre",
		priority = 1200,
		config = function()
			require("incline").setup({
				window = { margin = { vertical = 0, horizontal = 1 } },
				hide = { cursorline = true },
				render = function(props)
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
					if vim.bo[props.buf].modified then
						filename = "[+] " .. filename
					end
					local icon, color = require("nvim-web-devicons").get_icon_color(filename)
					return { { icon, guifg = color }, { " " }, { filename } }
				end,
			})
		end,
	},

	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		opts = {
			plugins = {
				gitsigns = true,
				tmux = true,
				kitty = { enabled = false, font = "+2" },
				twilight = { enabled = true },
			},
		},
		keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
	},

	{
		"folke/snacks.nvim",
		opts = {
			notifier = {},
			image = {},
			picker = {
				matcher = {
					fuzzy = true,
					smartcase = true,
					ignorecase = true,
					filename_bonus = true,
				},
				sources = {
					explorer = {
						matcher = {
							fuzzy = true,
							smartcase = true,
							ignorecase = true,
							filename_bonus = true,
							sort_empty = false,
						},
					},
				},
			},
			dashboard = {
				sections = {
					{ section = "header" },
					{ icon = " ", title = "Keymaps", section = "keys", color = "#E6C384", indent = 2, padding = 1 },
					{
						icon = " ",
						title = "Recent Files",
						section = "recent_files",
						color = "#7E9CD8",
						indent = 2,
						padding = 1,
					},
					{
						icon = " ",
						title = "Projects",
						section = "projects",
						color = "#98BB6C",
						indent = 2,
						padding = 1,
					},
					{
						pane = 2,
						icon = " ",
						title = "Git Status",
						section = "terminal",
						color = "#FFA066",
						enabled = function()
							return require("snacks.git").get_root() ~= nil
						end,
						cmd = "git status --short --branch --renames",
						height = 7,
						padding = 1,
						ttl = 300,
						indent = 3,
					},
					{ section = "startup" },
				},
				preset = {
					header = [[
 ██░ ██  ▄▄▄      ▄▄▄█████▓
▓██░ ██▒▒████▄    ▓  ██▒ ▓▒
▒██▀▀██░▒██  ▀█▄  ▒ ▓██░ ▒░
░▓█ ░██ ░██▄▄▄▄██ ░ ▓██▓ ░
░▓█▒░██▓ ▓█   ▓██▒  ▒██▒ ░
 ▒ ░░▒░▒ ▒▒   ▓▒█░  ▒ ░░
 ▒ ░▒░ ░  ▒   ▒▒ ░    ░
 ░  ░░ ░  ░   ▒     ░
 ░  ░  ░      ░  ░
]],
					keys = {
						{
							icon = " ",
							key = "f",
							desc = "Find File",
							action = ":lua Snacks.dashboard.pick('files')",
						},
						{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
						{
							icon = " ",
							key = "g",
							desc = "Find Text",
							action = ":lua Snacks.dashboard.pick('live_grep')",
						},
						{
							icon = " ",
							key = "r",
							desc = "Recent Files",
							action = ":lua Snacks.dashboard.pick('oldfiles')",
						},
						{
							icon = " ",
							key = "c",
							desc = "Config",
							action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
						},
						{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
						{ icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
						{ icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
						{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
					},
				},
			},
		},
	},
}
