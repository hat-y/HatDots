local home = vim.fn.expand("~")
local scoop_shim = home .. "\\scoop\\shims\\win32yank.exe"
local scoop_app = home .. "\\scoop\\apps\\win32yank\\current\\win32yank.exe"

local function exists(p)
	return (vim.uv or vim.loop).fs_stat(p) ~= nil
end

if exists(scoop_shim) or exists(scoop_app) then
	local yank = exists(scoop_shim) and scoop_shim or scoop_app
	vim.g.clipboard = {
		name = "win32yank (scoop)",
		copy = { ["+"] = yank .. " -i --crlf", ["*"] = yank .. " -i --crlf" },
		paste = { ["+"] = yank .. " -o --lf", ["*"] = yank .. " -o --lf" },
		cache_enabled = 0,
	}
else
	-- Fallback estable con PowerShell
	vim.g.clipboard = {
		name = "powershell-clipboard",
		copy = {
			["+"] = "powershell -NoProfile -Command Set-Clipboard",
			["*"] = "powershell -NoProfile -Command Set-Clipboard",
		},
		paste = {
			["+"] = "powershell -NoProfile -Command Get-Clipboard",
			["*"] = "powershell -NoProfile -Command Get-Clipboard",
		},
		cache_enabled = 0,
	}
end

vim.opt.clipboard = "unnamedplus"
