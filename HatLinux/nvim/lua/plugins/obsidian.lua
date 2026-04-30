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
				path = "~/HatNotes",
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
				vim.opt_local.spelllang = "es_ES,en"
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
	keys = {
		-- Plugin commands
		{ "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian app" },
		{ "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
		{ "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick switch" },
		{ "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search" },
		{ "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Insert template" },
		{
			"<leader>onl",
			function()
				local vault_path = vim.fn.expand("~/HatNotes")
				local logs_path = vault_path .. "/3-Logs"
				vim.fn.mkdir(logs_path, "p")

				local date = os.date("%Y-%m-%d")
				local file_path = logs_path .. "/" .. date .. ".md"

				-- Check if file already exists
				if vim.fn.filereadable(file_path) == 1 then
					vim.cmd("e " .. file_path)
					vim.cmd("normal! G")
					vim.cmd("startinsert")
					return
				end

				local content = string.format([=[---
creacion: %s
tipo: log
tags: []
---

# Log: %s

## Aprendido
- 

## Tareas
- [ ] 

## Notas
- 
]=], date, date)

				vim.fn.writefile(vim.split(content, "\n"), file_path)
				vim.cmd("e " .. file_path)
			end,
			desc = "Nueva nota en 3-Logs (log diario)",
		},
		{ "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
		{ "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Buffer links" },
		{ "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename note" },
		{ "<leader>olT", "<cmd>ObsidianTemplate log-tmpl<cr>", desc = "Insert log template" },

		-- Quick note creation
		{
			"<leader>onk",
			function()
				local title = vim.fn.input("Concepto: ")
				if title == "" then
					return
				end
				local vault_path = vim.fn.expand("~/HatNotes")
				local date = os.date("%Y-%m-%d")

				-- Create filename from title (slugify)
				local filename = title:lower():gsub("%s+", "-")
				local file_path = vault_path .. "/2-Know/" .. filename .. ".md"

				local content = string.format([=[---
creacion: %s
tipo: concepto
tags: []
---

# %s

## Qué es
%s

## Por qué importa
- 

## Ejemplo
```javascript
// código
```

## Relacionado
- [[]]
]=], date, title, title)

				vim.fn.writefile(vim.split(content, "\n"), file_path)
				vim.cmd("e " .. file_path)
			end,
			desc = "Nueva nota en 2-Know (concepto)",
		},
		{
			"<leader>ona",
			function()
				local title = vim.fn.input("Artículo: ")
				if title == "" then
					return
				end
				local vault_path = vim.fn.expand("~/HatNotes")
				local year = os.date("%Y")
				local date = os.date("%Y-%m-%d")
				local articles_path = vault_path .. "/6-Ref/Articulos/" .. year
				vim.fn.mkdir(articles_path, "p")

				-- Create filename
				local filename = date .. " " .. title .. ".md"
				local file_path = articles_path .. "/" .. filename:gsub("%.md$", "") .. ".md"

				local content = string.format([[---
tipo: articulo
fuente: 
fecha: %s
---

# %s

## Resumen
%s

## Notas
- 

## Para recordar
- 
]], date, title, title)

				vim.fn.writefile(vim.split(content, "\n"), file_path)
				vim.cmd("e " .. file_path)
			end,
			desc = "Nuevo artículo en 6-Ref/Articulos",
		},
		{
			"<leader>onp",
			function()
				local proj_name = vim.fn.input("Proyecto: ")
				if proj_name == "" then
					return
				end
				local vault_path = vim.fn.expand("~/HatNotes")
				local date = os.date("%Y-%m-%d")

				local proj_path = vault_path .. "/4-Projs/" .. proj_name
				vim.fn.mkdir(proj_path, "p")

				local content = string.format([=[---
creacion: %s
estado: activo
tags: []
---

# %s

```json
{
	"id_proyecto": "PRJ-001",
	"nombre": "%s",
	"descripción_breve": "Descripción...",
	"problema_a_resolver": "Problema...",
	"público_objetivo": ["Usuario Final"],
	"supuestos_clave": ["Supuesto 1"],
	"restricciones": {
		"tiempo": "Q3 2026",
		"presupuesto": "N/A",
		"tecnología": ["Node.js, PostgreSQL"],
		"cumplimiento": ["GDPR"]
	},
	"equipo_disponible": ["2 Backend, 1 Frontend"],
	"métricas_esperadas": ["MAU > 10k"],
	"prioridad_del_scope": ["Auth, Core API"],
	"datos_tecnicos_disponibles": {
		"APIs": ["REST / GraphQL"],
		"infra": "Docker / K8s",
		"stack": ["Stack base"]
	},
	"output_tipo": "PRD | RFC | SRS | HLD"
}
```

## Estado
- [x] Activo
- [ ] En pausa
- [ ] Completado

## Links importantes
- [[]]
- [[]]

## Tareas
- [ ] 

## Notas
- 

## Progreso
-

## Archivos relacionados
- 
]=], date, proj_name, proj_name)

				local readme_path = proj_path .. "/README.md"
				vim.fn.writefile(vim.split(content, "\n"), readme_path)
				vim.cmd("e " .. readme_path)
			end,
			desc = "Nuevo proyecto en 4-Projs",
		},

		-- Libro / Lectura commands
		{
			"<leader>oln",
			function()
				local book_title = vim.fn.input("Libro: ")
				if book_title == "" then
					return
				end
				-- Use fixed path instead of obsidian client
				local vault_path = vim.fn.expand("~/HatNotes")
				local books_path = vault_path .. "/6-Ref/Libros"
				vim.fn.mkdir(books_path, "p")

				local book_folder = books_path .. "/" .. book_title
				vim.fn.mkdir(book_folder, "p")

				-- Create metadata file
				local meta_path = book_folder .. "/metadata.md"
				local meta_content = string.format([[---
titulo: %s
autor: 
isbn: 
paginas: 
año: 
estado: sin-iniciar
inicio: %s
progreso: 0
---

## Por qué elegí este libro

## Temas que espero aprender
- 
]], book_title, os.date("%Y-%m-%d"))
				vim.fn.writefile(vim.split(meta_content, "\n"), meta_path)
				vim.cmd("e " .. meta_path)
			end,
			desc = "Nuevo libro (crea carpeta + metadata)",
		},
		{
			"<leader>ols",
			function()
				-- Use fixed path instead of obsidian client
				local vault_path = vim.fn.expand("~/HatNotes")
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
					vim.notify("No hay libros creados. Usa <leader>oln", vim.log.levels.WARN)
					return
				end

				-- Ask which book
				vim.ui.select(books, { prompt = "Seleccionar libro:" }, function(book)
					if not book then
						return
					end

					-- Count existing sessions
					local book_path = books_path .. "/" .. book
					local session_count = 0
					local session_handle = vim.loop.fs_scandir(book_path)
					if session_handle then
						while true do
							local entry_name, entry_typ = vim.loop.fs_scandir_next(session_handle)
							if not entry_name then
								break
							end
							if entry_typ == "file" and entry_name:match("^sesion %d+%.md$") then
								session_count = session_count + 1
							end
						end
					end

					local new_session = session_count + 1
					local date = os.date("%Y-%m-%d")
					local session_path = book_path .. "/sesion " .. new_session .. ".md"

					local session_content = string.format([[---
tipo: Sesion-Lectura
libro: %s
sesion: %d
fecha: %s
rango_paginas: 
duracion: 20min
---

# Sesión %d: 

## PRE-PREGUNTAS
1. 
2. 
3. 
4. 

---

## POST-PREGUNTAS
1. **Pregunta 1**
   - Resp: 
   - Ref: p.

---

## BRAIN DUMP

### Lo que entendí (en mis palabras)


### Conceptos clave
- 

### Qué no entendí bien
- 

### Aplicación práctica
- 
]], book, new_session, date, new_session)

					vim.fn.writefile(vim.split(session_content, "\n"), session_path)
					vim.cmd("e " .. session_path)
				end)
			end,
			desc = "Nueva sesión de lectura",
		},
		{
			"<leader>oll",
			function()
				-- Use fixed path instead of obsidian client
				local vault_path = vim.fn.expand("~/HatNotes")
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
				local vault_path = vim.fn.expand("~/HatNotes")
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

		-- Materias commands
		{
			"<leader>omn",
			function()
				local name = vim.fn.input("Materia: ")
				if name == "" then
					return
				end
				local vault_path = vim.fn.expand("~/HatNotes")
				local materias_path = vault_path .. "/4-Projs/Materias"
				vim.fn.mkdir(materias_path, "p")

				local materia_path = materias_path .. "/" .. name
				if vim.fn.isdirectory(materia_path) == 1 then
					vim.notify("La materia '" .. name .. "' ya existe", vim.log.levels.WARN)
					vim.cmd("e " .. materia_path .. "/materia.md")
					return
				end
				vim.fn.mkdir(materia_path, "p")

				local date = os.date("%Y-%m-%d")
				local content = string.format([=[---
creacion: %s
tipo: materia
estado: activa
cuatrimestre: 1C2026
tags: []
---

# %s

## Info
- **Profesor/a**: 
- **Email**: 
- **Aula**: 
- **Horario**: 
- **Plataforma**: 

## Evaluaciones
| Tipo | Fecha | Temas | Estado |
|------|-------|-------|--------|
| Parcial 1 | | | ⏳ |
| Parcial 2 | | | ⏳ |
| TP 1 | | | ⏳ |
| TP 2 | | | ⏳ |
| Final | | | ⏳ |

## Unidades / Temario
1. 
2. 
3. 
4. 
5. 

## Clases
- 

## Links útiles
- 
]=], date, name)

				vim.fn.writefile(vim.split(content, "\n"), materia_path .. "/materia.md")

				-- Update _indice.md
				local indice_path = materias_path .. "/_indice.md"
				if vim.fn.filereadable(indice_path) == 0 then
					local indice_content = string.format([=[---
creacion: %s
tipo: indice
tags: [materias]
---

# Materias - 1C 2026

## Activas
- [[%s/materia|%s]]

## Completadas
- 

## Notas generales
- 
]=], date, name, name, name)
					vim.fn.writefile(vim.split(indice_content, "\n"), indice_path)
				else
					local lines = vim.fn.readfile(indice_path)
					local activas_idx = nil
					for i, line in ipairs(lines) do
						if line == "## Activas" then
							activas_idx = i
							break
						end
					end
					if activas_idx then
						local new_line = "- [[" .. name .. "/materia|" .. name .. "]]"
						table.insert(lines, activas_idx + 1, new_line)
						vim.fn.writefile(lines, indice_path)
					end
				end

				vim.cmd("e " .. materia_path .. "/materia.md")
			end,
			desc = "Nueva materia",
		},
		{
			"<leader>omc",
			function()
				local vault_path = vim.fn.expand("~/HatNotes")
				local materias_path = vault_path .. "/4-Projs/Materias"

				local handle = vim.loop.fs_scandir(materias_path)
				if not handle then
					vim.notify("No hay materias. Usa <leader>omn primero", vim.log.levels.WARN)
					return
				end

				local materias = {}
				while true do
					local name, typ = vim.loop.fs_scandir_next(handle)
					if not name then
						break
					end
					if typ == "directory" then
						table.insert(materias, name)
					end
				end

				if #materias == 0 then
					vim.notify("No hay materias creadas. Usa <leader>omn", vim.log.levels.WARN)
					return
				end

				vim.ui.select(materias, { prompt = "Materia:" }, function(materia)
					if not materia then
						return
					end

					local materia_path = materias_path .. "/" .. materia
					local clase_count = 0
					local clase_handle = vim.loop.fs_scandir(materia_path)
					if clase_handle then
						while true do
							local entry, entry_typ = vim.loop.fs_scandir_next(clase_handle)
							if not entry then
								break
							end
							if entry_typ == "file" and entry:match("^Clase%-%d+%.md$") then
								clase_count = clase_count + 1
							end
						end
					end

					local num = clase_count + 1
					local date = os.date("%Y-%m-%d")
					local filename = string.format("Clase-%02d.md", num)
					local filepath = materia_path .. "/" .. filename

					local content = string.format([=[---
creacion: %s
tipo: clase
materia: %s
clase_num: %d
tags: []
---

# Clase %d - %s

## Tema de hoy
- 

## Apuntes


## Conceptos clave
- 

## Dudas / Preguntar al profe
- 

## Tareas
- [ ] 

## Próxima clase
- 
]=], date, materia, num, num, materia)

					vim.fn.writefile(vim.split(content, "\n"), filepath)
					vim.cmd("e " .. filepath)
				end)
			end,
			desc = "Nueva clase (seleccionar materia)",
		},
		{
			"<leader>omt",
			function()
				local vault_path = vim.fn.expand("~/HatNotes")
				local materias_path = vault_path .. "/4-Projs/Materias"

				local handle = vim.loop.fs_scandir(materias_path)
				if not handle then
					vim.notify("No hay materias. Usa <leader>omn primero", vim.log.levels.WARN)
					return
				end

				local materias = {}
				while true do
					local name, typ = vim.loop.fs_scandir_next(handle)
					if not name then
						break
					end
					if typ == "directory" then
						table.insert(materias, name)
					end
				end

				if #materias == 0 then
					vim.notify("No hay materias creadas. Usa <leader>omn", vim.log.levels.WARN)
					return
				end

				vim.ui.select(materias, { prompt = "Materia:" }, function(materia)
					if not materia then
						return
					end

					local materia_path = materias_path .. "/" .. materia
					local tp_count = 0
					local tp_handle = vim.loop.fs_scandir(materia_path)
					if tp_handle then
						while true do
							local entry, entry_typ = vim.loop.fs_scandir_next(tp_handle)
							if not entry then
								break
							end
							if entry_typ == "file" and entry:match("^TP%-%d+%.md$") then
								tp_count = tp_count + 1
							end
						end
					end

					local num = tp_count + 1
					local date = os.date("%Y-%m-%d")
					local filename = string.format("TP-%02d.md", num)
					local filepath = materia_path .. "/" .. filename

					local content = string.format([=[---
creacion: %s
tipo: tp
materia: %s
tp_num: %d
fecha_entrega: 
estado: pendiente
tags: []
---

# TP %d - %s

## Consigna
- 

## Requisitos
- [ ] 

## Notas / Ideas
- 

## Progreso
- [ ] Entendí la consigna
- [ ] Boceto / Plan
- [ ] Desarrollo
- [ ] Revisión
- [ ] Entregado

## Entrega
- **Fecha límite**: 
- **Formato**: 
]=], date, materia, num, num, materia)

					vim.fn.writefile(vim.split(content, "\n"), filepath)
					vim.cmd("e " .. filepath)
				end)
			end,
			desc = "Nuevo TP (seleccionar materia)",
		},
		{
			"<leader>omr",
			function()
				local vault_path = vim.fn.expand("~/HatNotes")
				local materias_path = vault_path .. "/4-Projs/Materias"

				local handle = vim.loop.fs_scandir(materias_path)
				if not handle then
					vim.notify("No hay materias. Usa <leader>omn primero", vim.log.levels.WARN)
					return
				end

				local materias = {}
				while true do
					local name, typ = vim.loop.fs_scandir_next(handle)
					if not name then
						break
					end
					if typ == "directory" then
						table.insert(materias, name)
					end
				end

				if #materias == 0 then
					vim.notify("No hay materias creadas. Usa <leader>omn", vim.log.levels.WARN)
					return
				end

				vim.ui.select(materias, { prompt = "Materia:" }, function(materia)
					if not materia then
						return
					end

					local materia_path = materias_path .. "/" .. materia

					local tipo_examen = vim.fn.input("Tipo (Parcial 1/Parcial 2/Final): ")
					if tipo_examen == "" then
						tipo_examen = "Parcial"
					end

					local date = os.date("%Y-%m-%d")
					local filename = "Repaso-" .. tipo_examen:gsub("%s+", "-") .. ".md"
					local filepath = materia_path .. "/" .. filename

					local content = string.format([=[---
creacion: %s
tipo: repaso
materia: %s
examen: %s
tags: []
---

# Repaso - %s (%s)

## Temas que entran
1. 
2. 
3. 

## Resumen por tema

### Tema 1
- 

### Tema 2
- 

### Tema 3
- 

## Ejercicios de práctica
1. 

## Dudas para consultar
- [ ] 

## Checklist de preparación
- [ ] Temas teóricos completos
- [ ] Ejercicios practicados
- [ ] Fórmulas / definiciones memorizadas
- [ ] Dudas resueltas
- [ ] Simulé condiciones de examen

## Notas post-examen
- 
]=], date, materia, tipo_examen, materia, tipo_examen)

					vim.fn.writefile(vim.split(content, "\n"), filepath)
					vim.cmd("e " .. filepath)
				end)
			end,
			desc = "Repaso / Parcial (seleccionar materia)",
		},
		{
			"<leader>omi",
			function()
				local vault_path = vim.fn.expand("~/HatNotes")
				local indice_path = vault_path .. "/4-Projs/Materias/_indice.md"
				if vim.fn.filereadable(indice_path) == 0 then
					vim.notify("No existe el índice. Usa <leader>omn primero", vim.log.levels.WARN)
					return
				end
				vim.cmd("e " .. indice_path)
			end,
			desc = "Abrir índice de materias",
		},

		-- Markdown convenience keymaps (<leader>m*)
		-- Note: bold/italic/link wrapping removed — handled by mini.surround
		{
			"<leader>mc",
			function()
				if vim.fn.mode() == "n" then
					require("markdown-keymaps").toggle_checkbox()
				else
					require("markdown-keymaps").insert_checkbox()
				end
			end,
			desc = "Toggle checkbox (n) / Insert checkbox (i)",
		},
		{
			"<leader>mq",
			function()
				require("markdown-keymaps").insert_blockquote()
			end,
			desc = "Insert blockquote",
		},
		{
			",1",
			function()
				require("markdown-keymaps").insert_heading({ level = 1 })
			end,
			desc = "Insert H1 heading",
			mode = "i",
		},
		{
			",2",
			function()
				require("markdown-keymaps").insert_heading({ level = 2 })
			end,
			desc = "Insert H2 heading",
			mode = "i",
		},
		{
			",3",
			function()
				require("markdown-keymaps").insert_heading({ level = 3 })
			end,
			desc = "Insert H3 heading",
			mode = "i",
		},
		{
			",4",
			function()
				require("markdown-keymaps").insert_heading({ level = 4 })
			end,
			desc = "Insert H4 heading",
			mode = "i",
		},
		{
			",5",
			function()
				require("markdown-keymaps").insert_heading({ level = 5 })
			end,
			desc = "Insert H5 heading",
			mode = "i",
		},
		{
			",6",
			function()
				require("markdown-keymaps").insert_heading({ level = 6 })
			end,
			desc = "Insert H6 heading",
			mode = "i",
		},
	},
}
