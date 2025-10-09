return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = false, -- cargado siempre para evitar timings raros

	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim", -- picker recomendado
	},

	opts = {
		workspaces = {
			{ name = "HatNotes", path = "~/HatNotes" },
		},

		-- Compleción
		completion = {
			nvim_cmp = false, -- si usás blink.cmp, poné blink = true en vez de nvim_cmp
			min_chars = 2,
			create_new = true,
		},

		-- Templates & Dailies (tu estructura 0–7)
		templates = {
			folder = "7-Tmpl",
			date_format = "%Y-%m-%d-%a",
			time_format = "%H:%M",
		},
		daily_notes = {
			folder = "3-Logs",
			date_format = "%Y-%m-%d",
			template = "log-tmpl.md",
		},

		preferred_link_style = "wiki",
		picker = { name = "telescope.nvim" },

		-- Abrir URLs/imagenes en Windows
		follow_url_func = function(url)
			vim.fn.jobstart({ "cmd.exe", "/c", "start", "", url }, { detach = true })
		end,
		follow_img_func = function(img)
			vim.fn.jobstart({ "cmd.exe", "/c", "start", "", img }, { detach = true })
		end,

		sort_by = "modified",
		sort_reversed = true,
		open_notes_in = "current",

		-- Dejo vacío para que los mappings los pongamos nosotros vía autocmd (más robusto)
		mappings = {},
	},

	config = function(_, opts)
		-- Fallback si sacaste telescope por accidente
		if opts.picker and opts.picker.name == "telescope.nvim" then
			local ok = pcall(require, "telescope")
			if not ok then
				vim.notify("[obsidian] telescope no encontrado; usando mini.pick", vim.log.levels.WARN)
				opts.picker.name = "mini.pick"
			end
		end

		require("obsidian").setup(opts)

		vim.opt.conceallevel = 1

		-- ---- Mapeos buffer-locales SIEMPRE que el buffer sea markdown ----
		local function attach_obsidian_buf(bufnr)
			if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
				return
			end
			if vim.bo[bufnr].filetype ~= "markdown" then
				return
			end

			local ok, obs = pcall(require, "obsidian")
			if not ok then
				return
			end
			local util = obs.util

			-- gf “passthrough” oficial (README): si hay link → follow; si no → gf
			vim.keymap.set("n", "gf", function()
				return util.gf_passthrough()
			end, { buffer = bufnr, expr = true, noremap = false, silent = true, desc = "Obsidian follow (gf)" })

			-- Toggle checkbox (comando del plugin: es lo más robusto y no depende de UI extra)
			vim.keymap.set(
				"n",
				"<leader>ch",
				"<cmd>ObsidianToggleCheckbox<CR>",
				{ buffer = bufnr, silent = true, desc = "Obsidian: toggle checkbox" }
			)

			-- Enter inteligente (seguir link / togglear / etc.)
			vim.keymap.set("n", "<CR>", function()
				return util.smart_action()
			end, { buffer = bufnr, expr = true, silent = true, desc = "Obsidian smart action" })
		end

		-- Autocmds: cuando el buffer sea markdown o entres al buffer → attach
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(ev)
				attach_obsidian_buf(ev.buf)
			end,
		})
		vim.api.nvim_create_autocmd("BufEnter", {
			callback = function(ev)
				if vim.bo[ev.buf].filetype == "markdown" then
					attach_obsidian_buf(ev.buf)
				end
			end,
		})

		-- Attach inmediato por si ya estás en una nota
		vim.schedule(function()
			attach_obsidian_buf(vim.api.nvim_get_current_buf())
		end)
	end,

	-- Atajos útiles
	keys = {
		-- Comandos del plugin
		{ "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Abrir en Obsidian app" },
		{ "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Nueva nota" },
		{ "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick switch" },
		{ "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Buscar" },
		{ "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Insertar template" },
		{ "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Daily (hoy)" },
		{ "<leader>oD", "<cmd>ObsidianTomorrow<cr>", desc = "Daily (mañana)" },
		{ "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
		{ "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Links del buffer" },

		{
			"<leader>oO",
			function()
				vim.fn.jobstart({ "cmd.exe", "/c", "start", "", "obsidian://open" }, { detach = true })
			end,
			desc = "Forzar abrir Obsidian (obsidian://)",
		},
	},
}
