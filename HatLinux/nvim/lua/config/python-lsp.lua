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
      vim.notify("🐍 Using Python: " .. python_exe, vim.log.levels.DEBUG)
      return python_exe
    end
  end

  -- Fallback a python global
  local global_python = vim.fn.exepath("python3") or vim.fn.exepath("python")
  vim.notify("🐍 Using global Python: " .. global_python, vim.log.levels.DEBUG)
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

      -- Notificar al servidor sobre la nueva configuración
      client.notify("workspace/didChangeConfiguration", {
        settings = client.config.settings,
      })

      vim.notify("🐍 Pyright configured with UV Python: " .. python_path, vim.log.levels.INFO)
    end
  end,
})

-- Comando para verificar qué intérprete está usando pyright
vim.api.nvim_create_user_command("PythonPath", function()
  local python_path = get_uv_python_path()
  vim.notify("Current Python path: " .. python_path, vim.log.levels.INFO)

  -- También mostrar qué está usando pyright si está activo
  local clients = vim.lsp.get_clients({ name = "pyright" })
  if #clients > 0 then
    local client = clients[1]
    local lsp_python_path = client.config.settings.python and client.config.settings.python.pythonPath
    if lsp_python_path then
      vim.notify("Pyright Python path: " .. lsp_python_path, vim.log.levels.INFO)
    else
      vim.notify("Pyright: no custom python path configured", vim.log.levels.WARN)
    end
  else
    vim.notify("Pyright not active", vim.log.levels.WARN)
  end
end, { desc = "Show current Python paths" })

-- Comando para recargar la configuración de pyright
vim.api.nvim_create_user_command("ReloadPythonLSP", function()
  local clients = vim.lsp.get_clients({ name = "pyright" })
  if #clients > 0 then
    local client = clients[1]
    local python_path = get_uv_python_path()

    client.config.settings = client.config.settings or {}
    client.config.settings.python = client.config.settings.python or {}
    client.config.settings.python.pythonPath = python_path

    client.notify("workspace/didChangeConfiguration", {
      settings = client.config.settings,
    })

    vim.notify("🐍 Reloaded Pyright with UV Python: " .. python_path, vim.log.levels.INFO)
  else
    vim.notify("Pyright not active", vim.log.levels.WARN)
  end
end, { desc = "Reload Python LSP configuration" })

vim.notify("🐍 Python LSP + UV configuration loaded", vim.log.levels.DEBUG)