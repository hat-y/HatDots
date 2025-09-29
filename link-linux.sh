set -Eeuo pipefail

REPO="$HOME/HatDots/HatLinux"
mkdir -p "$HOME/.config" "$HOME/.config/ghostty"

safe_link () { # dst src
  local dst="$1" src="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -d "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak.$(date +%s)"; fi
  ln -sfn "$src" "$dst"
  echo "✓ $dst -> $src"
}

safe_link "$HOME/.config/nvim"                   "$REPO/nvim"
safe_link "$HOME/.config/ghostty/config"         "$REPO/HatGhostty/config"
safe_link "$HOME/.config/starship.toml"          "$REPO/starship/starship.toml"
safe_link "$HOME/.tmux.conf"                     "$REPO/HatTmux/.tmux.conf"
safe_link "$HOME/.zshrc"                         "$REPO/HatZsh/.zshrc"
safe_link "$HOME/.p10k.zsh"                      "$REPO/HatZsh/.p10k.zsh"

