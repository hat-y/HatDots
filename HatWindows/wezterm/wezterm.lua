local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- ===== Básicos =====
config.default_prog = { "pwsh.exe", "-NoLogo" }
config.font = wezterm.font("IosevkaTerm Nerd Font Mono")
config.font_size = 20
config.window_padding = { top = 0, right = 0, left = 0, bottom = 0 }
config.hide_tab_bar_if_only_one_tab = true
config.max_fps = 120
config.enable_scroll_bar = false
config.window_background_opacity = 0.95
config.front_end = "OpenGL" -- estable en Windows

-- ===== Comportamiento de Ventana =====
config.window_close_confirmation = "AlwaysPrompt"
config.window_decorations = "RESIZE"
config.adjust_window_size_when_changing_font_size = false
config.initial_rows = 30
config.initial_cols = 120

-- ===== Integración con Sistema =====
config.launch_menu = {
	{
		label = "PowerShell",
		args = { "pwsh.exe", "-NoLogo" },
	},
	{
		label = "PowerShell (Admin)",
		args = { "pwsh.exe", "-NoLogo", "-Command", "Start-Process pwsh.exe -Verb RunAs" },
	},
	{
		label = "Command Prompt",
		args = { "cmd.exe" },
	},
}

-- ===== Animaciones y Transiciones =====
config.animation_fps = 60
config.cursor_blink_rate = 800

-- ===== Auditory Feedback (opcional) =====
config.audible_bell = "Disabled"

-- Mostrar workspace activo a la derecha con más información
wezterm.on("update-right-status", function(window, _)
	local workspace = window:active_workspace()
	local tab_count = #window:mux_tabs()
	local pane_count = 0
	for _, tab in ipairs(window:mux_tabs()) do
		pane_count = pane_count + #tab:panes()
	end
	window:set_right_status(string.format("WS: %s | Tabs: %d | Panes: %d", workspace, tab_count, pane_count))
end)


-- ===== Kanagawa Dragon (colores) =====
config.colors = {
	foreground = "#DCD7BA", -- fujiWhite
	background = "#080808", -- waveBlack (consistente con tema Kanagawa)
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
	return p:match("n?vim%.exe$") or p:match("n?vim$") or p:match("neovim") or p:match("nvim")
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


-- Atajos activos siempre
config.keys = { -- Debug overlay
	{
		key = "F12",
		mods = "CTRL|SHIFT",
		action = act.ShowDebugOverlay,
	},
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },

	-- Workspaces con LEADER - navegación básica
	{ key = "h", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
	{ key = "l", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },

	-- Workspaces con LEADER - gestión avanzada
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "n", mods = "LEADER", action = act.SwitchToWorkspace({ name = "main" }) },
	{ key = "d", mods = "LEADER", action = act.SwitchToWorkspace({ name = "dev" }) },
	{ key = "s", mods = "LEADER", action = act.SwitchToWorkspace({ name = "scratch" }) },

	
	-- Crear nuevo workspace con prompt
	{
		key = "N",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter workspace name:",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(
						act.SwitchToWorkspace({ name = line }),
						pane
					)
				end
			end),
		}),
	},

	-- Mover pane actual a nuevo workspace
	{
		key = "m",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Move pane to workspace:",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(
						act.MoveToNewWorkspace({ name = line }),
						pane
					)
				end
			end),
		}),
	},

	-- Renombrar workspace actual
	{
		key = "r",
		mods = "LEADER|SHIFT",
		action = act.PromptInputLine({
			description = "Rename current workspace:",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					wezterm.mux.rename_workspace(window:active_workspace(), line)
				end
			end),
		}),
	},

	-- Panes con LEADER + flechas
	{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "=", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- Ctrl+h / Ctrl+l inteligentes
	{ key = "h", mods = "CTRL", action = pass_to_vim_or(act.SwitchWorkspaceRelative(-1), "h", "CTRL") },
	{ key = "l", mods = "CTRL", action = pass_to_vim_or(act.SwitchWorkspaceRelative(1), "l", "CTRL") },

	-- Zoom y ajustes de fuente
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	-- Copiado y pegado mejorado
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- Navegación de tabs
	{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },

	-- Pane management mejorado
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- Scrolling rápido
	{ key = "PageUp", mods = "CTRL", action = act.ScrollByPage(-0.5) },
	{ key = "PageDown", mods = "CTRL", action = act.ScrollByPage(0.5) },

	-- Quick actions
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
	{ key = "f", mods = "LEADER", action = act.Search("CurrentSelectionOrEmptyString") },
}
return config
