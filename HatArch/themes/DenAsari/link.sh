#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/HatDots/HatArch/DenAsari"
TS="$(date +%F_%H%M%S)"

link_dir() {
  src="$1"; dst="$2"
  [ -d "$src" ] || { echo "skip $src"; return; }
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then rm -f "$dst"
  elif [ -e "$dst" ]; then mv "$dst" "${dst}.bak-${TS}"
  fi
  ln -s "$src" "$dst"
  echo "→ $dst → $src"
}

link_file() {
  src="$1"; dst="$2"
  [ -f "$src" ] || { echo "skip $src"; return; }
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then rm -f "$dst"
  elif [ -e "$dst" ]; then mv "$dst" "${dst}.bak-${TS}"
  fi
  ln -s "$src" "$dst"
  echo "→ $dst → $src"
}

# ~/.config/*
link_dir "$ROOT/hypr"      "$HOME/.config/hypr"
link_dir "$ROOT/waybar"    "$HOME/.config/waybar"
link_dir "$ROOT/fastfetch" "$HOME/.config/fastfetch"
link_dir "$ROOT/swaync"    "$HOME/.config/swaync"
link_dir "$ROOT/vesktop"   "$HOME/.config/vesktop"
link_dir "$ROOT/btop"      "$HOME/.config/btop"
link_dir "$ROOT/wofi"      "$HOME/.config/wofi"
link_dir "$ROOT/wlogout"   "$HOME/.config/wlogout"
link_dir "$ROOT/yazi"      "$HOME/.config/yazi"
link_dir "$ROOT/spicetify" "$HOME/.config/spicetify"

# ~/.local/bin/*
mkdir -p "$HOME/.local/bin"
link_file "$ROOT/bin/ffetch"  "$HOME/.local/bin/ffetch"
link_file "$ROOT/bin/wallset" "$HOME/.local/bin/wallset"

# (opcional) wallpapers
# link_dir "$ROOT/wallpapers" "$HOME/Pictures/wallpapers"

