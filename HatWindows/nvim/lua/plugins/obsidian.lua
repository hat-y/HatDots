return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",

	-- Carga por COMANDOS y cuando abras .md dentro de HatNotes
	cmd = {
		"ObsidianOpen",
		"ObsidianNew",
		"ObsidianQuickSwitch",
		"ObsidianSearch",
		"ObsidianTemplate",
		"ObsidianToday",
		"ObsidianTomorrow",
		"ObsidianDailies",
	},
	event = {
		"BufReadPre " .. vim.fn.expand("~") .. "/HatNotes/**/*.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/HatNotes/**/*.md",
	},

	dependencies = {
		"nvim-lua/plenary.nvim",
		-- "nvim-telescope/telescope.nvim",
	},

	opts = {
		workspaces = {
			{ name = "HatNotes", path = "~/HatNotes" },
		},

		-- Usa el motor de autocompletado que venís usando
		completion = { nvim_cmp = true },

		-- Picker estable sin deps extra
		picker = { name = "snacks.pick" },

		-- Dailies y templates según tu estructura 0–7
		daily_notes = {
			folder = "3-Logs",
			template = "log-tmpl.md",
		},

		templates = {
			folder = "7-Tmpl",
			date_format = "%Y-%m-%d-%a",
			time_format = "%H:%M",
		},

		preferred_link_style = "wiki",
		open_app_foreground = true,
	},

	config = function(_, opts)
		if opts.picker and opts.picker.name == "telescope.nvim" then
			local ok = pcall(require, "telescope.builtin")
			if not ok then
				vim.notify("[obsidian] Telescope no disponible; usando mini.pick", vim.log.levels.WARN)
				opts.picker.name = "mini.pick"
			end
		end

		require("obsidian").setup(opts)

		-- Keymaps buffer-local en Markdown (reemplaza 'mappings' deprecado)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(ev)
				local buf = ev.buf
				local util = require("obsidian").util

				-- gf: seguir link (si no aplica, hace passthrough normal)
				vim.keymap.set("n", "gf", function()
					return util.gf_passthrough()
				end, { buffer = buf, expr = true, desc = "Obsidian: goto link (gf)" })

				-- Enter inteligente: link/tag/checkbox/fold
				vim.keymap.set("n", "<CR>", function()
					return util.smart_action()
				end, { buffer = buf, expr = true, desc = "Obsidian: smart action" })

				-- Checkbox toggle
				vim.keymap.set(
					"n",
					"<leader>ch",
					util.toggle_checkbox,
					{ buffer = buf, desc = "Obsidian: toggle checkbox" }
				)
			end,
		})
	end,

	keys = {
		{ "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: abrir app" },
		{ "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: nueva nota" },
		{ "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: quick switch" },
		{ "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: buscar" },
		{ "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Obsidian: insertar template" },
		{ "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Obsidian: daily (hoy)" },
		{ "<leader>oD", "<cmd>ObsidianTomorrow<cr>", desc = "Obsidian: daily (mañana)" },
	},
}
