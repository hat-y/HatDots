# HatDots - Configuraciones para Linux

Mis dotfiles organizados para Fedora/KDE Plasma.

## Estructura

```
HatDots/
├── HatLinux/
│   ├── tmux/
│   │   ├── .tmux.conf               # Config de tmux (Catppuccin Mocha, Ctrl+Space)
│   │   └── scripts/                 # Scripts de sesión (compatibilidad migración)
│   ├── scripts/                     # Cross-multiplexer wrappers
│   │   └── ghostty-multiplexer-new  # Wrapper POSIX sh (Herdr > Tmux fallback)
│   ├── herdr/                       # Config de Herdr (multiplexer default)
│   │   ├── config.toml              # Pi-matching palette + keybindings
│   │   └── README.md                # Install + keybindings + license notes
│   ├── fish/                        # Fish shell init (paralelo a Zsh)
│   │   └── config.fish              # GentlemFish port + guard Herdr>Tmux
│   ├── ghostty/
│   │   └── config                   # Config de Ghostty (command = wrapper)
│   ├── kde/
│   │   ├── kwin/
│   │   │   └── kwinrc           # Config de KWin + KZones
│   │   └── config/
│   │       └── kglobalshortcutsrc-kzones
│   ├── zsh/
│   │   ├── .zshrc
│   │   └── .p10k.zsh
│   └── nvim/
│       └── (config de neovim)
└── link-linux.sh              # Script para linking
```

> **Nota sobre la migración**: el antiguo `ghostty-tmux-new` se reemplaza por
> el wrapper `ghostty-multiplexer-new`. Durante la ventana de migración
> existe un shim de compatibilidad en `tmux/scripts/ghostty-tmux-new` que
> delega al wrapper. Después de verificar (SCN-1..SCN-9), el shim se borra.

## Instalación

1. **Hacer link de archivos**:
```bash
# Para tmux
ln -sf ~/HatDots/HatLinux/tmux/.tmux.conf ~/.tmux.conf

# Para Ghostty
ln -sf ~/HatDots/HatLinux/ghostty/config ~/.config/ghostty/config

# Para KDE/KWin
ln -sf ~/HatDots/HatLinux/kde/kwin/kwinrc ~/.config/kwinrc
```

2. **Scripts necesarios**:
```bash
chmod +x ~/HatDots/HatLinux/tmux/scripts/ghostty-tmux-new
ln -sf ~/HatDots/HatLinux/tmux/scripts/ghostty-tmux-new ~/.local/bin/ghostty-tmux-new
```

## Componentes

### Ghostty + Multiplexor (Herdr default, Tmux fallback)
- Terminal: Ghostty
- Multiplexer por defecto: **Herdr** (PTY-based, agent-aware, ideal para Claude Code / Codex / OpenCode)
- Fallback: **Tmux** (cuando el binario `herdr` no está en PATH)
- Detector: `HatLinux/scripts/ghostty-multiplexer-new` — POSIX sh wrapper que elige Herdr o Tmux
- Sesiones con 2 ventanas (nvim + shell) cuando se usa Tmux fallback
- Shortcuts en tmux (cuando está activo):
  - `Ctrl+Space` = prefix
  - `Ctrl+Space s` = menú de sesiones
  - `Ctrl+Space N` = crear nueva sesión (via wrapper)
  - `Ctrl+Space C-k` = matar sesión
- Shortcuts en Herdr (`HatLinux/herdr/config.toml`):
  - `Ctrl+a` = prefix
  - `prefix + Alt+k` / `prefix + Alt+j` = previous / next agent
  - `prefix + Ctrl+1..9` = focus agent N
- Status bar con hora, CPU y RAM (en Tmux fallback)

### Herdr (configuración específica)
- Instalación (manual — link-linux.sh no la hace):
  ```bash
  brew install herdr          # macOS / Linuxbrew
  cargo install herdr         # desde crates.io
  ```
- Link manual de los archivos nuevos:
  ```bash
  mkdir -p ~/.local/bin ~/.config/herdr ~/.config/fish
  ln -sfn ~/projects/HatDots/HatLinux/scripts/ghostty-multiplexer-new \
            ~/.local/bin/ghostty-multiplexer-new
  ln -sfn ~/projects/HatDots/HatLinux/herdr/config.toml \
            ~/.config/herdr/config.toml
  ln -sfn ~/projects/HatDots/HatLinux/fish/config.fish \
            ~/.config/fish/config.fish
  # Después de la migración, limpiá el symlink viejo:
  rm -f ~/.local/bin/ghostty-tmux-new
  ```
- ⚠️ **License caveat**: Herdr upstream publica con SPDX `NOASSERTION` (source-available, no OSS por defecto).
- ⚠️ **Version warning**: testeado contra **v0.4.x**. Versiones nuevas pueden haber renombrado config keys.
- 🪟 **Windows**: Herdr no tiene binario nativo. Usar WSL o quedarse en Tmux fallback.
- Ver `HatLinux/herdr/README.md` para detalles completos.

**Revertir a Tmux puro** (si preferís no usar Herdr): editá `HatLinux/ghostty/config` y reemplazá la línea `command =` por:

```bash
command = /usr/bin/tmux -f ~/.tmux.conf new-session -A -s main
```

### KDE/KWin
- KZones instalado para tiling por zonas
- 3 escritorios virtuales: personal, dev, work
- KZones layouts configurados

### Zsh
- Configuración personalizada
- Powerlevel10k theme

## Requerimientos

- Fedora (测试 en Fedora 40+)
- KDE Plasma
- Ghostty
- tmux 2.0+
- zsh