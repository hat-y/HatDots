# HatDots Windows Installation Script
# Verifies dependencies and creates symbolic links

param(
    [switch]$Force,
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Repo = "$HOME\HatDots\HatWindows"
$Shared = "$HOME\HatDots\shared"

function Write-Step($message) {
    Write-Host "📦 $message" -ForegroundColor Cyan
}

function Write-Done($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

function Test-Command($cmd) {
    $null = Get-Command $cmd -ErrorAction SilentlyContinue
    return $?
}

function Install-Dependencies {
    Write-Step "Verificando dependencias..."

    $tools = @(
        @{ Name = "git"; Id = "Git.Git"; Install = { winget install -e --id Git.Git --silent } },
        @{ Name = "nvim"; Id = "Neovim.Neovim"; Install = { winget install -e --id Neovim.Neovim --silent } },
        @{ Name = "wezterm"; Id = "WezTerm.WezTerm"; Install = { winget install -e --id WezTerm.WezTerm --silent } },
        @{ Name = "starship"; Id = "Starship.Starship"; Install = { winget install -e --id Starship.Starship --silent } },
        @{ Name = "ripgrep"; Id = "BurntSushi.ripgrep.MSVC"; Install = { winget install -e --id BurntSushi.ripgrep.MSVC --silent } },
        @{ Name = "fd"; Id = "sharkdp.fd"; Install = { winget install -e --id sharkdp.fd --silent } },
        @{ Name = "lazygit"; Id = "JesseDuffield.lazygit"; Install = { winget install -e --id JesseDuffield.lazygit --silent } }
    )

    $optional = @(
        @{ Name = "zig"; Id = "Zig.Zig"; Install = { winget install -e --id Zig.Zig --silent } },
        @{ Name = "llvm"; Id = "LLVM.LLVM"; Install = { winget install -e --id LLVM.LLVM --silent } },
        @{ Name = "eza"; Id = "eza-community.eza"; Install = { winget install -e --id eza-community.eza --silent } },
        @{ Name = "zoxide"; Id = "ajeetdsouza.zoxide"; Install = { winget install -e --id ajeetdsouza.zoxide --silent } }
    )

    Write-Host "Verificando herramientas principales..." -ForegroundColor Yellow
    foreach ($tool in $tools) {
        if (Test-Command $tool.Name) {
            Write-Host "  ✓ $($tool.Name)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($tool.Name) - instalando..." -ForegroundColor Yellow
            try {
                & $tool.Invoke
                Write-Host "  ✓ $($tool.Name) instalado" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ $($tool.Name) no se pudo instalar" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "Verificando herramientas opcionales..." -ForegroundColor Yellow
    foreach ($tool in $optional) {
        if (Test-Command $tool.Name) {
            Write-Host "  ✓ $($tool.Name)" -ForegroundColor Green
        } else {
            Write-Host "  ○ $($tool.Name) (opcional)" -ForegroundColor Gray
        }
    }

    Write-Done "Dependencias verificadas"
}

function New-FileLink($link, $target) {
    New-Item -ItemType Directory -Force (Split-Path $link) | Out-Null
    if (Test-Path $link) { Remove-Item $link -Force }
    try {
        New-Item -ItemType SymbolicLink -Path $link -Target $target -Force | Out-Null
    } catch {
        New-Item -ItemType HardLink -Path $link -Target $target | Out-Null
    }
}

function New-DirLink($link, $target) {
    if (Test-Path $link) { Remove-Item $link -Recurse -Force }
    try {
        New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null
    } catch {
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    }
}

function New-Symlink($link, $target) {
    $linkDir = Split-Path $link -Parent
    if ($linkDir) {
        New-Item -ItemType Directory -Force $linkDir | Out-Null
    }
    if (Test-Path $link) {
        if ($Force) {
            Remove-Item $link -Force
        } else {
            Write-Host "  ⚠ $link ya existe, usando -Force para sobrescribir" -ForegroundColor Yellow
            Remove-Item $link -Force
        }
    }
    try {
        New-Item -ItemType SymbolicLink -Path $link -Target $target -Force | Out-Null
        Write-Host "  ✓ $link" -ForegroundColor Green
    } catch {
        try {
            New-Item -ItemType HardLink -Path $link -Target $target -Force | Out-Null
            Write-Host "  ✓ $link (hardlink)" -ForegroundColor Green
        } catch {
            New-Item -ItemType Junction -Path $link -Target $target -Force | Out-Null
            Write-Host "  ✓ $link (junction)" -ForegroundColor Green
        }
    }
}

# Main
Write-Host "🚀 HatDots Windows Installer" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

if (-not $SkipInstall) {
    Install-Dependencies
} else {
    Write-Host "⏭️  Saltando instalación de dependencias" -ForegroundColor Yellow
}

Write-Host ""
Write-Step "Creando symlinks..."

$Paths = @{
    NvimDir     = "$Repo\nvim"
    WeztermFile = "$Repo\wezterm\wezterm.lua"
    PSProfile   = "$Repo\powershell\Microsoft.PowerShell_profile.ps1"
    Starship    = "$Shared\starship.toml"
}

$Targets = @{
    NvimDir     = "$env:LOCALAPPDATA\nvim"
    WeztermFile = "$HOME\.wezterm.lua"
    PSProfile   = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    Starship    = "$HOME\.config\starship.toml"
}

# Ensure directories exist
New-Item -ItemType Directory -Force "$Repo\nvim", "$Repo\wezterm", "$Repo\powershell", "$HOME\.config", "$HOME\Documents\PowerShell" | Out-Null

# Create symlinks
New-DirLink $Targets.NvimDir $Paths.NvimDir
New-FileLink $Targets.WeztermFile $Paths.WeztermFile
New-FileLink $Targets.PSProfile $Paths.PSProfile
New-FileLink $Targets.Starship $Paths.Starship

Write-Host ""
Write-Done "Instalación completa!"
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Cerrá y reopená WezTerm/PowerShell"
Write-Host "  2. Abrí nvim y esperá que Lazy instale plugins"
Write-Host "  3. Enjoy! 🎉"
