# HatDots - Configuraciones para Linux

Mis dotfiles organizados para Fedora/KDE Plasma.

## Estructura

Desde la unificación de Phase 2, lo cross-platform vive en `common/` (tmux,
ghostty, zsh, fish, newsboat, herdr) y acá en `os/linux/` sólo queda lo
genérico de Linux (no atado a Hyprland/Omarchy — eso es `os/omarchy/`):

```
HatDots/
├── os/linux/
│   ├── README.md                    # este archivo
│   ├── ghostty/os.ghostty           # overlay: gtk-tabs-location, gtk-single-instance
│   ├── newsboat/os.newsboat         # overlay: browser = "xdg-open %u"
│   └── kde/
│       ├── kwin/kwinrc              # Config de KWin + KZones
│       └── config/kglobalshortcutsrc-kzones
├── os/omarchy/                      # Hyprland/Omarchy-only (hypr/, tmux/ghostty overlays, ...)
├── common/                          # tmux, ghostty, zsh, fish, newsboat, herdr
├── common/nvim/                     # Neovim, unificado desde Phase 3 (antes HatLinux/nvim)
└── link-linux.sh                    # Script para linking
```

## Instalación

1. **Hacer link de archivos** (ver también `link-linux.sh`):
```bash
# Para tmux
ln -sf ~/HatDots/common/tmux/tmux.conf ~/.config/tmux/tmux.conf

# Para Ghostty
ln -sf ~/HatDots/common/ghostty/config ~/.config/ghostty/config

# Para KDE/KWin
ln -sf ~/HatDots/os/linux/kde/kwin/kwinrc ~/.config/kwinrc
```

2. **Multiplexer wrapper**:
```bash
ln -sf ~/HatDots/common/bin/ghostty-multiplexer-new ~/.local/bin/ghostty-multiplexer-new
```

## Componentes

### Ghostty + Multiplexor (Herdr default, Tmux fallback)
- Terminal: Ghostty
- Multiplexer por defecto: **Herdr** (PTY-based, agent-aware, ideal para Claude Code / Codex / OpenCode)
- Fallback: **Tmux** (cuando el binario `herdr` no está en PATH)
- Detector: `common/bin/ghostty-multiplexer-new` — POSIX sh wrapper que elige Herdr o Tmux
- Shortcuts en tmux (cuando está activo, ver `common/tmux/tmux.conf`):
  - `C-Space` = prefix (`C-b` como prefix2)
  - `C-Space r` = renombrar ventana, `C-Space R` = renombrar sesión
  - `C-Space K` = matar sesión
  - `?` = ayuda de keybindings de Omarchy (overlay `os/omarchy/tmux/os.tmux.conf`)
- Shortcuts en Herdr (`common/herdr/config.toml`):
  - `Ctrl+a` = prefix
  - `prefix + Alt+k` / `prefix + Alt+j` = previous / next agent
  - `prefix + Ctrl+1..9` = focus agent N

### Herdr (configuración específica)
- Instalación (manual — link-linux.sh no la hace):
  ```bash
  brew install herdr          # macOS / Linuxbrew
  cargo install herdr         # desde crates.io
  ```
- Link manual de los archivos nuevos:
  ```bash
  mkdir -p ~/.local/bin ~/.config/herdr ~/.config/fish
  ln -sfn ~/projects/HatDots/common/bin/ghostty-multiplexer-new \
            ~/.local/bin/ghostty-multiplexer-new
  ln -sfn ~/projects/HatDots/common/herdr/config.toml \
            ~/.config/herdr/config.toml
  ln -sfn ~/projects/HatDots/common/fish/config.fish \
            ~/.config/fish/config.fish
  ```
- ⚠️ **License caveat**: Herdr upstream publica con SPDX `NOASSERTION` (source-available, no OSS por defecto).
- ⚠️ **Version warning**: testeado contra **v0.4.x**. Versiones nuevas pueden haber renombrado config keys.
- 🪟 **Windows**: Herdr no tiene binario nativo. Usar WSL o quedarse en Tmux fallback.
- Ver `common/herdr/README.md` para detalles completos.

**Revertir a Tmux puro** (si preferís no usar Herdr): editá `common/ghostty/config`
(o el overlay `os/linux/ghostty/os.ghostty` si sólo querés el cambio en Linux)
y reemplazá la línea `command =` por:

```bash
command = tmux new-session -A -s main
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
