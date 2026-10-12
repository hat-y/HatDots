-- DAP configuration using LazyVim extra
-- Main configuration is in lazyvim.plugins.extras.dap

-- Specific configuration for Python
local dap = require("dap")

-- Python adapter with debugpy
dap.adapters.python = {
	type = "executable",
	command = "python",
	args = { "-m", "debugpy.adapter" },
}

-- Configurations for Python
dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",
		program = "${file}",
		pythonPath = function()
			local cwd = vim.fn.getcwd()
			if vim.fn.executable(cwd .. "/venv/Scripts/python.exe") == 1 then
				return cwd .. "/venv/Scripts/python.exe"
			elseif vim.fn.executable(cwd .. "/.venv/Scripts/python.exe") == 1 then
				return cwd .. "/.venv/Scripts/python.exe"
			else
				return "python"
			end
		end,
		console = "integratedTerminal",
	},
	{
		type = "python",
		request = "launch",
		name = "Debug Django App",
		program = "${workspaceFolder}/manage.py",
		args = { "runserver", "--noreload" },
		console = "integratedTerminal",
		django = true,
	},
	{
		type = "python",
		request = "launch",
		name = "Debug Flask App",
		module = "flask",
		args = { "run", "--no-debugger" },
		console = "integratedTerminal",
		flask = true,
	},
}
