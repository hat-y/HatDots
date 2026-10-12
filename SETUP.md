# HatDots — Referencia Técnica

Documentación interna para debugging y casos borde. Para reinstalación, ver [README.md](README.md).

Este repositorio contiene dotfiles multiplataforma para **Linux**, **Windows** y **macOS** con Neovim (LazyVim), terminales, shells y herramientas de productividad.

> **🆕 macOS** — La rama `omarchy-config-merge` trae configs de Hyprland. `HatMac/` es un subset portable de esa rama, **sin** WM/keybinds globales (elección consciente: minimal). Ver `HatMac/README.md` para el detalle.

## Alcance portable y HatNotes

HatDots guarda configuraciones; **HatNotes** es un vault de Obsidian separado. Ningún instalador de HatDots clona, enlaza ni respalda el vault.

### macOS (HatMac)
```bash
# 1. Instalar Homebrew (si no lo tenés)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clonar y correr el installer (el path no importa, el script auto-detecta)
git clone https://github.com/hat-y/HatDots.git ~/projects/HatDots
cd ~/projects/HatDots
chmod +x link-mac.sh
./link-mac.sh          # corre brew bundle + crea symlinks

# Flags útiles:
#   ./link-mac.sh --no-brew    # ya tenés las deps
#   ./link-mac.sh --no-cask    # no instala Ghostty/WezTerm
```

> HatMac es **minimal**: Ghostty/WezTerm + tmux + nvim + zsh + newsboat.
> **No** incluye tiling WM (yabai/skhd) ni keybinds globales estilo Hyprland.

### Windows
```powershell
# Clonar el repositorio
git clone https://github.com/hat-y/HatDots.git $HOME\HatDots

# Ejecutar script (instala dependencias + crea symlinks)
cd $HOME\HatDots
.\link-windows.ps1
```

### Linux
```bash
# Clonar el repositorio
git clone https://github.com/hat-y/HatDots.git $HOME/HatDots

# Ejecutar script (instala dependencias + crea symlinks)
cd $HOME/HatDots
chmod +x link-linux.sh
./link-linux.sh
```

HatNotes es un compañero **requerido solo para los comandos de creación de Obsidian/Neovim**. Antes de usarlos, cloná o sincronizá HatNotes y verificá que las diez plantillas estén en `$HATNOTES_PATH/7-Tmpl`; el resto de los dotfiles de HatDots sigue siendo usable sin HatNotes.

Las configuraciones de Obsidian para Neovim en Linux y Windows resuelven `HATNOTES_PATH` con expansión de Neovim y usan `~/HatNotes` si la variable no está definida. Definila antes de abrir Neovim cuando el vault esté en otra ubicación. El runtimepath encuentra `shared/nvim` desde el symlink o junction de la configuración de cada plataforma.

| Plataforma | Límite actual |
|------------|---------------|
| Linux | Soportado para el flujo basado en Omarchy y `link-linux.sh`. |
| Windows | `link-windows.ps1` enlaza Neovim, WezTerm, el perfil de PowerShell y Starship; no tiene paridad con Linux ni configura Omarchy, Ghostty, Zsh, Tmux o Herdr. |
| macOS | Fuera de alcance. |

`link-linux.sh` respalda archivos/directorios que reemplaza como `*.bak.<timestamp>`, conserva symlinks existentes y no sobrescribe Ghostty ni launchers; un symlink existente de `.p10k.zsh` se elimina sin backup al copiarlo. `link-windows.ps1` elimina los destinos existentes que enlaza y no crea backups.

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
├── HatWindows/                     # Configuración inicial de Neovim, WezTerm y PowerShell
├── shared/
│   └── starship.toml               # Kanagawa Dragon (disponible, no activo)
├── link-linux.sh                   # Symlinks base
├── link-windows.ps1                # Reemplaza destinos sin backups
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

## 📋 Requisitos (desde feat/harmac-config, pendiente de consolidar)

### Windows
```powershell
# Herramientas principales
winget install -e --id Git.Git
winget install -e --id Neovim.Neovim
winget install -e --id WezTerm.WezTerm
winget install -e --id Starship.Starship

# Búsqueda y navegación
winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id sharkdp.fd
winget install -e --id JesseDuffield.lazygit

# Desarrollo (recomendado)
winget install -e --id Zig.Zig
winget install -e --id LLVM.LLVM

# Opcional: para mejor experiencia
winget install -e --id eza-community.eza
winget install -e --id ajeetdsouza.zoxide
```

### Linux (Fedora/KDE Plasma)
```bash
# Instalar dependencias
sudo dnf install neovim git zsh ripgrep fd-find eza zoxide fzf atuin

# Instalar Powerlevel10k
sudo dnf install zsh-theme-powerlevel10k
```

### Linux (Debian/Ubuntu/Debian-based)
```bash
# Instalar dependencias
sudo apt update
sudo apt install neovim git zsh ripgrep fd-find eza zoxide fzf

# Instalar Atuin
curl -Ls https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-musl.tar.gz | sudo tar xz -C /usr/local/bin/

# Instalar Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.local/share/zsh/powerlevel10k
```

