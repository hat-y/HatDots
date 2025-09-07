# HatDot to Windows

Dotfiles para **Windows**: Neovim (LazyVim), WezTerm, PowerShell y Starship.

## Requisitos

```powershell
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

- Abre Neovim → Lazy instalará plugins.
- `:Mason` → instala `prettierd`, `stylua`, `ruff`, `lua-language-server`, `pyright`, `vtsls`.
- `:TSUpdate` (parsers con clang).
- `:Lazy build telescope-zf-native.nvim` (requiere zig).

---

## Atajos útiles

- **Oil:** `-` (float), `<leader>-` (buffer)
- **Telescope:** `<leader>ff` (files), `<leader>fg` (grep), `<leader>fb` (buffers)
- **Format:** `<leader>cf` (Conform)
- **Git:** Gitsigns; `<leader>gg` abre LazyGit
- **WezTerm:** Alt+Shift +/- divide pane · Ctrl+h/l cambia workspace (si no estás en nvim)

---
