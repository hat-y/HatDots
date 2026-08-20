#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# HatDots/HatMac — herdr LaunchAgent installer
#
# Detects the herdr binary path (Apple Silicon / Intel), generates a
# LaunchAgent plist, and loads it. The agent runs `herdr server` as a
# persistent background daemon that survives reboots and lid closes.
#
# Usage:
#   ./HatMac/herdr/install.sh             # install + load
#   ./HatMac/herdr/install.sh --uninstall # stop + unload + remove
#   ./HatMac/herdr/install.sh --restart   # unload + load
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABEL="com.user.herdr"
PLIST_SRC="$SCRIPT_DIR/com.user.herdr.plist.template"
PLIST_DST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LOG_DIR="$HOME/Library/Logs/herdr"
HERDR_LOGS="$LOG_DIR/server.log"

usage() {
  echo "Uso: $0 [--uninstall | --restart]"
  echo ""
  echo "Sin flags: detecta herdr, genera plist, lo carga con launchctl."
  echo "--uninstall  stop el server + unload del LaunchAgent + borra plist"
  echo "--restart    unload + load (recargar config)"
  exit 0
}

detect_herdr_bin() {
  command -v herdr || {
    echo "� herdr no encontrado en PATH"
    echo "   Instalalo primero: brew install herdr"
    exit 1
  }
}

uninstall() {
  if [ -f "$PLIST_DST" ]; then
    launchctl unload "$PLIST_DST" 2>/dev/null || true
    rm -f "$PLIST_DST"
    echo "✓ LaunchAgent removido: $PLIST_DST"
  else
    echo "⚠️  LaunchAgent no estaba instalado"
  fi
  if command -v herdr >/dev/null 2>&1; then
    herdr server stop 2>/dev/null || true
    echo "✓ herdr server detenido"
  fi
  exit 0
}

restart() {
  if [ ! -f "$PLIST_DST" ]; then
    echo "❌ LaunchAgent no instalado. Corré $0 sin flags primero."
    exit 1
  fi
  launchctl unload "$PLIST_DST" 2>/dev/null || true
  launchctl load -w "$PLIST_DST"
  echo "✓ LaunchAgent recargado"
  exit 0
}

case "${1:-}" in
  -h|--help)   usage ;;
  --uninstall) uninstall ;;
  --restart)   restart ;;
  "")          : ;;
  *)           echo "Flag desconocida: $1"; usage ;;
esac

# ── Install ───────────────────────────────────────────────────────────────────

HERDR_BIN="$(detect_herdr_bin)"

if [ ! -f "$PLIST_SRC" ]; then
  echo "� Template no encontrado: $PLIST_SRC"
  exit 1
fi

mkdir -p "$(dirname "$PLIST_DST")" "$LOG_DIR"

# Generar plist con paths reales
sed \
  -e "s|__HERDR_BIN__|$HERDR_BIN|g" \
  -e "s|__HERDR_LOG__|$HERDR_LOGS|g" \
  "$PLIST_SRC" > "$PLIST_DST"

# Unload si ya estaba cargado
launchctl unload "$PLIST_DST" 2>/dev/null || true

# Load con -w para que persista en login futuros
launchctl load -w "$PLIST_DST"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✓ herdr LaunchAgent instalado y corriendo"
echo ""
echo "  Binario:    $HERDR_BIN"
echo "  Plist:      $PLIST_DST"
echo "  Logs:       $HERDR_LOGS"
echo ""
echo "Verificá:"
echo "  launchctl list | grep herdr"
echo "  herdr status server"
echo ""
echo "Próximos pasos:"
echo "  • Cerrá y reabrí Ghostty — debería attach a herdr"
echo "  • Dentro de herdr: prefix + ? para ver todos los keybinds"
echo "  • Para desinstalar: $0 --uninstall"
echo "═══════════════════════════════════════════════════════"
