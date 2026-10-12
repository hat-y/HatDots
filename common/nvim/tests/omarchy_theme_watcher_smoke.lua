-- RED/GREEN smoke test for config.omarchy_theme's fs-event watcher.
-- Run headless: nvim -u NONE -i NONE -l common/nvim/tests/omarchy_theme_watcher_smoke.lua
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(script))))
package.path = root .. "/common/nvim/lua/?.lua;" .. root .. "/common/nvim/lua/?/init.lua;" .. package.path

local tmp = vim.fn.tempname()

local function remove_tmp()
	vim.fn.delete(tmp, "rf")
end

local ok, err = xpcall(function()
	-- Fixture: two theme dirs, `current` is a symlink to one of them - the
	-- same shape as the real ~/.config/omarchy.
	vim.fn.mkdir(tmp .. "/themes/dragon/theme", "p")
	vim.fn.mkdir(tmp .. "/themes/ristretto/theme", "p")
	vim.fn.writefile({ "return { name = 'dragon' }" }, tmp .. "/themes/dragon/theme/neovim.lua")
	vim.fn.writefile({ "return { name = 'ristretto' }" }, tmp .. "/themes/ristretto/theme/neovim.lua")
	vim.fn.system({ "ln", "-sfn", tmp .. "/themes/dragon", tmp .. "/current" })
	assert(vim.v.shell_error == 0, "failed to create the initial `current` symlink fixture")

	vim.env.OMARCHY_DIR = tmp
	package.loaded["config.omarchy_theme"] = nil
	local omarchy_theme = require("config.omarchy_theme")
	assert(omarchy_theme.available() == true, "fixture sanity check: initial theme should resolve")

	local fired = false
	local handle = omarchy_theme.watch(function()
		fired = true
	end, { debounce_ms = 20 })

	assert(handle ~= nil, "watch() should return a handle for an existing directory")

	-- Simulate `omarchy-theme-set`: relink `current` to point elsewhere.
	-- This is an unlink+relink of a direct child of the watched directory,
	-- not an edit to a file several levels down.
	vim.defer_fn(function()
		vim.fn.system({ "ln", "-sfn", tmp .. "/themes/ristretto", tmp .. "/current" })
	end, 50)

	local waited_ok = vim.wait(2000, function()
		return fired
	end, 20)

	handle.stop()
	assert(waited_ok and fired, "watcher callback did not fire within the timeout after the theme switch")
end, debug.traceback)

remove_tmp()
assert(ok, err)
print("omarchy theme watcher smoke passed")
