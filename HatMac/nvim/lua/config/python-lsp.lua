-- Configuración específica para Pyright con UV

-- Función para obtener el path del intérprete Python de UV
local function get_uv_python_path()
  local cwd = vim.fn.getcwd()
  local venv_path = cwd .. "/.venv"

  -- Verificar si existe .venv
  if vim.fn.isdirectory(venv_path) == 1 then
    local python_exe

    -- Linux/macOS
    if vim.fn.executable(venv_path .. "/bin/python") == 1 then
      python_exe = venv_path .. "/bin/python"
    -- Windows
    elseif vim.fn.executable(venv_path .. "/Scripts/python.exe") == 1 then
      python_exe = venv_path .. "/Scripts/python.exe"
    end

    if python_exe then
      return python_exe
    end
  end

  -- Fallback a python global
  local global_python = vim.fn.exepath("python3") or vim.fn.exepath("python")
  return global_python
end

-- Configuración para pyright
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PythonLSPSetup", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "pyright" then
      -- Obtener el path del intérprete UV
      local python_path = get_uv_python_path()

      -- Actualizar la configuración del cliente
      client.config.settings = client.config.settings or {}
      client.config.settings.python = client.config.settings.python or {}
      client.config.settings.python.pythonPath = python_path
    end
  end,
})

-- Comando para verificar qué intérprete está usando pyright
vim.api.nvim_create_user_command("PythonPath", function()
  local python_path = get_uv_python_path()
  vim.notify("Current Python path: " .. python_path, vim.log.levels.INFO)
end, { desc = "Show current Python path" })
