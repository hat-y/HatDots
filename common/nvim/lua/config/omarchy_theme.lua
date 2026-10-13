-- Omarchy dynamic theming: Ghostty and Neovim follow Omarchy's active theme
-- (user decision - see odd/tasks/hatdots-unify.md, task P3-5).
--
-- Omarchy keeps its current theme at ~/.config/omarchy/current/theme/, with
-- a neovim.lua that returns a lazy.nvim plugin spec. `omarchy-theme-set`
-- switches it by replacing the `current` symlink and sends ghostty SIGUSR2
-- to reload its own config.
--
-- Base dir is overridable via OMARCHY_DIR for tests; defaults to the real
-- Omarchy location otherwise (same pattern as hatnotes.creation's
-- HATNOTES_PATH).
local M = {}

M.base_dir = vim.fn.expand(vim.env.OMARCHY_DIR or "~/.config/omarchy")

--- Full path to the theme spec Omarchy currently points at.
function M.path()
	return M.base_dir .. "/current/theme/neovim.lua"
end

--- True when Omarchy's neovim.lua theme spec exists and is readable.
function M.available()
	return vim.fn.filereadable(M.path()) == 1
end

--- True when this machine is running Omarchy at all (same marker
--- directory the hatdots installer uses, via platform.DetectOmarchy, to
--- decide whether to link the os/omarchy/* overlays). Overridable via
--- OMARCHY_SHARE_DIR for tests, same pattern as OMARCHY_DIR.
function M.is_omarchy()
	local share_dir = vim.fn.expand(vim.env.OMARCHY_SHARE_DIR or "~/.local/share/omarchy")
	return vim.fn.isdirectory(share_dir) == 1
end

--- Return Omarchy's current theme spec (`dofile`d) when available, else the
--- given fallback spec unchanged.
function M.spec(fallback)
	if not M.available() then
		return fallback
	end

	local ok, spec = pcall(dofile, M.path())
	if not ok or spec == nil then
		vim.notify("config.omarchy_theme: failed to load " .. M.path() .. ": " .. tostring(spec), vim.log.levels.WARN)
		return fallback
	end

	return spec
end

--- Watch Omarchy's own config directory (`~/.config/omarchy`, the parent of
--- `current`) for changes, debounced, and invoke `callback` on change.
---
--- We watch this directory rather than `current/theme/neovim.lua` itself,
--- or even `current`, because `omarchy-theme-set` replaces the `current`
--- symlink wholesale (unlink + relink) instead of editing it in place. A
--- watch on the symlink's target would go stale the moment the symlink is
--- repointed; `current` is a direct child of this directory, so a
--- non-recursive watch here (the only kind inotify reliably supports on
--- Linux) still sees the symlink get replaced.
---
--- Returns a handle with a `:stop()` method, or nil if the directory to
--- watch doesn't exist.
---@param callback fun()
---@param opts { debounce_ms?: integer, dir?: string }|nil
function M.watch(callback, opts)
	opts = opts or {}
	local debounce_ms = opts.debounce_ms or 200
	local dir = opts.dir or M.base_dir

	if vim.fn.isdirectory(dir) == 0 then
		return nil
	end

	local uv = vim.uv or vim.loop
	local handle = uv.new_fs_event()
	local timer = uv.new_timer()
	local stopped = false

	local function on_event()
		if stopped then
			return
		end
		timer:stop()
		timer:start(debounce_ms, 0, function()
			vim.schedule(function()
				if not stopped then
					callback()
				end
			end)
		end)
	end

	handle:start(dir, {}, function(err)
		if err then
			return
		end
		on_event()
	end)

	return {
		stop = function()
			stopped = true
			pcall(function()
				timer:stop()
				timer:close()
			end)
			pcall(function()
				handle:stop()
				handle:close()
			end)
		end,
	}
end

return M
