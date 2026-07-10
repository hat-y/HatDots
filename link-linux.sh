#!/usr/bin/env bash
# HatDots Linux Installation Script
# Installs dependencies and creates symlinks for dotfiles
#
# Strategy: HatDots manages what Omarchy does NOT:
#   HatDots:  nvim (themes, keymaps, LSP), tmux (plugins, layout script),
#             ghostty (shaders, config), zsh (aliases, vi-mode, zoxide), launchers
#   Omarchy:  hyprland, waybar, walker, mako, alacritty, kitty, foot,
#             ghostty (theme), bin scripts (~230)

set -Eeuo pipefail

REPO="${HATDOTS_REPO:-$HOME/projects/HatDots}"
CWD_ARG="${CWD:-$HOME}"

# ─── Detect package manager ───────────────────────────────────────────────────
detect_package_manager() {
    if command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v apt &>/dev/null; then
        echo "apt"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# ─── Install dependencies ────────────────────────────────────────────────────
install_dependencies() {
    local pm=$(detect_package_manager)
    echo "📦 Detectado: $pm"

    case $pm in
        pacman)
            sudo pacman -S --noconfirm \
                neovim tmux ghostty ghostty-shell-integration ghostty-terminfo \
                eza zoxide fzf ripgrep fd
            ;;
        dnf)
            sudo dnf install -y neovim git zsh ripgrep fd-find eza zoxide fzf tmux 2>/dev/null || \
            sudo dnf install -y neovim git zsh ripgrep fd-find eza zoxide fzf tmux
            ;;
        apt)
            sudo apt update && sudo apt install -y neovim git zsh ripgrep fd-find eza zoxide fzf tmux
            ;;
        zypper)
            sudo zypper install -y neovim git zsh ripgrep fd eza zoxide fzf tmux
            ;;
        *)
            echo "❌ No se detectó package manager conocido"
            echo "Instalá manualmente: neovim, tmux, ghostty, eza, zoxide, fzf"
            ;;
    esac
}

# ─── Safe symlink ────────────────────────────────────────────────────────────
safe_link() {
    local dst="$1" src="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ]; then
        echo "⚠  Ya existe symlink: $dst"
        return 0
    elif [ -e "$dst" ]; then
        mv "$dst" "$dst.bak.$(date +%s)"
        echo "⚠  Backup: $dst.bak"
    fi
    ln -sfn "$src" "$dst"
    echo "✓  $dst"
}

