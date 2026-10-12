#!/usr/bin/env bash
# HatDots macOS Installation Script
# Installs dependencies via Homebrew and creates symlinks for dotfiles
#
# Uso:
#   ./link-mac.sh                     # instala deps + crea symlinks
#   ./link-mac.sh --no-brew           # solo crea symlinks (asume deps ya instaladas)
#   ./link-mac.sh --no-cask           # no instala casks (apps GUI)
#   ./link-mac.sh --no-herdr-autostart # no instala LaunchAgent de herdr

set -Eeuo pipefail

# Auto-detect repo root from script location (works no matter where you clone).
# Override con env: HATDOTS_REPO=/custom/path ./link-mac.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${HATDOTS_REPO:-$SCRIPT_DIR}"
BREWFILE="$REPO/os/mac/Brewfile"

if [ ! -f "$BREWFILE" ]; then
  echo "❌ Brewfile no encontrado en: $BREWFILE"
  echo "   Verificá que estés corriendo este script desde la raíz del repo HatDots."
  exit 1
fi

INSTALL_BREW=true
INSTALL_CASKS=true
HERDR_AUTOSTART=yes

for arg in "$@"; do
  case "$arg" in
    --no-brew)  INSTALL_BREW=false ;;
    --no-cask)  INSTALL_CASKS=false ;;
    --no-herdr-autostart)  HERDR_AUTOSTART=no ;;
    -h|--help)
      echo "Uso: ./link-mac.sh [--no-brew] [--no-cask] [--no-herdr-autostart]"
      echo "  --no-brew            No correr brew bundle (asumir deps instaladas)"
      echo "  --no-cask            No instalar casks (apps GUI)"
      echo "  --no-herdr-autostart Skip LaunchAgent de herdr (server manual)"
      exit 0
      ;;
    *) echo "⚠️  Flag desconocida: $arg"; exit 1 ;;
  esac
done

# ── Homebrew check ─────────────────────────────────────────────────────────────
detect_brew_prefix() {
  if [ -f /opt/homebrew/bin/brew ]; then
    echo "/opt/homebrew"
  elif [ -f /usr/local/bin/brew ]; then
    echo "/usr/local"
  else
    echo ""
  fi
}

if [ "$INSTALL_BREW" = true ]; then
  BREW_PREFIX=$(detect_brew_prefix)
  if [ -z "$BREW_PREFIX" ]; then
    echo "❌ Homebrew no encontrado"
    echo "   Instalalo desde: https://brew.sh"
    exit 1
  fi
  echo "🍺 Homebrew detectado en: $BREW_PREFIX"

  echo ""
  echo "📦 Instalando dependencias (Brewfile)..."
  if [ "$INSTALL_CASKS" = false ]; then
    brew bundle --file="$BREWFILE" --no-cask --no-upgrade
  else
    brew bundle --file="$BREWFILE"
  fi

  # Tap fonts si hay casks de fuentes
  brew tap | grep -q "homebrew/cask-fonts" || true
  echo "✅ Dependencias instaladas"
fi

# ── Symlinks ───────────────────────────────────────────────────────────────────

echo ""
echo "📂 Creando symlinks..."

mkdir -p "$HOME/.config" \
         "$HOME/.config/ghostty" \
         "$HOME/.config/tmux" \
         "$HOME/.config/newsboat" \
         "$HOME/.config/herdr" \
         "$HOME/.local/bin"

safe_link() {
  local dst="$1" src="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local backup="${dst}.bak.$(date +%s)"
    mv "$dst" "$backup"
    echo "⚠️  Backup: $backup"
  fi
  ln -sfn "$src" "$dst"
  echo "✓ $dst -> $src"
}

# Neovim
safe_link "$HOME/.config/nvim"                  "$REPO/common/nvim"

# Zsh
safe_link "$HOME/.zshrc"                        "$REPO/common/zsh/.zshrc"
safe_link "$HOME/.p10k.zsh"                     "$REPO/common/zsh/.p10k.zsh"

# Ghostty (directorio completo: config + shaders + themes)
safe_link "$HOME/.config/ghostty"               "$REPO/common/ghostty"

# Tmux
safe_link "$HOME/.tmux.conf"                    "$REPO/common/tmux/tmux.conf"
safe_link "$HOME/.local/bin/tmux-work"          "$REPO/common/bin/tmux-work"
safe_link "$HOME/.local/bin/ghostty-tmux-new"   "$REPO/os/mac/bin/ghostty-tmux-new"

# OS overlays for the common configs linked above
mkdir -p "$HOME/.config/hatdots"
safe_link "$HOME/.config/hatdots/os.zsh"        "$REPO/os/mac/zsh/os.zsh"
safe_link "$HOME/.config/hatdots/os.ghostty"    "$REPO/os/mac/ghostty/os.ghostty"

# Newsboat
safe_link "$HOME/.config/newsboat/config"       "$REPO/common/newsboat/config"
safe_link "$HOME/.config/newsboat/urls"         "$REPO/common/newsboat/urls"
safe_link "$HOME/.local/bin/hat-news"           "$REPO/os/mac/newsboat/hat-news"
safe_link "$HOME/.config/hatdots/os.newsboat"   "$REPO/os/mac/newsboat/os.newsboat"

# herdr (terminal server para agentes de IA)
# config.toml: HatDots uses the same config on every OS (common/herdr/).
safe_link "$HOME/.config/herdr/config.toml"     "$REPO/common/herdr/config.toml"
HATMAC_HERDR="$REPO/os/mac/herdr"
chmod +x "$HATMAC_HERDR/install.sh"

# Instalar LaunchAgent para que herdr server arranque al login
# (skip con --no-herdr-autostart)
if [ "${HERDR_AUTOSTART:-yes}" != "no" ] && [ -f "$HATMAC_HERDR/install.sh" ]; then
  if command -v herdr >/dev/null 2>&1; then
    echo ""
    echo "🚀 Instalando LaunchAgent para herdr server..."
    "$HATMAC_HERDR/install.sh" || echo "⚠️  Falló la instalación del LaunchAgent. Reintentá con: $HATMAC_HERDR/install.sh"
  else
    echo "�️  herdr no instalado todavía. Después de 'brew install herdr' corré:"
    echo "   $HATMAC_HERDR/install.sh"
  fi
fi

echo ""
echo "=========================================="
echo "✅ Instalación HatMac completa!"
echo ""
echo "Próximos pasos:"
echo "  1. Reiniciá tu terminal o: source ~/.zshrc"
echo "  2. Si nunca usaste zsh: chsh -s /bin/zsh"
echo "  3. Configurá tu prompt: p10k configure"
echo "  4. Abrí Ghostty (esperá que Lazy instale plugins en nvim)"
echo "  5. Para RSS en TUI: hat-news --open"
echo ""
echo "⚠️  Lo que HatMac NO incluye (a propósito):"
echo "   • Hyprland → no existe en macOS"
echo "   • Yabai/skhd → elegiste minimal sin tiling WM"
echo "   • keybinds globales tipo SUPER+X → no hay compositor que los capture"
echo "   Todo el flujo vive dentro de Ghostty + tmux + nvim."
echo ""
echo "   Si más adelante querés tiling estilo Hyprland en Mac,"
echo "   mirá: brew install --cask yabai skhd"
