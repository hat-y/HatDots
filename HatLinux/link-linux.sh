set -euo pipefail

# --- Ajusta si tu repo tiene otro nombre/ubicación ---
DOT="$HOME/HatDots/HatLinux"

# --- Utilidades ---
TS="$(date +%Y%m%d-%H%M%S)"

backup_if_real() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    mv "$path" "${path}.bak.${TS}"
    echo "[backup] ${path} -> ${path}.bak.${TS}"
  fi
}

normalize_lf() {
  local file="$1"
  [ -f "$file" ] || return 0
  # quita CRLF si viniera desde Windows
  sed -i 's/\r$//' "$file" || true
}

link_to() {
  # link_to <target> <linkpath>
  local target="$1"
  local linkpath="$2"
  mkdir -p "$(dirname "$linkpath")"
  backup_if_real "$linkpath"
  ln -sfn "$target" "$linkpath"
  echo "[link] $linkpath -> $target"
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "Falta '$1' en PATH"; exit 1; }; }
need ln
need sed

# --- Estructura esperada del repo ---
# $DOT/nvim/init.lua
# $DOT/ghostty/config
# $DOT/starship/starship.toml
# $DOT/shell/.zshrc

# Normaliza finales de línea por si vinieron CRLF
normalize_lf "$DOT/ghostty/config"
normalize_lf "$DOT/starship/starship.toml"
normalize_lf "$DOT/shell/.zshrc"

# --- NVIM ---
if [ -d "$DOT/nvim" ]; then
  link_to "$DOT/nvim" "$HOME/.config/nvim"
else
  echo "[warn] No existe $DOT/nvim (saltando NVIM)"
fi

# --- GHOSTTY ---
if [ -f "$DOT/ghostty/config" ]; then
  # Recomendado: linkear la CARPETA completa de ghostty
  link_to "$DOT/ghostty" "$HOME/.config/ghostty"
else
  echo "[warn] No existe $DOT/ghostty/config (saltando Ghostty)"
fi

# --- STARSHIP ---
if [ -f "$DOT/starship/starship.toml" ]; then
  link_to "$DOT/starship/starship.toml" "$HOME/.config/starship.toml"
else
  echo "[warn] No existe $DOT/starship/starship.toml (saltando Starship)"
fi

# --- ZSH ---
if [ -f "$DOT/shell/.zshrc" ]; then
  link_to "$DOT/shell/.zshrc" "$HOME/.zshrc"
else
  echo "[warn] No existe $DOT/shell/.zshrc (saltando Zsh)"
fi

echo
echo "=== Verificación rápida ==="
for p in \
  "$HOME/.config/nvim" \
  "$HOME/.config/ghostty" \
  "$HOME/.config/ghostty/config" \
  "$HOME/.config/starship.toml" \
  "$HOME/.zshrc"
do
  if [ -e "$p" ] || [ -L "$p" ]; then
    printf "%-35s -> %s\n" "$p" "$(readlink -f "$p" || echo 'N/A')"
  fi
done

if command -v ghostty >/dev/null 2>&1; then
::contentReference[oaicite:0]{index=0}
