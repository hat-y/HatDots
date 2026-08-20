# HatDots — HatMac 🍎

Dotfiles para macOS, adaptados desde la rama `omarchy-config-merge` de HatDots.

## ⚠️ Alcance y decisiones

**HatMac es minimal y consciente.** Está armado para vivir **dentro de Ghostty** (+ tmux + Neovim) y **no intenta reemplazar el WM nativo de macOS**.

### Lo que **NO** se incluye (a propósito)

| Omarchy (Linux)              | Por qué no en Mac                                  |
|------------------------------|----------------------------------------------------|
| Hyprland compositor          | No existe en macOS                                 |
| `hypr/bindings.lua` (SUPER+X)| No hay compositor que capture keybinds globales    |
| Yabai + skhd tiling          | Elegiste **minimal** (sin tiling WM)               |
| Karabiner-Elements           | Elegiste **minimal** (sin mapeos a nivel teclado)  |
| Omarchy theme hot-reload     | Omarchy es una distro específica, no corre en Mac  |
| Autostart Hyprland           | Sin compositor, no hay dónde colgar autostart      |
| Walker / Wofi launcher       | Usá Spotlight (⌘Space) o Raycast                   |
| `omarchy-launch-webapp`      | En Mac: Safari Profiles o Chromium con `--app=`    |

### Lo que **SÍ** está incluido

- ✅ **Neovim (LazyVim)** — config completa con Omarchy hot-reload omitido (no aplica)
- ✅ **Zsh + Powerlevel10k** — paths adaptados a Homebrew
- ✅ **Atuin** (history sync), **eza**, **zoxide**, **fzf**, **ripgrep**, **fd**
- ✅ **tmux** con TPM, continuum, tmux-resurrect + scripts (`tmux-work`, `ghostty-tmux-new`)
- ✅ **Ghostty** config completa (Gentleman Theme palette + macos-option-as-alt + Cmd+K clear + 52 shaders)
- ✅ **Newsboat** + script `hat-news` con notificaciones nativas vía `osascript`

## � Instalación

### Prerequisito: Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Instalación completa (recomendada)

Desde la raíz del repo:

```bash
chmod +x link-mac.sh
./link-mac.sh
```

Esto corre `brew bundle --file HatMac/Brewfile` y crea todos los symlinks con backups timestamped.

### Instalación parcial

```bash
./link-mac.sh --no-brew    # ya tenés las deps instaladas
./link-mac.sh --no-cask    # no instala Ghostty (ya lo tenés)
```

## 📁 Estructura

```
HatMac/
├── README.md                 # este archivo
├── Brewfile                  # dependencias Homebrew
├── zsh/
│   ├── .zshrc                # paths Homebrew-aware (Apple Silicon + Intel)
│   └── .p10k.zsh             # tema Powerlevel10k (configurable con p10k configure)
├── tmux/
│   ├── tmux.conf             # Gentleman theme + TPM + continuum + vi-mode
│   └── scripts/
│       ├── tmux-work             # sesión Work con 3 windows (nvim/shell/pi)
│       └── ghostty-tmux-new      # nueva sesión en ghostty (Ctrl+Space N)
├── ghostty/
│   ├── config                # command = herdr + Gentleman theme palette + Cmd+K clear
│   ├── shaders/              # 52 shaders GLSL
│   └── themes/               # catppuccin-mocha
├── newsboat/
│   ├── config                # browser = "open %u" (macOS nativo)
│   ├── urls                  # feeds: Google News AR/US, HN, LWN, Ars, etc.
│   └── hat-news              # script: headlines + osascript notif
├── herdr/
│   ├── config.toml           # kanagawa theme + prefix=ctrl+b + custom keybinds
│   └── README.md             # qué es, instalación, atajos, troubleshooting
└── nvim/                     # LazyVim completo
    ├── init.lua              # con rama is_mac explícita
    ├── lua/config/
    │   └── options.lua       # clipboard: pbcopy/pbpaste + reattach-to-user-namespace fallback
    └── lua/plugins/          # TODO el set de plugins Omarchy
        (excepto omarchy-theme-hotreload.lua que no aplica)
```

