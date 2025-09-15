local wezterm = require("wezterm")
local act = wezterm.action
local config = {}

-- ===== Básicos =====
config.default_prog = { "pwsh.exe", "-NoLogo" }
config.font = wezterm.font("IosevkaTerm Nerd Font Mono")
config.font_size = 18.0
config.window_padding = { top = 0, right = 0, left = 0, bottom = 0 }
config.hide_tab_bar_if_only_one_tab = true
config.max_fps = 120
config.enable_scroll_bar = false
config.window_background_opacity = 0.95
config.front_end = "OpenGL" -- estable en Windows

-- Mostrar workspace activo a la derecha
wezterm.on("update-right-status", function(window, _)
	window:set_right_status(window:active_workspace())
end)

-- ===== Kanagawa Dragon (colores) =====
config.colors = {
	foreground = "#DCD7BA", -- fujiWhite
	background = "#000000",
	cursor_bg = "#C8C093",
	cursor_fg = "#181616",
	cursor_border = "#C8C093",
	selection_bg = "#2A2A37", -- sumiInk2
	selection_fg = "#DCD7BA",
	scrollbar_thumb = "#2A2A37",
	split = "#2A2A37",
	ansi = {
		"#181616", -- black
		"#C34043", -- red (autumnRed)
		"#98BB6C", -- green (springGreen)
		"#E6C384", -- yellow (carpYellow)
		"#7E9CD8", -- blue (crystalBlue)
		"#957FB8", -- magenta (oniViolet)
		"#7AA89F", -- cyan (waveAqua2)
		"#C8C093", -- white (oldWhite)
	},
	brights = {
		"#2A2A37", -- bright black
		"#E82424", -- bright red (samuraiRed)
		"#A7C080", -- bright green
		"#FF9E3B", -- bright yellow (autumnYellow)
		"#8CAAEE", -- bright blue
		"#A292BA", -- bright magenta
		"#7FC8C2", -- bright cyan
		"#DCD7BA", -- bright white
	},
	tab_bar = {
		background = "#181616",
		new_tab = { bg_color = "#181616", fg_color = "#C8C093" },
		new_tab_hover = { bg_color = "#2A2A37", fg_color = "#DCD7BA", italic = true },
		active_tab = { bg_color = "#1F1F28", fg_color = "#DCD7BA", intensity = "Bold" },
		inactive_tab = { bg_color = "#181616", fg_color = "#C8C093" },
		inactive_tab_hover = { bg_color = "#2A2A37", fg_color = "#DCD7BA" },
	},
}

-- ===== Helpers: detectar (n)vim y enrutar teclas =====
local function is_vim(pane)
	local p = pane:get_foreground_process_name() or ""
	return p:match("n?vim.exe") or p:match("n?vim$")
end

-- Si estás en Neovim -> enviar la tecla a Neovim
-- Si NO -> ejecutar la acción de WezTerm (p.ej. cambiar workspace)
local function pass_to_vim_or(action, key, mods)
	return wezterm.action_callback(function(win, pane)
		if is_vim(pane) then
			win:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		else
			win:perform_action(action, pane)
		end
	end)
end

-- ===== Keymaps =====
-- Leader de WezTerm (como tmux): Ctrl+Space
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- Debug overlay (para inspeccionar qué evento llega)
	{ key = "F12", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },

	-- Workspaces con LEADER (recomendado, cero conflictos con Neovim/Obsidian)
	{ key = "h", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
	{ key = "l", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },

	-- Panes con LEADER + flechas
	{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "+", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	{ key = "9", mods = "ALT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- ==== Ctrl+h / Ctrl+l "inteligentes" ====
	{ key = "h", mods = "CTRL", action = pass_to_vim_or(act.SwitchWorkspaceRelative(-1), "h", "CTRL") },
	{ key = "Backspace", mods = "CTRL", action = pass_to_vim_or(act.SwitchWorkspaceRelative(-1), "h", "CTRL") },
	{ key = "l", mods = "CTRL", action = pass_to_vim_or(act.SwitchWorkspaceRelative(1), "l", "CTRL") },
}

return config
