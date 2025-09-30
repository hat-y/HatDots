#!/usr/bin/env bash
set -euo pipefail

sel="$((printf '[clear]\n'; cliphist list) \
  | wofi --dmenu --width 700 --height 400 --prompt 'Clipboard' || true)"

[ -n "${sel:-}" ] || exit 0

if [ "$sel" = "[clear]" ]; then
  cliphist wipe
  wl-copy --clear
  exit 0
fi

cliphist decode "$sel" | wl-copy

