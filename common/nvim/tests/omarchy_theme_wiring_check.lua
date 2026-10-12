-- Integration check: run with the FULL config loaded, e.g.
--   nvim --headless "+luafile tests/omarchy_theme_wiring_check.lua"
-- On an Omarchy machine the theme watcher must be running after startup.
local theme = require("config.omarchy_theme")

if not theme.is_omarchy() then
	print("omarchy theme wiring check skipped (not omarchy)")
	vim.cmd("qa!")
	return
end

if theme.active_watch == nil then
	io.stderr:write("FAIL: omarchy theme watcher is not running after startup\n")
	vim.cmd("cquit 1")
	return
end

print("omarchy theme wiring check passed")
vim.cmd("qa!")
