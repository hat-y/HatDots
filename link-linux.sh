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
            sudo dnf install -y neovim git zsh ripgrep fd-find eza zoxide fzf tmux 2>/dev/null || \
            sudo dnf install -y neovim git zsh ripgrep fd-find eza zoxide fzf
            ;;
        apt)
            sudo apt update
            sudo apt install -y neovim git zsh ripgrep fd-find eza zoxide fzf tmux
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

# Install Zsh plugins (git clones to XDG data dir)
install_zsh_plugins() {
    local plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
    mkdir -p "$plugins_dir"

    # zsh-autosuggestions
    local as_dir="$plugins_dir/zsh-autosuggestions"
    if [ ! -d "$as_dir" ]; then
        echo "📥 Instalando zsh-autosuggestions..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$as_dir"
    else
        echo "✅ zsh-autosuggestions ya instalado"
    fi

    # zsh-syntax-highlighting
    local sh_dir="$plugins_dir/zsh-syntax-highlighting"
    if [ ! -d "$sh_dir" ]; then
        echo "📥 Instalando zsh-syntax-highlighting..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$sh_dir"
    else
        echo "✅ zsh-syntax-highlighting ya instalado"
    fi

    # Powerlevel10k
    local p10k_dir="$plugins_dir/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        echo "📥 Instalando Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        echo "✅ Powerlevel10k ya instalado"
    fi
}

# Install Tmux plugins (TPM)
install_tmux_plugins() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    mkdir -p "$tpm_dir"

    # TPM itself
    if [ ! -d "$tpm_dir/tpm" ]; then
        echo "📥 Instalando TPM..."
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir/tpm"
    fi
}

# Main installation
main() {
    echo "🚀 HatDots Linux Installer"
    echo "=============================="

    # Install dependencies
    install_dependencies

    # Install Zsh plugins (autosuggestions, syntax-highlighting, powerlevel10k)
    install_zsh_plugins

    # Install Tmux plugins (TPM)
    install_tmux_plugins

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
    # safe_link "$HOME/.config/wezterm/wezterm.lua"    "$TERMINALS/wezterm/wezterm.lua"
    # Ghostty
    safe_link "$HOME/.config/ghostty/config"             "$TERMINALS/ghostty/config"
    safe_link "$HOME/.config/ghostty/shaders"            "$TERMINALS/ghostty/shaders"

    # Tmux
    safe_link "$HOME/.config/tmux/tmux.conf"             "$TERMINALS/tmux/tmux.conf"

    # Shell (zsh)
    safe_link "$HOME/.zshrc"                         "$REPO/HatLinux/zsh/.zshrc"
    safe_link "$HOME/.p10k.zsh"                      "$REPO/HatLinux/zsh/.p10k.zsh"

    echo ""
    echo "=========================================="
    echo "✅ Instalación completa!"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Reiniciá tu terminal"
    echo "  2. Cambiá a zsh: chsh -s $(which zsh)"
    echo "  3. Abrí nvim y esperá que Lazy instale plugins"
    echo "  4. Enjoy! 🎉"
}

main "$@"