## ⌨️ Atajos (dentro del terminal)

### Ghostty
- `Shift+Insert` — pegar
- `Ctrl+Insert` — copiar
- `Super+F` — toggle maximize
- `Shift+Enter` — escape + enter (útil en vim)

### tmux (prefix: `Ctrl+Space`)
- `Ctrl+Space h/l` — workspace anterior/siguiente
- `Ctrl+Space -/=` — split vertical/horizontal
- `Ctrl+Space n/d/s` — workspaces "notes" / "dev" / "scratch"
- `Alt+1..9` — switch window por número
- `Alt+Left/Right` — ventana anterior/siguiente
- `Ctrl+Alt+Arrow` — mover foco entre panes
- `Ctrl+Alt+Shift+Arrow` — resize panes
- `Ctrl+Space N` — nueva sesión (vía `ghostty-tmux-new`)
- `Ctrl+Space R` — reload tmux.conf
- `Ctrl+Space q` — reload config

### Neovim (LazyVim defaults)
- `<leader>ff` — Telescope find files
- `<leader>fg` — Telescope grep
- `<leader>gg` — LazyGit
- `<leader>cf` — Format
- `-` — Oil file explorer
- `<C-h/j/k/l>` — navegar windows
- `<C-w>v/-` — split vertical/horizontal

### Shell (zsh)
- `Ctrl+R` — atuin history search (descomentar en `.zshrc`)
- `Ctrl+T` — fzf file picker
- `Alt+C` — fzf cd
- `z <dir>` — zoxide jump

## 🐛 Troubleshooting

### El portapapeles no anda en tmux
Si pegás desde tmux y no funciona, instalá:
```bash
brew install reattach-to-user-namespace
```
El `options.lua` de nvim ya tiene fallback automático para esto.

### Ghostty no encuentra `tmux`
Verificá:
```bash
which tmux
# Debería devolver /opt/homebrew/bin/tmux (Apple Silicon) o /usr/local/bin/tmux (Intel)
```
Si usás `brew bundle` debería estar. Si no, editá `HatMac/ghostty/config` y cambiá la línea `command = ...`.

### Newsboat no abre links
```bash
brew install newsboat
# Verificá:
newsboat --version
```

### p10k no se ve bien en terminal
```bash
p10k configure
```

### Quiero tiling estilo Hyprland
HatMac es minimal a propósito. Si más adelante querés replicar SUPER+RETURN, SUPER+h/j/k/l, etc. en Mac:

```bash
brew install --cask yabai skhd
```

Y armá un `~/Library/Application Support/skhd/skhdrc` mapeando los binds de `HatLinux/hypr/bindings.lua`. Eso queda fuera del alcance de este dotfile.

## 🤝 Diferencias clave vs Linux (omarchy-config-merge)

| Aspecto                | Linux (omarchy-config-merge)                  | Mac (HatMac)                                  |
|------------------------|-----------------------------------------------|-----------------------------------------------|
| Compositor             | Hyprland                                      | (ninguno — Quartz)                            |
| Default shell          | `/usr/bin/fish`                               | `/bin/zsh` (macOS default)                    |
| fzf path               | `/usr/share/fzf/shell/key-bindings.zsh`       | `$HOMEBREW_PREFIX/opt/fzf/shell/...`          |
| p10k path              | `/usr/share/zsh-theme-powerlevel10k/...`      | `$HOMEBREW_PREFIX/share/powerlevel10k/...`    |
| Browser launcher       | `xdg-open`                                    | `open` (nativo)                               |
| Notification           | `notify-send` (libnotify)                     | `osascript -e 'display notification...'`      |
| Clipboard (Wayland/X11)| wl-copy / xclip / xsel                        | pbcopy / pbpaste                              |
| Theme hot-reload       | Omarchy → `omarchy-theme-hotreload.lua`       | (no aplica, theme fijo en cada terminal)      |
| tmux autostart cmd     | `uwsm-app -- ghostty ...`                     | `ghostty ...` directo                         |

## 📄 Licencia

MIT — igual que el resto de HatDots.
