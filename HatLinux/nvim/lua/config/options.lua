local home = vim.fn.expand("~")
local scoop_shim = home .. "\\scoop\\shims\\win32yank.exe"
local scoop_app = home .. "\\scoop\\apps\\win32yank\\current\\win32yank.exe"

local function exists(p)
	return (vim.uv or vim.loop).fs_stat(p) ~= nil
end

-- Clipboard configuration
if exists(scoop_shim) or exists(scoop_app) then
	local yank = exists(scoop_shim) and scoop_shim or scoop_app
	vim.g.clipboard = {
		name = "win32yank (scoop)",
		copy = { ["+"] = yank .. " -i --crlf", ["*"] = yank .. " -i --crlf" },
		paste = { ["+"] = yank .. " -o --lf", ["*"] = yank .. " -o --lf" },
		cache_enabled = 1,
	}
else
	-- Stable fallback with PowerShell
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
		cache_enabled = 1,
	}
end

vim.opt.clipboard = "unnamedplus"

-- Shell configuration for Windows
if vim.fn.executable("pwsh") == 1 then
	vim.opt.shell = "pwsh.exe"
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = '"'
	vim.opt.shellxquote = '"'
	vim.opt.shellpipe = "| Out-File -Encoding UTF8 %s"
	vim.opt.shellredir = "| Out-File -Encoding UTF8 %s"
elseif vim.fn.executable("powershell") == 1 then
	vim.opt.shell = "powershell.exe"
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = '"'
	vim.opt.shellxquote = '"'
	vim.opt.shellpipe = "| Out-File -Encoding UTF8 %s"
	vim.opt.shellredir = "| Out-File -Encoding UTF8 %s"
end

-- Optimized shada configuration for Windows
-- Use a safer path and limit size
local shada_path = vim.fn.stdpath("data") .. "/shada"
vim.opt.shadafile = shada_path .. "/main.shada"
vim.opt.shada = "!,'100,<50,s10,h"

-- Function to clean shada more aggressively
local function clean_shada_force()
	local tmp_files = vim.fn.glob(shada_path .. "/*.tmp*", false, true)

	for _, file in ipairs(tmp_files) do
		-- Try to delete multiple times
		for attempt = 1, 3 do
			local ok = os.remove(file)
			if ok then
				break
			elseif attempt == 3 then
				vim.schedule(function()
					vim.notify("Cannot delete shada temp: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.WARN)
				end)
			else
				-- Small pause before retrying
				vim.loop.sleep(100)
			end
		end
	end
end

-- More frequent and early cleanup
vim.defer_fn(function()
	clean_shada_force()
end, 100)

-- Also clean before exit to avoid accumulation
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		local tmp_files = vim.fn.glob(shada_path .. "/*.tmp*", false, true)
		if #tmp_files > 0 then
			clean_shada_force()
		end
	end,
})

-- Clean and save shada
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		vim.cmd("wshada!")
	end,
})
