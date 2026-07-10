# HatDots — Referencia Técnica

Documentación interna para debugging y casos borde. Para reinstalación, ver [README.md](README.md).

## Estructura del repo

```
HatDots/
├── terminals/
│   ├── tmux/
│   │   └── tmux.conf              # Omarchy style + HatDots TPM plugins
│   └── ghostty/
│       ├── config                  # Referencia de config
│       ├── shaders/                # 52 shaders GLSL
│       └── themes/
├── HatLinux/
│   ├── nvim/                       # LazyVim completo
│   │   ├── lua/plugins/
│   │   │   ├── theme.lua           # Aether (activo)
│   │   │   ├── all-themes.lua      # 20 themes (lazy)
│   │   │   ├── theme-hotreload.lua # Hot-reload de themes
│   │   │   ├── colorscheme.lua     # Desactivado (oxocarbon/kanagawa comentados)
│   │   │   └── ...                 # LSP, DAP, keymaps, etc.
│   │   └── plugin/after/
│   │       └── transparency.lua   # Fondos transparentes
│   └── zsh/
│       ├── .zshrc                  # Referencia
│       └── .p10k.zsh               # Powerlevel10k custom
├── shared/
│   └── starship.toml               # Kanagawa Dragon (disponible, no activo)
├── link-linux.sh                   # Symlinks base
└── README.md                       # Guía de reinstalación
```

## Archivos modificados vs Omarchy stock

Estos archivos **NO son symlinks** a HatDots — están editados directamente en `~`:

```
~/.config/ghostty/config          — Fused: Omarchy theme + HatDots shader + tmux launch
~/.config/hypr/bindings.lua       — Omarchy base + launcher overrides
~/.zshrc                          — CachyOS base + HatDots additions
~/.config/uwsm/default            — TERMINAL=ghostty
~/.local/bin/hatdots-launch-terminal
~/.local/bin/hatdots-launch-terminal-tmux
~/.local/bin/tmux-session-layout
~/.p10k.zsh                       — Copiado de HatDots
```

## Tmux

### Config
`~/.config/tmux/tmux.conf` → symlink a `HatDots/terminals/tmux/tmux.conf`

Base: **Omarchy** (keybindings, status bar, pane style, base-index 1, aggressive-resize)

HatDots sobre eso:
- `default-shell /bin/zsh` — fuerza zsh (Omarchy usa fish)
- Ctrl+L smart — pasa a vim/fzf o limpia pantalla
- Ctrl+H/j/k/l en copy-mode — navegación de panes
- Scratch popup (`Alt+G`) — sesión "scratch" popup
- TPM plugins: `tmux-sensible`, `tmux-yank`, `vim-tmux-navigator`, `tmux-resurrect`

### Plugins (TPM)
Instalar: `prefix + I` (Ctrl+Space + I) dentro de tmux.

Directorio: `~/.config/tmux/plugins/` (no `~/.tmux/plugins/`)

### Sesión con layout (tmux-session-layout)
```bash
tmux-session-layout [session-name] [cwd]
```
Crea 3 ventanas: nvim | shell | shell

Si la sesión ya existe → attach directo.

## Neovim

### Config
`~/.config/nvim` → symlink a `HatDots/HatLinux/nvim`

Base: **LazyVim** con extras para Python, Prisma, Docker, Angular, Rust.

### Theme: Aether

- **Activo**: `bjarneo/aether.nvim` (v3) — matchea Catppuccin Mocha de Omarchy
- **Transparencia**: `plugin/after/transparency.lua` — fondos nulos en Normal, Float, NvimTree, Telescope, Notify
- **Hot-reload**: `theme-hotreload.lua` — cambiá themes con `:Lazy` → Reload

### 20 themes disponibles
`all-themes.lua` carga todos en lazy (no activos):

aether, bamboo, catppuccin, ethereal, everforest, flexoki-neovim, gruvbox, hackerman, kanagawa, lumon, matteblack, miasma, monokai-pro, nord, retro-82, rose-pine, tokyonight, vantablack, white

