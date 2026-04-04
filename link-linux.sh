#!/usr/bin/env bash
# HatDots Linux Installation Script
# Installs dependencies and creates symlinks for dotfiles

set -Eeuo pipefail

# Detect package manager
detect_package_manager() {
    if command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v apt &>/dev/null; then
        echo "apt"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v nix-env &>/dev/null; then
        echo "nix"
    else
        echo "unknown"
    fi
}

# Install dependencies based on package manager
install_dependencies() {
    local pm=$(detect_package_manager)
    echo "📦 Detectado: $pm"
    echo "Instalando dependencias..."

    case $pm in
        dnf)
            sudo dnf install -y neovim git zsh ripgrep fd-find eza zoxide fzf atuin 2>/dev/null || \
            sudo dnf install -y neovim git zsh ripgrep fd-find eza zoxide fzf
            ;;
        apt)
            sudo apt update
            sudo apt install -y neovim git zsh ripgrep fd-find eza zoxide fzf
            # Atuin requires manual install
            if ! command -v atuin &>/dev/null; then
                echo "📥 Instalando Atuin..."
                curl -Ls https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-musl.tar.gz | sudo tar xz -C /usr/local/bin/ || true
            fi
            ;;
        pacman)
            sudo pacman -S --noconfirm neovim git zsh ripgrep fd eza zoxide atuin fzf
            ;;
        zypper)
            sudo zypper install -y neovim git zsh ripgrep fd eza zoxide fzf
            # Atuin requires manual install
            if ! command -vu atuin &>/dev/null; then
                echo "📥 Instalando Atuin..."
                curl -Ls https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-musl.tar.gz | sudo tar xz -C /usr/local/bin/ || true
            fi
            ;;
        nix)
            echo "📦 Nix detected - usando home-manager..."
            echo "Agregá a tu home.nix:"
            echo "  home.packages = with pkgs; [ neovim git zsh ripgrep fd eza zoxide fzf atuin ];"
            ;;
        unknown)
            echo "❌ No se detectó package manager conocido"
            echo "Por favor instalá las dependencias manualmente:"
            echo "  - neovim, git, zsh, tmux"
            echo "  - ripgrep, fd (fd-find)"
            echo "  - eza, zoxide, fzf"
            echo "  - atuin, ghostty (opcionales)"
            ;;
    esac

    echo "✅ Dependencias instaladas"
}

# Install Powerlevel10k theme
install_p10k() {
    local p10k_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        echo "📥 Instalando Powerlevel10k..."
        mkdir -p "$(dirname "$p10k_dir")"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        echo "✅ Powerlevel10k ya instalado"
    fi
}

# Main installation
main() {
    echo "🚀 HatDots Linux Installer"
    echo "=============================="

    # Install dependencies
    install_dependencies

    # Install Powerlevel10k
    install_p10k

    echo ""
    echo "📂 Creando symlinks..."

    REPO="$HOME/HatDots"
    SHARED="$HOME/HatDots/shared"
    TERMINALS="$HOME/HatDots/terminals"
    mkdir -p "$HOME/.config" "$HOME/.config/wezterm" "$HOME/.config/ghostty"

    safe_link() {
        local dst="$1" src="$2"
        mkdir -p "$(dirname "$dst")"
        if [ -d "$dst" ] && [ ! -L "$dst" ]; then
            mv "$dst" "$dst.bak.$(date +%s)"
            echo "⚠️ Backup: $dst.bak.$(date +%s)"
        fi
        ln -sfn "$src" "$dst"
        echo "✓ $dst -> $src"
    }

    # Neovim config
    safe_link "$HOME/.config/nvim"                   "$REPO/HatLinux/nvim"

    # Terminal (elegí una: wezterm o ghostty)
    # WezTerm
    safe_link "$HOME/.config/wezterm/wezterm.lua"    "$TERMINALS/wezterm/wezterm.lua"
    # Ghostty (comentado - descomentá si lo usás)
    # safe_link "$HOME/.config/ghostty/config"       "$TERMINALS/ghostty/config"

    # Shell (zsh)
    safe_link "$HOME/.zshrc"                         "$REPO/HatLinux/zsh/.zshrc"
    safe_link "$HOME/.p10k.zsh"                      "$REPO/HatLinux/zsh/.p10k.zsh"

    echo ""
    echo "=========================================="
    echo "✅ Instalación completa!"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Reiniciá tu terminal"
    echo "  2. Cambiá a zsh: chsh -s /bin/zsh"
    echo "  3. Abrí nvim y esperá que Lazy instale plugins"
    echo "  4. Enjoy! 🎉"
}

main "$@"
