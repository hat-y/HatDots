# HatDots - Configuraciones para Linux

Mis dotfiles organizados para Fedora/KDE Plasma.

## Estructura

```
HatDots/
├── HatLinux/
│   ├── tmux/
│   │   ├── .tmux.conf          # Config de tmux
│   │   └── scripts/
│   │       └── ghostty-tmux-new # Script para crear sesiones
│   ├── ghostty/
│   │   └── config               # Config de Ghostty
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

### Ghostty + Tmux
- Terminal: Ghostty
- Multiplexer: tmux
- Sesiones automáticas con 2 ventanas (nvim + shell)
- Shortcuts en tmux:
  - `Ctrl+Space` = prefix
  - `Ctrl+Space s` = menú de sesiones
  - `Ctrl+Space N` = crear nueva sesión
  - `Ctrl+Space C-k` = matar sesión
- Status bar con hora, CPU y RAM

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