set -euo pipefail
mkdir -p ~/.local/bin
for f in desktop-profile wallpaper-apply; do
  chmod +x "$HOME/HatDots/HatArch/bin/$f"
  ln -sfn "$HOME/HatDots/HatArch/bin/$f" "$HOME/.local/bin/$f"
done
echo "OK"
