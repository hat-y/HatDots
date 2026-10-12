# HatDot to Windows

Dotfiles para **Windows**: Neovim (LazyVim), WezTerm, PowerShell y Starship.

> **⚠️ Importante:** Sigue los pasos en orden. Es **crucial** instalar Node.js y tree-sitter CLI **antes** de abrir Neovim por primera vez para evitar errores de configuración.

## Requisitos

```powershell
# Herramientas esenciales
winget install -e --id Git.Git
winget install -e --id Neovim.Neovim
winget install -e --id WezTerm.WezTerm
winget install -e --id NerdFonts.FiraCode
winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id sharkdp.fd
winget install -e --id Zig.Zig
winget install -e --id LLVM.LLVM
winget install -e --id JesseDuffield.lazygit
winget install -e --id Starship.Starship

# Node.js (requerido para tree-sitter y otras herramientas)
winget install -e --id OpenJS.NodeJS

# opcionales
winget install -e --id eza-community.eza
winget install -e --id ajeetdsouza.zoxide
```

> **Nota:** En Windows, habilitá Modo Desarrollador  
> (Configuración → Para desarrolladores) para crear symlinks sin privilegios de admin.

---

## Estructura

```
HatDot/
  HatWindows/
    nvim/            # config de Neovim (LazyVim)
    wezterm/         # wezterm.lua
    powershell/      # Microsoft.PowerShell_profile.ps1
    starship/        # starship.toml
    README.md
  link-windows.ps1   # script para crear enlaces
```

---

## Enlaces a rutas reales

- **Neovim:**  
  `%LOCALAPPDATA%\nvim` → Junction → `HatWindows\nvim`

- **WezTerm:**  
  `~\.wezterm.lua` → Symlink → `HatWindows\wezterm\wezterm.lua`

- **PowerShell:**  
  `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` → Symlink → `HatWindows\powershell\...`

- **Starship:**  
  `~\.config\starship.toml` → Symlink → `HatWindows\starship\starship.toml`

---

## Tenés dos opciones:

### A) Script (recomendado)

En la raíz del repo:

```powershell
.\link-windows.ps1
```

### B) Manual (resumen)

#### WezTerm

```powershell
New-Item -ItemType SymbolicLink -Path $HOME\.wezterm.lua `
  -Target $HOME\HatDot\HatWindows\wezterm\wezterm.lua -Force
```

#### Neovim (junction)

```powershell
if (Test-Path $env:LOCALAPPDATA\nvim) { Remove-Item $env:LOCALAPPDATA\nvim -Recurse -Force }
New-Item -ItemType Junction -Path $env:LOCALAPPDATA\nvim `
  -Target $HOME\HatDot\HatWindows\nvim | Out-Null
```

#### PowerShell profile

```powershell
New-Item -ItemType Directory -Force $HOME\Documents\PowerShell | Out-Null
New-Item -ItemType SymbolicLink -Path $PROFILE `
  -Target $HOME\HatDot\HatWindows\powershell\Microsoft.PowerShell_profile.ps1 -Force
```

#### Starship

```powershell
New-Item -ItemType Directory -Force $HOME\.config | Out-Null
New-Item -ItemType SymbolicLink -Path $HOME\.config\starship.toml `
  -Target $HOME\HatDot\HatWindows\starship\starship.toml -Force
```

---

## Primer arranque (Neovim)

### 1. Instalación inicial de Tree-sitter CLI

**Importante:** Antes de abrir Neovim por primera vez, instala el CLI de tree-sitter:

```powershell
# Instalar tree-sitter CLI via npm (requiere Node.js)
npm install -g tree-sitter-cli

# Verificar instalación
tree-sitter --version
```

### 2. Configuración inicial de Neovim

- Abre Neovim → Lazy instalará plugins automáticamente.
- **No te preocupes por errores de treesitter al principio**, es normal durante la primera instalación.

### 3. Instalación de herramientas con Mason

Una vez que Neovim esté abierto:

```vim
:Mason
```

Instala las siguientes herramientas recomendadas:
- `prettierd` (formateador JavaScript/TypeScript)
- `stylua` (formateador Lua)
- `ruff` (linter/formatter Python)
- `lua-language-server` (LSP para Lua)
- `pyright` (LSP para Python)
- `vtsls` (LSP para TypeScript/JavaScript)

### 4. Verificación de Tree-sitter

Después de la instalación inicial:

```vim
:checkhealth nvim-treesitter
```

Si ves algún error relacionado con tree-sitter, ejecuta:

```vim
:TSUpdate
```

LazyVim gestionará automáticamente la instalación y configuración de los parsers de treesitter.

### 5. Build de plugins nativos

```vim
:Lazy build telescope-zf-native.nvim
```

*(requiere Zig, que ya instalaste con los requisitos)*

---

## Troubleshooting (Solución de problemas)

### Neovim se cierra automáticamente

Si Neovim se cierra al iniciar, probablemente tienes archivos swap acumulados:

```powershell
# Eliminar archivos swap de Neovim
Remove-Item "$env:LOCALAPPDATA\nvim-data\swap\*" -Force -Recurse
```

### Error "nvim-treesitter.configs no disponible"

Este error indica que falta tree-sitter CLI:

```powershell
# Instalar tree-sitter CLI
npm install -g tree-sitter-cli

# Verificar instalación
tree-sitter --version
```

### Error "Unmet requirements for nvim-treesitter"

Si Mason no puede instalar tree-sitter CLI automáticamente:

```powershell
# Instalación manual
npm install -g tree-sitter-cli

# Luego en Neovim
:checkhealth nvim-treesitter
```

### Error E325: ATTENTION (Swap files)

Si Neovim muestra errores de archivos swap:

```powershell
# Limpiar todos los archivos swap
Remove-Item "$env:LOCALAPPDATA\nvim-data\swap\*" -Force -Recurse
```

### Plugins no se instalan correctamente

```vim
:Lazy sync
:checkhealth
```

---

## Atajos útiles

- **Oil:** `-` (float), `<leader>-` (buffer)
- **Telescope:** `<leader>ff` (files), `<leader>fg` (grep), `<leader>fb` (buffers)
- **Format:** `<leader>cf` (Conform)
- **Git:** Gitsigns; `<leader>gg` abre LazyGit
- **WezTerm:** Alt+Shift +/- divide pane · Ctrl+h/l cambia workspace (si no estás en nvim)

---
