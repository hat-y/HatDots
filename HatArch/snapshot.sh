#!/usr/bin/env bash
set -euo pipefail

DST="$HOME/HatDots/HatArch/DenAsari"
mkdir -p "$DST"/{hypr,waybar,ghostty,fastfetch,swaync,bin,wallpapers,vesktop,btop,wofi,wlogout,yazi}

have_rsync=0; command -v rsync >/dev/null && have_rsync=1

copydir() {
  src="$1"; dst="$2"; shift 2
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  if [ "$have_rsync" -eq 1 ]; then
    rsync -a "$src"/ "$dst"/ "$@"
  else
    cp -a "$src"/. "$dst"/
  fi
}

# Copias
copydir "$HOME/.config/hypr"      "$DST/hypr"
copydir "$HOME/.config/waybar"    "$DST/waybar"
copydir "$HOME/.config/fastfetch" "$DST/fastfetch"
copydir "$HOME/.config/swaync"    "$DST/swaync"
copydir "$HOME/.config/btop"      "$DST/btop"
copydir "$HOME/.config/wofi"      "$DST/wofi"
copydir "$HOME/.config/wlogout"   "$DST/wlogout"
copydir "$HOME/.config/yazi"      "$DST/yazi"

# Vesktop: excluye cachés y Singletons
if [ "$have_rsync" -eq 1 ]; then
  copydir "$HOME/.config/vesktop" "$DST/vesktop" \
    --exclude 'Singleton*' --exclude '*/Cache*' --exclude '*/GPUCache*' --exclude 'Crashpad*' --exclude 'Code Cache*'
else
  copydir "$HOME/.config/vesktop" "$DST/vesktop"
  rm -f "$DST/vesktop"/Singleton* 2>/dev/null || true
fi

# Scripts locales
[ -x "$HOME/.local/bin/ffetch" ]  && install -m755 "$HOME/.local/bin/ffetch"  "$DST/bin/ffetch"
[ -x "$HOME/.local/bin/wallset" ] && install -m755 "$HOME/.local/bin/wallset" "$DST/bin/wallset"

# Wallpapers
if [ "$have_rsync" -eq 1 ]; then
  rsync -a --include='*.jpg' --include='*.png' --include='*.webp' --exclude='*' \
    "$HOME/Pictures/wallpapers/" "$DST/wallpapers/" 2>/dev/null || true
else
  find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) -exec cp -a "{}" "$DST/wallpapers/" \; 2>/dev/null || true
fi

# Reemplazo seguro de rutas solo en archivos regulares
find "$DST" -type f -print0 | xargs -0 sed -i "s#/home/plagus#$HOME#g"

echo "Snapshot copiado en: $DST"

