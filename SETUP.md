# HatDots - Guía de Configuración Rápida

Este repositorio contiene dotfiles multiplataforma para **Linux** y **Windows** con Neovim (LazyVim), terminales, shells y herramientas de productividad.

## 🚀 Instalación Rápida

### Windows
```powershell
# Clonar el repositorio
git clone https://github.com/hat-y/HatDots.git $HOME\HatDots

# Ejecutar script de instalación
cd $HOME\HatDots
.\link-windows.ps1
```

### Linux
```bash
# Clonar el repositorio
git clone https://github.com/hat-y/HatDots.git $HOME/HatDots

# Ejecutar script de instalación
cd $HOME/HatDots
chmod +x link-linux.sh
./link-linux.sh
```

## 📋 Requisitos

### Windows
```powershell
winget install -e --id Git.Git
winget install -e --id Neovim.Neovim
winget install -e --id WezTerm.WezTerm
winget install -e --id Starship.Starship
winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id sharkdp.fd
winget install -e --id JesseDuffield.lazygit
winget install -e --id Zig.Zig
winget install -e --id LLVM.LLVM
# Opcional: para mejor experiencia
winget install -e --id eza-community.eza
winget install -e --id ajeetdsouza.zoxide
```

### Linux (Arch/derivados)
```bash
# Paquetes principales
sudo pacman -S neovim git wezterm zsh starship ripport fd lazygit zig llvm

# Opcionales recomendados
sudo pacman -S eza zoxide atuin fzf
```

## 🎨 Características Principales

### Neovim (LazyVim)
- **Plugins de IA**: Copilot, Claude Code, Avante, Gemini CLI (solo Windows)
- **Lenguajes**: TypeScript, Python, Rust soporte completo
- **Productividad**: Telescope, Oil (navegador de archivos), LazyGit
- **UI**: Tema Kanagawa, Treesitter, formateo automático

### Terminal y Shell
- **Windows**: WezTerm + PowerShell + Starship
- **Linux**: Ghostty + Zsh + Powerlevel10k + Starship
- **Multiplexor**: Tmux (Linux)

### Escritorio Completo (Arch Linux + Hyprland)
- **Compositor**: Hyprland con configuración modular
- **Temas**: DenAsari y Mocha-Power
- **Herramientas**: Waybar, Wofi, SwayNC, Yazi, Fastfetch

## 🔧 Configuración Post-Instalación

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

## 📁 Estructura del Repositorio

```
HatDots/
├── HatLinux/           # Configuraciones Linux
│   ├── nvim/           # Neovim config
│   ├── HatZsh/         # Zsh + Powerlevel10k
│   ├── HatGhostty/     # Terminal Ghostty
│   └── starship/       # Starship prompt
├── HatWindows/         # Configuraciones Windows
│   ├── nvim/           # Neovim config con plugins IA
│   ├── wezterm/        # WezTerm config
│   ├── powershell/     # PowerShell profile
│   └── starship/       # Starship prompt
├── HatArch/            # Configuraciones Arch Linux + Hyprland
│   ├── DenAsari/       # Tema completo
│   └── Mocha-Power/    # Tema alternativo
├── assets/             # Recursos compartidos
├── link-linux.sh       # Script instalación Linux
├── link-windows.ps1    # Script instalación Windows
└── SETUP.md            # Este archivo
```

## ⌨️ Atajos Útiles

### Neovim
- `<leader>ff` - Buscar archivos
- `<leader>fg` - Búsqueda global
- `<leader>gg` - Abrir LazyGit
- `<leader>cf` - Formatear código
- `-` - Abrir Oil (navegador de archivos)
- `<leader>aa` - Toggle Avante (IA, Windows)
- `<leader>ac` - Toggle Claude Code (Windows)

### WezTerm (Windows)
- `Ctrl+Space h/l` - Cambiar workspace
- `Ctrl+Space flechas` - Navegar panes
- `Ctrl+Space -/+` - Dividir vertical/horizontal

### Tmux (Linux)
- `Ctrl+b` - Prefix
- `Ctrl+b c` - Nueva ventana
- `Ctrl+b |` - Dividir vertical
- `Ctrl+b -` - Dividir horizontal

## 🐛 Problemas Comunes

### Windows
- **Symlinks**: Habilita Modo Desarrollador para crear symlinks sin admin
- **Build errors**: Asegúrate de tener Zig y LLVM instalados
- **API Keys**: Configura las claves para plugins de IA

### Linux
- **Permisos**: Asegúrate que los scripts tengan permisos de ejecución
- **Dependencias**: Instala las dependencias faltantes de tu distribución

## 🤝 Contribuciones

Las mejoras son bienvenidas:
- Reporta issues
- Envía pull requests
- Sugiere nuevas configuraciones

## 📄 Licencia

MIT License - Siéntete libre de usar, modificar y distribuir.