-- Configuración específica de Python para uv

-- Función para detectar y activar entorno virtual uv
local function activate_uv_venv()
	local cwd = vim.fn.getcwd()
	local venv_path = cwd .. "/.venv"

	-- Verificar si existe .venv
	if vim.fn.isdirectory(venv_path) == 1 then
		-- Activar variables de entorno para Python LSP
		local python_exe = venv_path .. "/bin/python"
		if vim.fn.executable(python_exe) == 1 then
			vim.env.VIRTUAL_ENV = venv_path
			vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH

			-- Notificar al usuario que se activó el entorno virtual
			vim.notify("🐍 Activated uv venv: " .. venv_path, vim.log.levels.INFO)
			return true
		end
	end

	return false
end

-- Función para crear entorno virtual uv si no existe
local function create_uv_venv()
	local venv_path = vim.fn.getcwd() .. "/.venv"

	if vim.fn.isdirectory(venv_path) == 0 then
		local choice = vim.fn.confirm("No .venv found. Create one with uv?", "&Yes\n&No", 2)
		if choice == 1 then
			vim.notify("Creating uv virtual environment...", vim.log.levels.INFO)
			vim.fn.system("uv venv")
			if vim.fn.isdirectory(venv_path) == 1 then
				vim.notify("uv venv created successfully!", vim.log.levels.INFO)
				activate_uv_venv()
				return true
			else
				vim.notify("Failed to create uv venv", vim.log.levels.ERROR)
			end
		end
	else
		activate_uv_venv()
	end

	return false
end

-- Función para instalar paquetes con uv
local function uv_install(package)
	if not activate_uv_venv() then
		create_uv_venv()
	end

	if vim.fn.isdirectory(vim.fn.getcwd() .. "/.venv") == 1 then
		vim.notify("Installing " .. package .. " with uv...", vim.log.levels.INFO)
		local result = vim.fn.system("uv add " .. package)
		if vim.v.shell_error == 0 then
			vim.notify("Installed " .. package, vim.log.levels.INFO)
		else
			vim.notify("Failed to install " .. package .. ": " .. result, vim.log.levels.ERROR)
		end
	else
		vim.notify("No uv venv found", vim.log.levels.ERROR)
	end
end

-- Comandos personalizados
vim.api.nvim_create_user_command("UVVenv", function()
	create_uv_venv()
end, { desc = "Create/activate uv virtual environment" })

vim.api.nvim_create_user_command("UVInstall", function(opts)
	local package = opts.args
	if package == "" then
		package = vim.fn.input("Package name: ")
	end
	uv_install(package)
end, {
	nargs = "?",
	desc = "Install package with uv",
})

vim.api.nvim_create_user_command("UVSync", function()
	if activate_uv_venv() then
		vim.notify("Syncing dependencies with uv...", vim.log.levels.INFO)
		local result = vim.fn.system("uv sync")
		if vim.v.shell_error == 0 then
			vim.notify("Dependencies synced", vim.log.levels.INFO)
		else
			vim.notify("Sync failed: " .. result, vim.log.levels.ERROR)
		end
	end
end, { desc = "Sync dependencies with uv" })

-- Autocomandos para Python
vim.api.nvim_create_augroup("PythonUV", { clear = true })

-- Activar entorno virtual al abrir archivos Python
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = "PythonUV",
	pattern = "*.py",
	callback = function()
		local venv_path = vim.fn.getcwd() .. "/.venv"
		if vim.fn.isdirectory(venv_path) == 1 then
			activate_uv_venv()
		end
	end,
})

-- Mostrar información del entorno virtual en el statusline
local function uv_venv_info()
	if vim.env.VIRTUAL_ENV then
		local venv_name = vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t")
		return "🐍 " .. venv_name
	end
	return ""
end

-- Exportar funciones para uso en otros lugares
_G.UV = {
	activate = activate_uv_venv,
	create = create_uv_venv,
	install = uv_install,
	info = uv_venv_info,
}

vim.notify("🐍 Python + UV configuration loaded", vim.log.levels.DEBUG)

