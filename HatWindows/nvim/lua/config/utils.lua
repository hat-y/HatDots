local M = {}

M.is_win = (vim.uv or vim.loop).os_uname().sysname:lower():find("windows") ~= nil
M.is_linux = not M.is_win and vim.fn.has("linux") == 1

function M.exe(name)
	local p = vim.fn.exepath(name)
	return (p ~= nil and p ~= "") and p or name
end

return M