### Linux (NixOS/Home Manager)
```nix
# En your home.nix
home.packages = with pkgs; [
  neovim git zsh ripgrep fd eza zoxide fzf atuin
];
```

### Linux (Arch/derivados)
```bash
# Paquetes principales
sudo pacman -S neovim git zsh ripgrep fd

# Opcionales recomendados
sudo pacman -S eza zoxide atuin fzf
```

### Linux (openSUSE)
```bash
# Instalar dependencias
sudo zypper install neovim git zsh ripgrep fd

# Instalar herramientas adicionales
sudo zypper install eza zoxide fzf

# Instalar Atuin
curl -Ls https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-musl.tar.gz | sudo tar xz -C /usr/local/bin/
```

## 🎨 Características Principales (desde feat/harmac-config)

### Neovim (LazyVim)
- **Plugins de IA**: Copilot, Claude Code, Avante, Gemini CLI (solo Windows) — nota: a remover en fase 3 de unify.
- **Lenguajes**: TypeScript, Python, Rust soporte completo
- **Productividad**: Telescope, Oil (navegador de archivos), LazyGit
- **UI**: Tema Kanagawa, Treesitter, formateo automático
- **Platform-aware**: Detecta Windows/Linux y carga plugins accordingly

### Terminal y Shell
- **Windows**: WezTerm + PowerShell + Starship
- **Linux**: WezTerm o Ghostty + Zsh + Powerlevel10k
- **Multiplexor**: Tmux (Linux)

### WezTerm (Linux + Windows)
- Terminal multiplataforma moderno con splits vim-like
- Tema Kanagawa Dragon
- Configuración idéntica en ambas plataformas

### Ghostty (Linux - opcional)
- Terminal moderno (manual installation required)
- Si lo usás: agregá a tu config los keybinds de splits

### Escritorio Completo (Arch Linux + Hyprland)
- **Compositor**: Hyprland con configuración modular
- **Temas**: DenAsari y Mocha-Power
- **Herramientas**: Waybar, Wofi, SwayNC, Yazi, Fastfetch

## 🔧 Configuración Post-Instalación (desde feat/harmac-config)

### Neovim - Primer arranque
1. Abre Neovim
2. Lazy instalará plugins automáticamente
3. Ejecuta `:Mason` para instalar servidores LSP
4. Instala formateadores: `:MasonInstall prettierd stylua ruff`
5. Actualiza Treesitter: `:TSUpdate`

### Claves API (Plugins de IA - Windows)
Configura las variables de entorno para plugins de IA:
- Gemini: `GEMINI_API_KEY`
- Claude: `ANTHROPIC_API_KEY`
- Ver guía completa en `HatWindows/API_KEYS.md`

### Fonts
Installa una Nerd Font para soporte de iconos:
- **Windows**: `winget install NerdFonts.FiraCode`
- **Linux**: Busca en repositorios o descarga desde Nerd Fonts

## ⌨️ Atajos Útiles (desde feat/harmac-config)

### Neovim
- `<leader>ff` - Buscar archivos
- `<leader>fg` - Búsqueda global
- `<leader>gg` - Abrir LazyGit
- `<leader>cf` - Formatear código
- `-` - Abrir Oil (navegador de archivos)
- `<leader>aa` - Toggle Avante (IA, Windows)
- `<leader>ac` - Toggle Claude Code (Windows)

### WezTerm (Linux + Windows)
- `Ctrl+Space h/l` - Cambiar workspace
- `Ctrl+Space flechas` - Navegar panes
- `Ctrl+Space -/+` - Dividir vertical/horizontal
- `Ctrl+Space n` - Workspace "notes"
- `Ctrl+Space d` - Workspace "dev"

### Ghostty (Linux - si lo usás)
- `Alt + -` - Split vertical (abajo)
- `Alt + Shift + =` - Split horizontal (derecha)
- `Alt + h/j/k/l` - Navegar entre splits
- `Alt + z` - Zoom split actual
- `Ctrl + Shift + t` - Nueva pestaña
- `Ctrl + PageUp/PageDown` - Cambiar pestaña

## 🐛 Problemas Comunes (desde feat/harmac-config)

### Windows
- **Symlinks**: Habilita Modo Desarrollador para crear symlinks sin admin
- **Build errors**: Asegúrate de tener Zig y LLVM instalados
- **API Keys**: Configura las claves para plugins de IA

### Linux
- **Permisos**: Asegúrate que los scripts tengan permisos de ejecución
- **Dependencias**: Instala las dependencias faltantes de tu distribución

## 🤝 Contribuciones (desde feat/harmac-config)

Las mejoras son bienvenidas:
- Reporta issues
- Envía pull requests
- Sugiere nuevas configuraciones

## 📄 Licencia

MIT License - Siéntete libre de usar, modificar y distribuir.