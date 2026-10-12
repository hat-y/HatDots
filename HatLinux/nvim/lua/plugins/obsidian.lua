local creation = require("hatnotes.creation")
local vault_path = creation.vault_path

return {
	"epwalsh/obsidian.nvim",
	version = "*",
	ft = "markdown", -- Load only for markdown files

	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim", -- recommended picker
	},

	opts = {
		workspaces = {
			{
				name = "HatNotes",
				path = vault_path,
				overrides = {
					-- Performance limits for this specific workspace
					search_max_lines = 1000,
				},
			},
		},

		-- Completion settings
		completion = {
			nvim_cmp = false, -- if you use blink.cmp, put blink = true instead of nvim_cmp
			min_chars = 2,
			create_new = true,
		},

		-- Templates & Dailies (0-7 structure)
		templates = {
			folder = "7-Tmpl",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",

			-- Custom substitutions for better template functionality
			substitutions = {
				yesterday = function()
					return os.date("%Y-%m-%d", os.time() - 86400)
				end,
				tomorrow = function()
					return os.date("%Y-%m-%d", os.time() + 86400)
				end,
				current_day_name = function()
					local days = {"domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"}
					return days[os.date("%w")]
				end,
				underscored_date = function()
					return os.date("%Y_%m_%d")
				end,
			},
		},
		daily_notes = {
			folder = "3-Logs",
			date_format = "%Y-%m-%d",
			template = "log-tmpl.md",
		},

		preferred_link_style = "wiki",
		picker = { name = "telescope.nvim" },

		-- Link handling and formatting
		wiki_link_func = function(opts)
			return require("obsidian.util").wiki_link_id_prefix(opts)
		end,
		file_extension = "md",

		-- Open URLs/images on Linux (xdg-open)
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url }, { detach = true })
		end,
		follow_img_func = function(img)
			vim.fn.jobstart({ "xdg-open", img }, { detach = true })
		end,

		sort_by = "modified",
		sort_reversed = true,
		open_notes_in = "current",

		-- Performance optimizations
		ui = {
			enable = true,
			update_debounce = 200,
			max_file_length = 5000,
		},

		-- Event callbacks for enhanced functionality
		callbacks = {
			enter_note = function(note)
				-- Custom logic when entering a note can go here
				-- Example: Auto-add tags, set metadata, etc.
			end,
		},

		-- Leave empty to place mappings ourselves via autocmd (more robust)
		mappings = {},
	},

	config = function(_, opts)
		creation.preflight()

		-- Fallback if you accidentally removed telescope
		if opts.picker and opts.picker.name == "telescope.nvim" then
			local ok = pcall(require, "telescope")
			if not ok then
				vim.notify("[obsidian] telescope not found; using mini.pick", vim.log.levels.WARN)
				opts.picker.name = "mini.pick"
			end
		end

		require("obsidian").setup(opts)

		vim.opt.conceallevel = 1

		-- Spell check for markdown files - add hunspell path to runtimepath
		vim.opt.runtimepath:prepend("/usr/share/hunspell")
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function()
				vim.opt_local.spell = true
				vim.opt_local.spelllang = "es,en"
			end,
		})

		-- Line wrapping for markdown files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function()
				vim.opt_local.wrap = true
				vim.opt_local.linebreak = true
				vim.opt_local.textwidth = 80
			end,
		})

		-- Buffer-local mappings when buffer is markdown
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

			-- gf "passthrough" official: if link exists -> follow; if not -> gf
			vim.keymap.set("n", "gf", function()
				return util.gf_passthrough()
			end, { buffer = bufnr, expr = true, noremap = false, silent = true, desc = "Obsidian follow (gf)" })

			-- Toggle checkbox
			vim.keymap.set(
				"n",
				"<leader>ch",
				"<cmd>ObsidianToggleCheckbox<cr>",
				{ buffer = bufnr, silent = true, desc = "Obsidian: toggle checkbox" }
			)

			-- Smart enter (follow link / toggle etc)
			vim.keymap.set("n", "<CR>", function()
				return util.smart_action()
			end, { buffer = bufnr, expr = true, silent = true, desc = "Obsidian smart action" })

			-- Quick spell check correction (first suggestion)
			vim.keymap.set("i", "<leader>sz", "<cmd>norm! z=iai<cr>", { buffer = bufnr, silent = true, desc = "Accept first spell suggestion" })

			-- Quick add word to dictionary
			vim.keymap.set("i", "zg", "<cmd>norm! zg<cr>", { buffer = bufnr, silent = true, desc = "Add word to dictionary" })

			-- Quick mark word as wrong
			vim.keymap.set("i", "zw", "<cmd>norm! zw<cr>", { buffer = bufnr, silent = true, desc = "Mark word as wrong" })
		end

		-- Autocmd: when buffer is markdown or enter buffer -> attach
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(ev)
				attach_obsidian_buf(ev.buf)
			end,
		})

		-- Immediate attach in case you're already in a note
		vim.schedule(function()
			attach_obsidian_buf(vim.api.nvim_get_current_buf())
		end)
	end,

	-- Useful shortcuts
	keys = vim.list_extend({
		-- Plugin commands
		{ "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian app" },
		{ "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
		{ "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick switch" },
		{ "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search" },
		{ "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Insert template" },

		{ "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
		{ "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Buffer links" },
		{ "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename note" },
		{ "<leader>olT", "<cmd>ObsidianTemplate log-tmpl<cr>", desc = "Insert log template" },


		-- Libro / Lectura commands
		{
			"<leader>oll",
			function()
				-- Use fixed path instead of obsidian client
				local books_path = vault_path .. "/6-Ref/Libros"

				local handle = vim.loop.fs_scandir(books_path)
				if not handle then
					vim.notify("No hay libros en 6-Ref/Libros. Usa <leader>oln primero", vim.log.levels.WARN)
					return
				end

				local books = {}
				while true do
					local name, typ = vim.loop.fs_scandir_next(handle)
					if not name then
						break
					end
					if typ == "directory" then
						table.insert(books, name)
					end
				end

				if #books == 0 then
					vim.notify("No hay libros creados", vim.log.levels.WARN)
					return
				end

				vim.ui.select(books, { prompt = "Abrir libro:" }, function(book)
					if book then
						local meta_path = books_path .. "/" .. book .. "/metadata.md"
						vim.cmd("e " .. meta_path)
					end
				end)
			end,
			desc = "Abrir libro (seleccionar)",
		},
		{
			"<leader>olq",
			function()
				-- Use fixed path
				local books_path = vault_path .. "/6-Ref/Libros"

				local handle = vim.loop.fs_scandir(books_path)
				if not handle then
					vim.notify("No hay libros en 6-Ref/Libros", vim.log.levels.WARN)
					return
				end

				local books = {}
				while true do
					local name, typ = vim.loop.fs_scandir_next(handle)
					if not name then
						break
					end
					if typ == "directory" then
						table.insert(books, name)
					end
				end

				if #books == 0 then
					vim.notify("No hay libros creados", vim.log.levels.WARN)
					return
				end

				vim.ui.select(books, { prompt = "Crear cuestionario para:" }, function(book)
					if not book then
						return
					end

					local book_path = books_path .. "/" .. book
					local session_handle = vim.loop.fs_scandir(book_path)
					if not session_handle then
						vim.notify("No hay sesiones", vim.log.levels.WARN)
						return
					end

					-- Collect all sessions
					local sessions = {}
					while true do
						local entry_name, entry_typ = vim.loop.fs_scandir_next(session_handle)
						if not entry_name then
							break
						end
						if entry_typ == "file" and entry_name:match("^sesion %d+%.md$") then
							table.insert(sessions, entry_name)
						end
					end

					if #sessions == 0 then
						vim.notify("No hay sesiones creadas", vim.log.levels.WARN)
						return
					end

					-- Sort sessions by number
					table.sort(sessions, function(a, b)
						local num_a = tonumber(a:match("sesion (%d+)"))
						local num_b = tonumber(b:match("sesion (%d+)"))
						return num_a < num_b
					end)

					-- Read each session and extract questions
					local questions = {}
					for _, sess_name in ipairs(sessions) do
						local sess_path = book_path .. "/" .. sess_name
						local lines = vim.fn.readfile(sess_path)
						local session_num = sess_name:match("sesion (%d+)")

						local in_pre = false
						local in_post = false

						for _, line in ipairs(lines) do
							if line:match("^## PRE%-PREGUNTAS") then
								in_pre = true
								in_post = false
							elseif line:match("^## POST%-PREGUNTAS") then
								in_pre = false
								in_post = true
							elseif line:match("^## BRAIN DUMP") then
								in_pre = false
								in_post = false
							elseif in_pre or in_post then
								-- Look for numbered questions
								local q = line:match("^%d+%. (.+)")
								if q and q ~= "" and not q:match("^%-") then
									table.insert(questions, {
										session = session_num,
										question = q,
										answer = "",
										section = in_pre and "pre" or "post"
									})
								end
							end
						end
					end

					if #questions == 0 then
						vim.notify("No encontré preguntas en las sesiones", vim.log.levels.WARN)
						return
					end

					-- Build questionnaire content
					local date = os.date("%Y-%m-%d")
					local content = string.format([[---
tipo: Cuestionario
libro: %s
sesiones: %d
creado: %s
---

# Cuestionario: %s

## Repaso

]], book, #sessions, date, book)

					for i, q in ipairs(questions) do
						content = content .. string.format([[### %d. (%s)
**Pregunta**: %s

**Respuesta**: 


---
]], i, q.section == "pre" and "pre-lectura" or "post-lectura", q.question)
					end

					content = content .. string.format([[
## Notas para futuro recuerdo

| Cuándo | Qué revisar |
|--------|-------------|
| Mañana | |
| En 3 días | |
| En 1 semana | |
| En 1 mes | |
]])

					-- Write questionnaire file
					local questionnaire_path = book_path .. "/cuestionario.md"
					vim.fn.writefile(vim.split(content, "\n"), questionnaire_path)
					vim.cmd("e " .. questionnaire_path)
				end)
			end,
			desc = "Crear cuestionario desde sesiones",
		},

		{
			"<leader>oO",
			function()
				vim.fn.jobstart({ "xdg-open", "obsidian://open" }, { detach = true })
			end,
			desc = "Forzar abrir Obsidian (obsidian://)",
		},
		{
			"<leader>oQ",
			function()
				local obs = require("obsidian")
				local client = obs.get_client()
				local today = os.date("%Y-%m-%d")
				local note = client:today()
				if note then
					vim.cmd("e " .. note.path)
					vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
					vim.cmd("startinsert")
				else
					vim.cmd("ObsidianToday")
					vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
					vim.cmd("startinsert")
				end
			end,
			desc = "Quick create/open today's log",
		},

		{
			"<leader>omi",
			function()
				local indice_path = vault_path .. "/4-Projs/Materias/_indice.md"
				if vim.fn.filereadable(indice_path) == 0 then
					vim.notify("No existe el índice. Usa <leader>omn primero", vim.log.levels.WARN)
					return
				end
				vim.cmd("e " .. indice_path)
			end,
			desc = "Abrir índice de materias",
		},
		{
			"<leader>omm",
			function()
				local materias_path = vault_path .. "/4-Projs/Materias"

				local handle = vim.loop.fs_scandir(materias_path)
				if not handle then
					vim.notify("No hay materias. Usa <leader>omn primero", vim.log.levels.WARN)
					return
				end

				local materias = {}
				local slug_to_name = {}
				while true do
					local name, typ = vim.loop.fs_scandir_next(handle)
					if not name then
						break
					end
					if typ == "directory" and name ~= "_indice.md" then
						local materia_file = materias_path .. "/" .. name .. "/materia.md"
						local pretty_name = name
						if vim.fn.filereadable(materia_file) == 1 then
							local lines = vim.fn.readfile(materia_file)
							for _, line in ipairs(lines) do
								local n = line:match("^nombre:%s*(.+)$")
								if n then
									pretty_name = n
									break
								end
							end
						end
						table.insert(materias, pretty_name)
						slug_to_name[pretty_name] = name
					end
				end

				if #materias == 0 then
					vim.notify("No hay materias creadas. Usa <leader>omn", vim.log.levels.WARN)
					return
				end

				vim.ui.select(materias, { prompt = "Abrir material de:" }, function(pretty_name)
					if not pretty_name then
						return
					end
					local slug = slug_to_name[pretty_name]
					local material_path = materias_path .. "/" .. slug .. "/material"
					vim.fn.mkdir(material_path, "p")
					-- Open material folder in terminal file manager or telescope
					local pickers = require("telescope.pickers")
					local finders = require("telescope.finders")
					local conf = require("telescope.config").values
					local actions = require("telescope.actions")
					local action_state = require("telescope.actions.state")

					local files = {}
					local mat_handle = vim.loop.fs_scandir(material_path)
					if mat_handle then
						while true do
							local f_name, f_type = vim.loop.fs_scandir_next(mat_handle)
							if not f_name then
								break
							end
							if f_type == "file" then
								table.insert(files, { name = f_name, path = material_path .. "/" .. f_name })
							end
						end
					end
					table.sort(files, function(a, b) return a.name < b.name end)

					if #files == 0 then
						vim.notify("Sin PDFs aún. Agregá archivos a: " .. material_path, vim.log.levels.INFO)
						return
					end

					pickers
						.new({}, {
							prompt_title = "Material: " .. pretty_name,
							finder = finders.new_table({
								results = files,
								entry_maker = function(entry)
									return {
										value = entry.path,
										display = entry.name,
										ordinal = entry.name,
									}
								end,
							}),
							sorter = conf.generic_sorter({}),
							attach_mappings = function(prompt_bufnr, map)
								actions.select_default:replace(function()
									local selection = action_state.get_selected_entry()
									actions.close(prompt_bufnr)
									if selection then
										vim.fn.jobstart({ "xdg-open", selection.value }, { detach = true })
									end
								end)
								return true
							end,
						})
						:find()
				end)
			end,
desc = "Abrir material/PDFs de materia",
		},

		-- Markdown convenience keymaps (<leader>m*)
		-- Note: bold/italic/link wrapping removed — handled by mini.surround
		{
			"<leader>mc",
			function()
				if vim.fn.mode() == "n" then
					require("config.markdown_utils").toggle_checkbox()
				else
					require("config.markdown_utils").insert_checkbox()
				end
			end,
			desc = "Toggle checkbox (n) / Insert checkbox (i)",
		},
		{
			"<leader>mq",
			function()
				require("config.markdown_utils").insert_blockquote()
			end,
			desc = "Insert blockquote",
		},
		{
			",1",
			function()
				require("config.markdown_utils").insert_heading({ level = 1 })
			end,
			desc = "Insert H1 heading",
			mode = "i",
		},
		{
			",2",
			function()
				require("config.markdown_utils").insert_heading({ level = 2 })
			end,
			desc = "Insert H2 heading",
			mode = "i",
		},
		{
			",3",
			function()
				require("config.markdown_utils").insert_heading({ level = 3 })
			end,
			desc = "Insert H3 heading",
			mode = "i",
		},
		{
			",4",
			function()
				require("config.markdown_utils").insert_heading({ level = 4 })
			end,
			desc = "Insert H4 heading",
			mode = "i",
		},
		{
			",5",
			function()
				require("config.markdown_utils").insert_heading({ level = 5 })
			end,
			desc = "Insert H5 heading",
			mode = "i",
		},
		{
			",6",
			function()
				require("config.markdown_utils").insert_heading({ level = 6 })
			end,
			desc = "Insert H6 heading",
			mode = "i",
		},
	}, creation.keys),
}
