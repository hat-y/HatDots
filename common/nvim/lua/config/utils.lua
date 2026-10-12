-- Utilities for Neovim configuration

local M = {}

-- Operating system detection
M.is_win = (vim.uv or vim.loop).os_uname().sysname:lower():find("windows") ~= nil
M.is_linux = not M.is_win and vim.fn.has("linux") == 1
M.is_macos = vim.fn.has("mac") == 1

-- Function to get full path of an executable
function M.exe(name)
	local p = vim.fn.exepath(name)
	return (p ~= nil and p ~= "") and p or name
end

-- Function to check if a command exists
function M.has(command)
	return vim.fn.executable(command) > 0
end

-- Function to create directories if they don't exist
function M.ensure_dir(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

-- Function to safely map keys
function M.map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- Function for autocmds
function M.autocmd(group, event, pattern, callback)
	vim.api.nvim_create_autocmd(event, {
		group = vim.api.nvim_create_augroup(group, { clear = true }),
		pattern = pattern,
		callback = callback,
	})
end

-- Function to check if a file is readable
function M.is_readable(file)
	local f = io.open(file, "r")
	if f then
		f:close()
		return true
	end
	return false
end

-- Function to create a notification
function M.notify(message, level)
	level = level or vim.log.levels.INFO
	vim.notify(message, level, { title = "HatDots Config" })
end

-- Function to safely load modules
function M.safe_require(module)
	local ok, loaded_module = pcall(require, module)
	if ok then
		return loaded_module
	else
		M.notify("Could not load module: " .. module, vim.log.levels.WARN)
		return nil
	end
end

-- Function to get system package manager
function M.get_package_manager()
	if M.has("winget") then
		return "winget"
	elseif M.has("brew") then
		return "brew"
	elseif M.has("apt") then
		return "apt"
	elseif M.has("scoop") then
		return "scoop"
	else
		return "unknown"
	end
end

-- Specific configuration for Windows
if M.is_win then
	-- Configure shell for Windows
	if M.has("pwsh") then
		vim.opt.shell = "pwsh.exe"
		vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
		vim.opt.shellquote = '"'
		vim.opt.shellxquote = '"'
	elseif M.has("powershell") then
		vim.opt.shell = "powershell.exe"
		vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
		vim.opt.shellquote = '"'
		vim.opt.shellxquote = '"'
	end
end

return M