# ─── Safe copy ───────────────────────────────────────────────────────────────
safe_copy() {
    local dst="$1" src="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -f "$dst" ]; then
        mv "$dst" "$dst.bak.$(date +%s)"
        echo "⚠  Backup: $dst.bak"
    fi
    cp "$src" "$dst"
    echo "✓  $dst (copied)"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    echo "🚀 HatDots Installer"
    echo "=========================================="

    if [ ! -d "$REPO" ]; then
        echo "❌ Repo no encontrado: $REPO"
        echo "   Cloná primero: git clone https://github.com/hat-y/HatDots.git $REPO"
        exit 1
    fi

    # 1. Dependencies
    echo ""
    echo "📦 Instalando dependencias..."
    install_dependencies

    # 2. Tmux plugins (TPM)
    echo ""
    echo "📥 Instalando TPM..."
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    mkdir -p "$tpm_dir"
    if [ ! -d "$tpm_dir/tpm" ]; then
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir/tpm"
    fi

    # 3. Symlinks base
    echo ""
    echo "📂 Creando symlinks..."

    safe_link "$HOME/.config/nvim" "$REPO/HatLinux/nvim"
    safe_link "$HOME/.config/tmux/tmux.conf" "$REPO/terminals/tmux/tmux.conf"
    safe_link "$HOME/.config/ghostty/shaders" "$REPO/terminals/ghostty/shaders"

    # p10k
    if [ -f "$REPO/HatLinux/zsh/.p10k.zsh" ]; then
        safe_copy "$HOME/.p10k.zsh" "$REPO/HatLinux/zsh/.p10k.zsh"
    fi

    # 4. Ghostty config (solo si no existe)
    if [ ! -f "$HOME/.config/ghostty/config" ]; then
        echo ""
        echo "📝 Creando ghostty config..."
        cat > "$HOME/.config/ghostty/config" << 'GHOSTTY_EOF'
# ═══════════════════════════════════════════════════════════════════════════════
# Ghostty — Fused with Omarchy + HatDots
# Theme: Omarchy (dynamic) | Shader: HatDots | Tmux: HatDots auto-launch
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Theme (Omarchy dynamic) ───────────────────────────────────────────────
config-file = ?"~/.config/omarchy/current/theme/ghostty.conf"

# ─── Font ─────────────────────────────────────────────────────────────────
font-family = "JetBrainsMono Nerd Font"
font-style = Regular
font-size = 9

# ─── Window ────────────────────────────────────────────────────────────────
window-theme = ghostty
window-padding-x = 4
window-padding-y = 4
confirm-close-surface = false
resize-overlay = never
gtk-toolbar-style = flat
gtk-single-instance = false

# ─── Cursor ───────────────────────────────────────────────────────────────
cursor-style = block
cursor-style-blink = false

# ─── Shell Integration ──────────────────────────────────────────────────────
shell-integration-features = no-cursor,ssh-env

# ─── Tmux auto-launch (HatDots) ────────────────────────────────────────────
command = /home/hat/.local/bin/tmux-session-layout main

# ─── Shader: cursor_smear_gentleman (HatDots) ──────────────────────────────
custom-shader = shaders/cursor_smear_gentleman.glsl

# ─── Keyboard Bindings ──────────────────────────────────────────────────────
keybind = shift+insert=paste_from_clipboard
keybind = control+insert=copy_to_clipboard
keybind = super+control+shift+alt+arrow_down=resize_split:down,100
keybind = super+control+shift+alt+arrow_up=resize_split:up,100
keybind = super+control+shift+alt+arrow_left=resize_split:left,100
keybind = super+control+shift+alt+arrow_right=resize_split:right,100
keybind = super+f=toggle_maximize
keybind = alt+f4=close_window

# ─── Performance ───────────────────────────────────────────────────────────
async-backend = epoll
mouse-scroll-multiplier = 0.95
GHOSTTY_EOF
        echo "✓  ~/.config/ghostty/config"
    else
        echo "⚠  ~/.config/ghostty/config ya existe — no se sobreescribe"
        echo "   Verificá que tenga: command = /home/hat/.local/bin/tmux-session-layout main"
    fi

    # 5. Launcher scripts (solo si no existen)
    echo ""
    echo "📝 Creando launcher scripts..."

    mkdir -p "$HOME/.local/bin"

    if [ ! -f "$HOME/.local/bin/hatdots-launch-terminal" ]; then
        cat > "$HOME/.local/bin/hatdots-launch-terminal" << 'LAUNCHER_EOF'
#!/bin/bash
cwd="$(omarchy-cmd-terminal-cwd 2>/dev/null || pwd)"
exec setsid uwsm-app -- ghostty -e bash -c "cd '$cwd' && exec zsh"
LAUNCHER_EOF
        chmod +x "$HOME/.local/bin/hatdots-launch-terminal"
        echo "✓  hatdots-launch-terminal"
    fi

    if [ ! -f "$HOME/.local/bin/hatdots-launch-terminal-tmux" ]; then
        cat > "$HOME/.local/bin/hatdots-launch-terminal-tmux" << 'LAUNCHER_TMUX_EOF'
#!/bin/bash
ws="Work"
if command -v hyprctl &>/dev/null; then
  ws_name=$(hyprctl activeworkspace -j 2>/dev/null | grep -oP '"name"\s*:\s*"\K[^"]+')
  [[ -n "$ws_name" ]] && ws="ws-${ws_name}"
fi
cwd="$(omarchy-cmd-terminal-cwd 2>/dev/null || pwd)"
exec setsid uwsm-app -- ghostty -e bash -c "cd '$cwd' && exec tmux-session-layout '$ws'"
LAUNCHER_TMUX_EOF
        chmod +x "$HOME/.local/bin/hatdots-launch-terminal-tmux"
        echo "✓  hatdots-launch-terminal-tmux"
    fi

    if [ ! -f "$HOME/.local/bin/tmux-session-layout" ]; then
        cat > "$HOME/.local/bin/tmux-session-layout" << 'LAYOUT_EOF'
#!/bin/bash
# tmux-session-layout — 3 windows: nvim | shell | shell
set -euo pipefail
SESSION="${1:-main}"
CWD="${2:-$(pwd)}"
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach -t "$SESSION"
fi
tmux new-session -d -s "$SESSION" -c "$CWD" nvim
tmux new-window -t "$SESSION" -c "$CWD"
tmux new-window -t "$SESSION" -c "$CWD"
tmux select-window -t "$SESSION:1"
exec tmux attach -t "$SESSION"
LAYOUT_EOF
        chmod +x "$HOME/.local/bin/tmux-session-layout"
        echo "✓  tmux-session-layout"
    fi

    echo ""
    echo "=========================================="
    echo "✅ Instalación base completa!"
    echo ""
    echo "Próximos pasos manuales:"
    echo ""
    echo "1. Hyprland bindings (~/.config/hypr/bindings.lua):"
    echo "   o.bind(\"SUPER + RETURN\", \"Terminal (Ghostty)\", \"hatdots-launch-terminal\")"
    echo "   o.bind(\"SUPER + ALT + RETURN\", \"Tmux (workspace)\", \"hatdots-launch-terminal-tmux\")"
    echo "   hyprctl reload"
    echo ""
    echo "2. uwsm default (~/.config/uwsm/default):"
    echo "   export TERMINAL=ghostty"
    echo ""
    echo "3. Zsh (~/.zshrc): agregar al final las líneas de:"
    echo "   cat $REPO/SETUP.md | grep -A20 'Zsh.*fusionado'"
    echo ""
    echo "4. Tmux: Ctrl+Space + I (instalar plugins TPM)"
    echo ""
    echo "5. Nvim: nvim (Lazy instala todo)"
    echo ""
    echo "Ver SETUP.md para detalles y troubleshooting."
}

main "$@"