local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(script))))
package.path = root .. "/shared/nvim/lua/?.lua;" .. root .. "/shared/nvim/lua/?/init.lua;" .. package.path

local vault = vim.fn.tempname()
local templates = {
  "log-tmpl.md", "know-tmpl.md", "ref-tmpl.md", "proj-tmpl.md", "libro-tmpl.md",
  "libro-sesion-tmpl.md", "materia-tmpl.md", "clase-tmpl.md", "tp-tmpl.md", "repaso-tmpl.md",
}

local function remove_vault()
  vim.fn.delete(vault, "rf")
end

local ok, err = xpcall(function()
  vim.fn.mkdir(vault .. "/7-Tmpl", "p")
  for _, name in ipairs(templates) do
    vim.fn.writefile({ name .. " {{date}} {{titulo}} {{materia}} {{num}} {{examen}}" }, vault .. "/7-Tmpl/" .. name)
  end

  vim.env.HATNOTES_PATH = vault
  local creation = require("hatnotes.creation")
  assert(creation.vault_path == vault, "vault path did not resolve HATNOTES_PATH")
  assert(creation.preflight() == true, "template preflight failed")

  local expected = { "<leader>onl", "<leader>onk", "<leader>ona", "<leader>onp", "<leader>oln", "<leader>ols", "<leader>omn", "<leader>omc", "<leader>omt", "<leader>omr" }
  local specs = {}
  for _, spec in ipairs(creation.keys) do
    specs[spec[1]] = (specs[spec[1]] or 0) + 1
  end
  assert(#creation.keys == #expected, "expected exactly ten creation key specs")
  for _, lhs in ipairs(expected) do
    assert(specs[lhs] == 1, lhs .. " must exist exactly once")
  end

  local rendered = table.concat(creation.render("know-tmpl.md", { date = "2026-01-02", titulo = "Rendered" }), "\n")
  assert(rendered:find("2026%-01%-02 Rendered"), "renderer did not substitute placeholders")

  local by_lhs = {}
  for _, spec in ipairs(creation.keys) do
    by_lhs[spec[1]] = spec[2]
  end
  by_lhs["<leader>onl"]()
  local log_path = vault .. "/3-Logs/" .. os.date("%Y-%m-%d") .. ".md"
  assert(vim.fn.filereadable(log_path) == 1, "log creator did not write its date path")
  assert(table.concat(vim.fn.readfile(log_path), "\n"):find("log%-tmpl%.md"), "log did not render its template")

  local original_input, original_select = vim.fn.input, vim.ui.select
  vim.fn.input = function() return "Álgebra Lineal" end
  vim.ui.select = function(items, _, callback) callback(items[1]) end
  by_lhs["<leader>omn"]()
  by_lhs["<leader>omc"]()
  local subject = vault .. "/4-Projs/Materias/algebra-lineal"
  vim.fn.writefile({ "sentinel" }, subject .. "/clase-03.md")
  by_lhs["<leader>omc"]()
  vim.fn.input, vim.ui.select = original_input, original_select

  assert(vim.fn.filereadable(subject .. "/materia.md") == 1, "subject creator did not slug or render")
  assert(vim.fn.filereadable(subject .. "/clase-01.md") == 1, "class creator did not number from one")
  assert(table.concat(vim.fn.readfile(subject .. "/clase-03.md"), "\n") == "sentinel", "class creator overwrote an existing gap file")
  assert(vim.fn.filereadable(subject .. "/clase-04.md") == 1, "class creator did not advance past the highest existing number")
  local index = table.concat(vim.fn.readfile(vault .. "/4-Projs/Materias/_indice.md"), "\n")
  assert(index:find("%[%[algebra%-lineal/materia|Álgebra Lineal%]%]"), "subject index was not updated")
end, debug.traceback)

remove_vault()
assert(vim.fn.isdirectory(vault) == 0, "temporary vault cleanup failed")
assert(ok, err)
print("creation smoke passed")
