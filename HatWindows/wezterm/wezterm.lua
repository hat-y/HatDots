local wezterm = require("wezterm")
local act = wezterm.action
local config = {}

-- ====== Básicos ======
config.default_prog = { "pwsh.exe", "-NoLogo" }
config.font = wezterm.font("IosevkaTerm Nerd Font Mono")
config.font_size = 18.0
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { top = 0, right = 0, left = 0, bottom = 0 }
config.max_fps = 120
config.enable_scroll_bar = false
config.window_background_opacity = 0.95
config.front_end = "OpenGL" -- estable en Windows

-- ====== Estado a la derecha: workspace activo ======
wezterm.on("update-right-status", function(window, _)
	window:set_right_status(window:active_workspace())
end)

-- ====== Colores (OldWorld) ======
config.colors = {
	foreground = "#C9C7CD",
	background = "#000000",
	cursor_bg = "#92A2D5",
	cursor_fg = "#C9C7CD",
	cursor_border = "#92A2D5",
	selection_fg = "#C9C7CD",
	selection_bg = "#3B4252",
	scrollbar_thumb = "#4C566A",
	split = "#4C566A",
	ansi = { "#000000", "#EA83A5", "#90B99F", "#E6B99D", "#85B5BA", "#92A2D5", "#85B5BA", "#C9C7CD" },
	brights = { "#4C566A", "#EA83A5", "#90B99F", "#E6B99D", "#85B5BA", "#92A2D5", "#85B5BA", "#C9C7CD" },
	indexed = { [16] = "#F5A191", [17] = "#E29ECA" },
}

-- ====== Helpers: pasar Ctrl-h/l a (n)vim, si no cambiar workspace ======
local function is_vim(pane)
	local p = pane:get_foreground_process_name() or ""
	return p:match("n?vim.exe") or p:match("n?vim$")
end
local function pass_to_vim_or(action, key, mods)
	return wezterm.action_callback(function(win, pane)
		if is_vim(pane) then
			win:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		else
			win:perform_action(action, pane)
		end
	end)
end

-- ====== Keymaps ======
config.keys = {
	-- Splits
	{ key = "+", mods = "ALT|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Mover entre panes
	{ key = "LeftArrow", mods = "ALT|SHIFT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "ALT|SHIFT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "ALT|SHIFT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "ALT|SHIFT", action = act.ActivatePaneDirection("Down") },

	-- Workspaces
	{ key = "9", mods = "ALT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "l", mods = "CTRL", action = pass_to_vim_or(act.SwitchWorkspaceRelative(1), "l", "CTRL") },
	{ key = "h", mods = "CTRL", action = pass_to_vim_or(act.SwitchWorkspaceRelative(-1), "h", "CTRL") },

	-- Copiar/Pegar (por si tu build no trae defaults)
	{ key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- Overlay de debug
	{ key = "D", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
}

-- ====== Nota de compatibilidad ======
-- En builds recientes podés habilitar copia al seleccionar:
-- config.copy_on_select = true

return config
