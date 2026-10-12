local M = {}

M.vault_path = vim.fn.expand(vim.env.HATNOTES_PATH or "~/HatNotes")
M.required_templates = {
  "log-tmpl.md", "know-tmpl.md", "ref-tmpl.md", "proj-tmpl.md", "libro-tmpl.md",
  "libro-sesion-tmpl.md", "materia-tmpl.md", "clase-tmpl.md", "tp-tmpl.md", "repaso-tmpl.md",
}

function M.preflight()
  for _, name in ipairs(M.required_templates) do
    local path = M.vault_path .. "/7-Tmpl/" .. name
    if vim.fn.filereadable(path) == 0 then
      error("HatNotes template missing: " .. path)
    end
  end
  return true
end

function M.render(name, values)
  local path = M.vault_path .. "/7-Tmpl/" .. name
  if vim.fn.filereadable(path) == 0 then
    error("HatNotes template missing: " .. path)
  end
  local content = table.concat(vim.fn.readfile(path), "\n")
  for key, value in pairs(values) do
    content = content:gsub("{{" .. key .. "}}", function() return tostring(value) end)
  end
  return vim.split(content, "\n", { plain = true })
end

local function open(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function write_template(name, values, path)
  vim.fn.writefile(M.render(name, values), path)
  open(path)
end

local function slugify(value)
  value = value:lower()
  value = value:gsub("á", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ó", "o"):gsub("ú", "u"):gsub("ñ", "n"):gsub("ü", "u")
  value = value:gsub("Á", "a"):gsub("É", "e"):gsub("Í", "i"):gsub("Ó", "o"):gsub("Ú", "u"):gsub("Ñ", "n"):gsub("Ü", "u")
  return value:gsub("[^a-z0-9]+", "-"):gsub("^%-", ""):gsub("%-$", "")
end

local function directories(path)
  local handle = (vim.uv or vim.loop).fs_scandir(path)
  if not handle then return end
  local result = {}
  while true do
    local name, kind = (vim.uv or vim.loop).fs_scandir_next(handle)
    if not name then break end
    if kind == "directory" then table.insert(result, name) end
  end
  return result
end

local function next_number(path, pattern)
  local maximum = 0
  local handle = (vim.uv or vim.loop).fs_scandir(path)
  if not handle then return 1 end
  while true do
    local name, kind = (vim.uv or vim.loop).fs_scandir_next(handle)
    if not name then break end
    local number = kind == "file" and name:match(pattern)
    if number then maximum = math.max(maximum, tonumber(number)) end
  end
  return maximum + 1
end

local function subjects()
  local path = M.vault_path .. "/4-Projs/Materias"
  local folders = directories(path)
  if not folders then return end
  local names, slugs = {}, {}
  for _, slug in ipairs(folders) do
    local name = slug
    local note = path .. "/" .. slug .. "/materia.md"
    if vim.fn.filereadable(note) == 1 then
      for _, line in ipairs(vim.fn.readfile(note)) do
        local found = line:match("^nombre:%s*(.+)$")
        if found then name = found break end
      end
    end
    table.insert(names, name)
    slugs[name] = slug
  end
  return path, names, slugs
end

local function select_subject(callback)
  local path, names, slugs = subjects()
  if not path or #names == 0 then
    vim.notify("No hay materias creadas. Usa <leader>omn", vim.log.levels.WARN)
    return
  end
  vim.ui.select(names, { prompt = "Materia:" }, function(name)
    if name then callback(path .. "/" .. slugs[name], name) end
  end)
end

M.keys = {
  {
    "<leader>onl",
    function()
      local logs = M.vault_path .. "/3-Logs"
      vim.fn.mkdir(logs, "p")
      local path = logs .. "/" .. os.date("%Y-%m-%d") .. ".md"
      if vim.fn.filereadable(path) == 1 then
        open(path)
        vim.cmd("normal! G")
        vim.cmd("startinsert")
        return
      end
      write_template("log-tmpl.md", { date = os.date("%Y-%m-%d") }, path)
    end,
    desc = "Nueva nota en 3-Logs (log diario)",
  },
  {
    "<leader>onk",
    function()
      local title = vim.fn.input("Concepto: ")
      if title == "" then return end
      write_template("know-tmpl.md", { date = os.date("%Y-%m-%d"), titulo = title }, M.vault_path .. "/2-Know/" .. title:lower():gsub("%s+", "-") .. ".md")
    end,
    desc = "Nueva nota en 2-Know (concepto)",
  },
  {
    "<leader>ona",
    function()
      local title = vim.fn.input("Artículo: ")
      if title == "" then return end
      local date = os.date("%Y-%m-%d")
      local articles = M.vault_path .. "/6-Ref/Articulos/" .. os.date("%Y")
      vim.fn.mkdir(articles, "p")
      write_template("ref-tmpl.md", { date = date, titulo = title }, articles .. "/" .. date .. " " .. title .. ".md")
    end,
    desc = "Nuevo artículo en 6-Ref/Articulos",
  },
  {
    "<leader>onp",
    function()
      local title = vim.fn.input("Proyecto: ")
      if title == "" then return end
      local path = M.vault_path .. "/4-Projs/" .. title
      vim.fn.mkdir(path, "p")
      write_template("proj-tmpl.md", { date = os.date("%Y-%m-%d"), titulo = title }, path .. "/README.md")
    end,
    desc = "Nuevo proyecto en 4-Projs",
  },
  {
    "<leader>oln",
    function()
      local title = vim.fn.input("Libro: ")
      if title == "" then return end
      local path = M.vault_path .. "/6-Ref/Libros/" .. title
      vim.fn.mkdir(path, "p")
      write_template("libro-tmpl.md", { date = os.date("%Y-%m-%d"), titulo = title }, path .. "/metadata.md")
    end,
    desc = "Nuevo libro (crea carpeta + metadata)",
  },
  {
    "<leader>ols",
    function()
      local books = M.vault_path .. "/6-Ref/Libros"
      local names = directories(books)
      if not names or #names == 0 then
        vim.notify("No hay libros creados. Usa <leader>oln", vim.log.levels.WARN)
        return
      end
      vim.ui.select(names, { prompt = "Seleccionar libro:" }, function(title)
        if not title then return end
        local path = books .. "/" .. title
        local number = next_number(path, "^sesion (%d+)%.md$")
        write_template("libro-sesion-tmpl.md", { date = os.date("%Y-%m-%d"), titulo = title, num = number }, path .. "/sesion " .. number .. ".md")
      end)
    end,
    desc = "Nueva sesión de lectura",
  },
  {
    "<leader>omn",
    function()
      local name = vim.fn.input("Materia: ")
      if name == "" then return end
      local slug = slugify(name)
      local subjects_path = M.vault_path .. "/4-Projs/Materias"
      local path = subjects_path .. "/" .. slug
      vim.fn.mkdir(subjects_path, "p")
      if vim.fn.isdirectory(path) == 1 then
        vim.notify("La materia '" .. slug .. "' ya existe", vim.log.levels.WARN)
        open(path .. "/materia.md")
        return
      end
      vim.fn.mkdir(path .. "/material", "p")
      local date = os.date("%Y-%m-%d")
      write_template("materia-tmpl.md", { date = date, materia = name }, path .. "/materia.md")
      local index = subjects_path .. "/_indice.md"
      local entry = "- [[" .. slug .. "/materia|" .. name .. "]]"
      if vim.fn.filereadable(index) == 0 then
        vim.fn.writefile({ "---", "creacion: " .. date, "tipo: indice", "tags: [materias]", "---", "", "# Materias - 1C 2026", "", "## Activas", entry, "", "## Completadas", "- ", "", "## Notas generales", "- ", "" }, index)
        return
      end
      local lines = vim.fn.readfile(index)
      for i, line in ipairs(lines) do
        if line == "## Activas" then
          table.insert(lines, i + 1, entry)
          vim.fn.writefile(lines, index)
          break
        end
      end
    end,
    desc = "Nueva materia",
  },
  {
    "<leader>omc",
    function()
      select_subject(function(path, name)
        local number = next_number(path, "^clase%-(%d+)%.md$")
        write_template("clase-tmpl.md", { date = os.date("%Y-%m-%d"), materia = name, num = number }, path .. string.format("/clase-%02d.md", number))
      end)
    end,
    desc = "Nueva clase (seleccionar materia)",
  },
  {
    "<leader>omt",
    function()
      select_subject(function(path, name)
        local number = next_number(path, "^tp%-(%d+)%.md$")
        write_template("tp-tmpl.md", { date = os.date("%Y-%m-%d"), materia = name, num = number }, path .. string.format("/tp-%02d.md", number))
      end)
    end,
    desc = "Nuevo TP (seleccionar materia)",
  },
  {
    "<leader>omr",
    function()
      select_subject(function(path, name)
        local exam = vim.fn.input("Tipo (Parcial 1/Parcial 2/Final): ")
        if exam == "" then exam = "Parcial" end
        write_template("repaso-tmpl.md", { date = os.date("%Y-%m-%d"), materia = name, examen = exam }, path .. "/repaso-" .. slugify(exam) .. ".md")
      end)
    end,
    desc = "Repaso / Parcial (seleccionar materia)",
  },
}

return M
