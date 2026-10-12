-- RED/GREEN smoke test for lua/config/omarchy_theme.lua.
-- Run headless: nvim -u NONE -i NONE -l common/nvim/tests/omarchy_theme_smoke.lua
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(script))))
package.path = root .. "/common/nvim/lua/?.lua;" .. root .. "/common/nvim/lua/?/init.lua;" .. package.path

local tmp_present = vim.fn.tempname()
local tmp_absent = vim.fn.tempname()

local function remove_tmp()
	vim.fn.delete(tmp_present, "rf")
	vim.fn.delete(tmp_absent, "rf")
end

local ok, err = xpcall(function()
	-- Fixture 1: a directory with a theme present.
	vim.fn.mkdir(tmp_present .. "/current/theme", "p")
	vim.fn.writefile({
		'return { { "folke/tokyonight.nvim", lazy = false, priority = 1000 } }',
	}, tmp_present .. "/current/theme/neovim.lua")

	vim.env.OMARCHY_DIR = tmp_present
	-- Force a reload: clear any cached module from a previous require.
	package.loaded["config.omarchy_theme"] = nil
	local omarchy_theme = require("config.omarchy_theme")

	assert(
		omarchy_theme.path() == tmp_present .. "/current/theme/neovim.lua",
		"path() did not resolve OMARCHY_DIR"
	)
	assert(omarchy_theme.available() == true, "available() should be true when neovim.lua exists")

	vim.env.OMARCHY_SHARE_DIR = tmp_present
	assert(omarchy_theme.is_omarchy() == true, "is_omarchy() should be true when the share dir exists")
	vim.env.OMARCHY_SHARE_DIR = tmp_absent
	assert(omarchy_theme.is_omarchy() == false, "is_omarchy() should be false when the share dir is missing")

	local fallback = { { "rebelot/kanagawa.nvim" } }
	local spec = omarchy_theme.spec(fallback)
	assert(spec[1][1] == "folke/tokyonight.nvim", "spec() did not dofile the Omarchy theme spec")

	-- Fixture 2: no Omarchy theme directory at all -> falls back.
	-- base_dir is resolved once at require time (same pattern as
	-- hatnotes.creation's vault_path), so re-require after changing the env.
	vim.env.OMARCHY_DIR = tmp_absent
	package.loaded["config.omarchy_theme"] = nil
	local omarchy_theme_absent = require("config.omarchy_theme")

	assert(omarchy_theme_absent.available() == false, "available() should be false when neovim.lua is missing")
	local spec2 = omarchy_theme_absent.spec(fallback)
	assert(spec2 == fallback, "spec() did not return the fallback when Omarchy theme is unavailable")
end, debug.traceback)

remove_tmp()
assert(ok, err)
print("omarchy theme smoke passed")
