# herdr — HatDots/HatMac

[herdr](https://github.com/herdrdev/herdr) es un runtime persistente para terminales donde corren agentes de IA (Claude Code, Codex, Cursor, OpenCode, Grok). Es un binario Rust que corre como daemon: las terminales viven adentro, sobreviven cierres de tapa, caídas de red y reinicios.

## ¿Por qué lo incluye HatMac?

Si trabajás con agentes de IA en terminal, herdr te da:
- **Persistencia real**: tu sesión de Claude Code sigue corriendo aunque cierres la laptop o se corte la red.
- **Visibilidad de estado**: cada pane está marcado como `working`, `blocked` o `idle` — sabés qué agente espera input tuyo.
- **Reanudación nativa**: al restaurar sesión, retoma la conversación del agente (no la pierde).
- **Mouse + teclado**: prefix tmux-style (`ctrl+b`) y clicks/drags/splits.

**NO reemplaza a tmux.** Convive con tu setup:
- **tmux** = sesión de trabajo (nvim, shell, scripts)
- **herdr** = capa de agentes de IA persistentes

Si solo usás agentes desde tu laptop y nunca perdés sesiones, probablemente no lo necesites. Si te pasó de perder una conversación de Claude Code de 2 horas porque se te cerró la tapa, lo necesitás.

## Instalación

Ya está en el `Brewfile` de HatMac:
```bash
brew install herdr      # o ./link-mac.sh
```

Alternativas (sin brew):
```bash
curl -fsSL https://herdr.dev/install.sh | sh
mise use -g herdr
```

## Auto-arranque en boot/login (LaunchAgent)

Para que herdr server arranque automáticamente al hacer login (sin abrir terminal) y sobreviva reinicios:

```bash
./HatMac/herdr/install.sh             # instala + carga el LaunchAgent
./HatMac/herdr/install.sh --restart   # recarga después de cambiar config
./HatMac/herdr/install.sh --uninstall # desinstala
```

**Lo que hace:**
- Detecta el path del binario herdr (`/opt/homebrew/bin/herdr` o `/usr/local/bin/herdr`).
- Genera `~/Library/LaunchAgents/com.user.herdr.plist` con `herdr server`.
- Lo carga con `launchctl load -w` (persiste entre logins).
- Configura `KeepAlive` para que re-arranque si crashea.

**Verificación:**
```bash
launchctl list | grep herdr           # debe mostrar com.user.herdr
herdr status server                   # debe decir "running"
tail -f ~/Library/Logs/herdr/server.log
```

**Si querés saltarlo durante `./link-mac.sh`:**
```bash
./link-mac.sh --no-herdr-autostart
```

**Integración con Ghostty/WezTerm:**
El `HatMac/ghostty/config` y `HatMac/wezterm/wezterm.lua` ya tienen:
```
command = /opt/homebrew/bin/herdr
```
Cuando abrís el terminal, Ghostty/WezTerm ejecutan `herdr` → si el server está corriendo (LaunchAgent), hace attach; si no, crea uno nuevo + attach.

**tmux queda como herramienta interna:** dentro de cualquier pane de herdr podés correr `tmux` si necesitás splits/workspaces adicionales. La sesión "main" de tmux sigue configurada por si querés usarla.

## Uso básico

```bash
herdr                          # inicia (o re-attacha si ya hay server)
ctrl+b q                       # detach (el server sigue corriendo)
herdr                          # re-attach desde otra terminal / SSH
herdr --help                   # ver todos los comandos
```

Adentro de herdr (con prefix `ctrl+b`):
- `prefix + c` — nuevo pane
- `prefix + %` — split vertical
- `prefix + "` — split horizontal
- `prefix + h/j/k/l` — focus entre panes (vim-style)
- `prefix + n/p` — siguiente/anterior pane
- `prefix + ,` — renombrar pane
- `prefix + x` — cerrar pane
- `prefix + ?` — ayuda de keybinds

Custom de HatDots (definidos en `config.toml`):
- `prefix + g` — `ghostty-tmux-new` (nueva sesión tmux en ghostty)
- `prefix + shift + t` — `tmux-work` (sesión Work con 3 windows)
- `prefix + shift + n` — `hat-news` (RSS headlines)
- `prefix + shift + o` — abrir Obsidian

## Config

Ubicación: `~/.config/herdr/config.toml` (symlink a `HatMac/herdr/config.toml` via `link-mac.sh`).

Override por env:
```bash
HERDR_CONFIG_PATH=/custom/path/config.toml herdr
```

La config de HatMac está optimizada para integrarse con el resto:
- `[terminal] default_shell = "/bin/zsh"` — matchea `HatMac/zsh/.zshrc`
- `[theme] name = "kanagawa"` — mismo theme que wezterm y tmux Gentleman
- `[keys] prefix = "ctrl+b"` — mismo prefix que tmux (⚠️ si corrés herdr DENTRO de tmux, cambiá uno de los dos prefix)
- Custom keybinds que llaman scripts del repo (tmux-work, hat-news, etc.)

## Temas

18 themes built-in. Para listarlos:
```bash
herdr theme list
```

Cambiar:
```toml
[theme]
name = "kanagawa"  # o catppuccin, tokyo-night, dracula, nord, gruvbox, etc.
```

## Marketplace de plugins

[herdr.dev/plugins/](https://herdr.dev/plugins/) — plugins comunitarios para extender panes y workflows.

## Agentes soportados

Claude Code, Codex, Cursor, OpenCode, Grok, y más. Lista completa: [herdr.dev/docs/agents/](https://herdr.dev/docs/agents/).

Los agentes se conectan vía socket API — ver [herdr.dev/docs/socket-api/](https://herdr.dev/docs/socket-api/).

## Troubleshooting

### "Address already in use" al hacer `herdr`
Ya hay un server corriendo. Hacé `herdr` (sin flag) para re-attachear, o matá el server con `pkill herdr-server`.

### Conflicto de prefix con tmux
Si herdr corre dentro de tmux, ambos tienen `prefix = ctrl+b`. Cambiá uno:
- En herdr: editá `[keys] prefix = "ctrl+a"` en `config.toml`
- En tmux: editá `set -g prefix C-a` en `~/.tmux.conf` y reiniciá tmux (`prefix + R`)

### Ver logs
```bash
~/.local/state/herdr/server.log      # o donde diga `herdr info`
herdr info                           # muestra paths de log/state/config
```

### Reset completo (⚠️ pierde sesiones)
```bash
rm -rf ~/.config/herdr ~/.local/state/herdr
herdr                                 # vuelve a generar config default
```

## Links

- [Repo](https://github.com/herdrdev/herdr)
- [Docs](https://herdr.dev/docs/)
- [Quick start](https://herdr.dev/docs/quick-start/)
- [Configuration](https://herdr.dev/docs/configuration/)
- [Plugins](https://herdr.dev/plugins/)
