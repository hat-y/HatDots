#!/usr/bin/env bash
# HatDots — HatNotes autosync LaunchAgent installer (macOS).
# Renders the plist with absolute paths and (re)loads it, idempotently.
#
# Usage:
#   ./os/mac/hatnotes/install.sh             # install + load
#   ./os/mac/hatnotes/install.sh --uninstall # unload + remove
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABEL="com.user.hatnotes-autosync"
PLIST_SRC="$SCRIPT_DIR/$LABEL.plist.template"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs/hatnotes"
BIN="$HOME/.local/bin/hatnotes-autosync"
DOMAIN="gui/$(id -u)"

case "${1:-}" in
  --uninstall)
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
    rm -f "$PLIST_DST"
    echo "✓ LaunchAgent removido: $PLIST_DST"
    exit 0
    ;;
  "") : ;;
  *) echo "Uso: $0 [--uninstall]"; exit 1 ;;
esac

if [ ! -f "$PLIST_SRC" ]; then
  echo "Template no encontrado: $PLIST_SRC"
  exit 1
fi

mkdir -p "$(dirname "$PLIST_DST")" "$LOG_DIR"

sed \
  -e "s|__AUTOSYNC_BIN__|$BIN|g" \
  -e "s|__HOME__|$HOME|g" \
  -e "s|__LOG__|$LOG_DIR/launchd.log|g" \
  "$PLIST_SRC" > "$PLIST_DST"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$PLIST_DST"

echo "✓ HatNotes autosync instalado (cada 15 min)"
echo "  Plist: $PLIST_DST"
echo "  Log:   ${XDG_STATE_HOME:-$HOME/.local/state}/hatnotes-autosync.log"
echo "  Desactivar: launchctl bootout $DOMAIN/$LABEL"