### Cambiar theme
1. `:Lazy`
2. Buscar el theme
3. `...` → Reload
4. El hot-reload aplica el cambio sin reiniciar nvim

### Cambiar theme manualmente
```lua
-- En ~/.config/nvim/lua/plugins/theme.lua
-- Cambiar el colorscheme en el bloque LazyVim opts
opts = { colorscheme = "kanagawa" }  -- por ejemplo
```

### Errores de Lazy.nvim post-reinstall
Si aparece `attempt to index field 'updated' (a nil value)`:
```bash
mv ~/.local/share/nvim/lazy/lazy.nvim/.cache ~/.local/share/nvim/lazy/lazy.nvim/.cache.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
```
Luego abrir nvim de nuevo.

## Ghostty

### Config activa
`~/.config/ghostty/config` — editada directamente (no symlink a HatDots).

Componentes:
- **Theme**: `config-file = ?~/.config/omarchy/current/theme/ghostty.conf` (dinámico)
- **Font**: JetBrainsMono Nerd Font 9
- **Padding**: 4px (reducido de 14px default)
- **Shader**: `cursor_smear_gentleman.glsl` (cursor con efecto smear)
- **Shell**: `/bin/zsh` (via `command = tmux-session-layout main`)
- **Auto-launch**: Al abrir Ghostty → tmux con layout nvim|shell|shell

### Shaders
`~/.config/ghostty/shaders` → symlink a `HatDots/terminals/ghostty/shaders`

52 shaders disponibles. Activo: `cursor_smear_gentleman.glsl`

Para cambiar shader: editar `custom-shader = shaders/NOMBRE.glsl` en ghostty config.

### Shell integration
`shell-integration-features = no-cursor,ssh-env`

`no-cursor` puede conflituar con el shader. Si el cursor no se ve bien, probar removerlo.

## Zsh

Base: CachyOS (`/usr/share/cachyos-zsh-config/`)

Lo que HatDots agrega a `~/.zshrc`:

```bash
# Vi mode
bindkey -v
export KEYTIMEOUT=1

# zoxide
eval "$(zoxide init zsh)"

# eza aliases
alias ls='eza --icons=auto --group-directories-first --classify'
alias ll='eza -lh --git --icons=auto --group-directories-first --classify'
alias la='eza -lha --git --icons=auto --group-directories-first --classify'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# PATH extras
export PATH="$HOME/.local/bin:$PATH"
export PATH="/home/hat/.opencode/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

## Troubleshooting

### Ghostty: "unknown field" con --cwd
Ghostty no soporta `--cwd` como flag. Los launchers usan:
```bash
ghostty -e bash -c "cd '$cwd' && exec zsh"
```

### Ghostty: comando fallido al abrir
El `command =` en ghostty config falla si `tmux-session-layout` no existe o no es ejecutable.
Verificar: `ls -la ~/.local/bin/tmux-session-layout`

### Tmux abre fish en vez de zsh
```bash
tmux show-options -g default-shell
# debe ser /bin/zsh
tmux source-file ~/.config/tmux/tmux.conf
```

### Ctrl+L no limpia pantalla
El binding smart está **después** del `run '~/.tmux/plugins/tpm/tpm'` en tmux.conf. Si vim-tmux-navigator lo sobreescribe, reloadear tmux.

### xdg-terminal-exec abre Alacritty
Omarchy instala Alacritty y `uwsm default` busca por orden alfabético. Solución:
```bash
# ~/.config/uwsm/default
export TERMINAL=ghostty
```

### Nvim en caja chiquita
Ghostty tiene `window-padding-x = 4` y `window-padding-y = 4`. Reducir a 0 si querés más espacio.

### Tmux resurrect restaura sesión vieja
```bash
tmux kill-server  # limpia todo
tmux list-sessions  # verificar que no hay nada
```

### Lazy.nvim cache corrupto post-reinstall
```bash
mv ~/.local/share/nvim/lazy/lazy.nvim/.cache ~/.local/share/nvim/lazy/lazy.nvim/.cache.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
nvim
```