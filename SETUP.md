# HatDots - Guía de Configuración Rápida

Este repositorio contiene dotfiles multiplataforma para **Linux** y **Windows** con Neovim (LazyVim), terminales, shells y herramientas de productividad.

## 🚀 Instalación Rápida

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

## 📋 Requisitos

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

## 🎨 Características Principales

### Neovim (LazyVim)
- **Plugins de IA**: Copilot, Claude Code, Avante, Gemini CLI (solo Windows)
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
HatDots/                    # Terminal + Shell (portátil)
├── shared/                 # Configs compartidos
├── terminals/              # Terminal configs (elegí la que uses)
│   ├── wezterm/            # WezTerm config
│   └── ghostty/            # Ghostty config
├── HatLinux/               # Configuraciones Linux
│   ├── nvim/               # Neovim config (LazyVim)
│   └── zsh/                # Zsh + Powerlevel10k
├── HatWindows/             # Configuraciones Windows
│   ├── nvim/               # Neovim config con plugins IA
│   ├── wezterm/            # WezTerm config
│   └── powershell/         # PowerShell profile
├── link-linux.sh           # Script instalación Linux
├── link-windows.ps1        # Script instalación Windows
└── SETUP.md                # Este archivo
```

> **Nota**: Los configs en `HatDots/` son **portables** — funcionan en cualquier distro Linux. Si usás Arch con Hyprland, los configs de desktop están en el repo separado **[HatArch](https://github.com/hat-y/HatArch)**.

## ⌨️ Atajos Útiles

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