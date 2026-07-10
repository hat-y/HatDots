# HatDots — Guía de Reinstalación

## Flujo completo: Omarchy fresco → HatDots

Cuando reinstalés Omarchy o tengas un sistema limpio, seguí estos pasos en orden.

---

## 1. Omarchy (primero)

```bash
# Seguir la guía de Omarchy
# omarchy install
```

Omarchy instala: Hyprland, Waybar, Walker, Mako, Ghostty, tmux, Alacritty, Kitty, Foot, Fastfetch, Btop, ~230 bin scripts.

---

## 2. Instalar dependencias que Omarchy no incluye

```bash
sudo pacman -S neovim tmux ghostty ghostty-shell-integration ghostty-terminfo eza zoxide fzf
```

- **nvim**: para el editor (LazyVim)
- **ghostty + shell-integration + terminfo**: terminal (Omarchy ya instala ghostty pero verificá)
- **eza, zoxide, fzf**: herramientas que zsh usa
- **tmux**: sesiones (Omarchy lo incluye)

### Multiplexor (opcional, recomendado)

HatDots prefiere **Herdr** sobre Tmux cuando el binario `herdr` está en PATH, con Tmux como fallback automático. El wrapper `HatLinux/scripts/ghostty-multiplexer-new` decide en cada arranque. Fish shell (`HatLinux/fish/config.fish`) y Zsh (`HatLinux/zsh/.zshrc`) aplican el mismo guard.

```bash
brew install herdr        # macOS / Linuxbrew (Omarchy trae Homebrew)
cargo install herdr       # alternativa Linux
```

⚠️ **License caveat**: Herdr upstream publica con SPDX `NOASSERTION` (source-available, no OSS por defecto). Evaluá antes de uso comercial o redistribución.

⚠️ **Version warning**: testeado contra **v0.4.x**. Versiones más nuevas pueden haber renombrado config keys (e.g. `focus_agent` → `jump_to_agent`).

🪟 **Windows**: Herdr no tiene binario nativo. Usá WSL, o quedate en Tmux fallback.

Ver `HatLinux/herdr/README.md` para detalles completos y `HatLinux/README.md` para el setup.

---

## 3. Instalar HatDots

```bash
git clone https://github.com/hat-y/HatDots.git ~/projects/HatDots
cd ~/projects/HatDots
chmod +x link-linux.sh
./link-linux.sh
```

Esto crea:
```
~/.config/nvim              → ~/projects/HatDots/HatLinux/nvim
~/.config/tmux/tmux.conf     → ~/projects/HatDots/terminals/tmux/tmux.conf
```

Tmux plugins (TPM): dentro de tmux → `Ctrl+Space + I`

---

## 4. Ghostty — config fusionada

```bash
cat > ~/.config/ghostty/config << 'EOF'
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
EOF

# Shaders symlink
ln -sfn ~/projects/HatDots/terminals/ghostty/shaders ~/.config/ghostty/shaders
```

---

## 5. Launcher scripts

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/hatdots-launch-terminal << 'EOF'
#!/bin/bash
cwd="$(omarchy-cmd-terminal-cwd 2>/dev/null || pwd)"
exec setsid uwsm-app -- ghostty -e bash -c "cd '$cwd' && exec zsh"
EOF

cat > ~/.local/bin/hatdots-launch-terminal-tmux << 'EOF'
#!/bin/bash
ws="Work"
if command -v hyprctl &>/dev/null; then
  ws_name=$(hyprctl activeworkspace -j 2>/dev/null | grep -oP '"name"\s*:\s*"\K[^"]+')
  [[ -n "$ws_name" ]] && ws="ws-${ws_name}"
fi
cwd="$(omarchy-cmd-terminal-cwd 2>/dev/null || pwd)"
exec setsid uwsm-app -- ghostty -e bash -c "cd '$cwd' && exec tmux-session-layout '$ws'"
EOF

cat > ~/.local/bin/tmux-session-layout << 'EOF'
#!/bin/bash
# tmux-session-layout — Create a tmux session with 3 windows:
#   Window 1: nvim | Window 2: shell | Window 3: shell

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
EOF

chmod +x ~/.local/bin/hatdots-launch-terminal
chmod +x ~/.local/bin/hatdots-launch-terminal-tmux
chmod +x ~/.local/bin/tmux-session-layout
```

---

## 6. Hyprland bindings

Editá `~/.config/hypr/bindings.lua` y buscá las líneas de terminal. Cambiar de `xdg-terminal-exec` / `ghostty` / `alacritty` a los scripts de HatDots:

```lua
o.bind("SUPER + RETURN", "Terminal (Ghostty)", "hatdots-launch-terminal")
o.bind("SUPER + ALT + RETURN", "Tmux (workspace)", "hatdots-launch-terminal-tmux")
```

```bash
hyprctl reload
```

---

## 7. uwsm — terminal default

```bash
# Editar ~/.config/uwsm/default
export TERMINAL=ghostty
```

---

## 8. Zsh — fusionado sobre CachyOS

El `.zshrc` ya existe en CachyOS. Solo agregar al final:

```bash
# HatDots additions (agregar al ~/.zshrc existente)

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# zoxide
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# eza aliases
alias ls='eza --icons=auto --group-directories-first --classify'
alias ll='eza -lh --git --icons=auto --group-directories-first --classify'
alias la='eza -lha --git --icons=auto --group-directories-first --classify'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="/home/hat/.opencode/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

Powerlevel10k custom:
```bash
cp ~/projects/HatDots/HatLinux/zsh/.p10k.zsh ~/.p10k.zsh
```

---

## 9. Nvim — primer arranque

```bash
nvim  # Lazy instala todo automáticamente

# Opcional: limpiar cache si hubo errores
# mv ~/.local/share/nvim/lazy/lazy.nvim/.cache ~/.local/share/nvim/lazy/lazy.nvim/.cache.bak
# mv ~/.local/state/nvim ~/.local/state/nvim.bak
```

Cambiar theme: `:Lazy` → buscar theme → `...` → Reload

---

## 10. Tmux — reload config

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

Verificar shell: `tmux show-options -g default-shell` → `/bin/zsh`

---

## Checklist final

```bash
# Verificaciones rápidas
which ghostty                    # ghostty instalado
which nvim                       # nvim instalado
tmux show -g default-shell       # debe ser /bin/zsh
cat ~/.config/uwsm/default       # TERMINAL=ghostty
ls ~/.config/ghostty/shaders     # 52 shaders
ls ~/.local/bin/hatdots*         # 2 launchers + tmux-session-layout
```

---

## División HatDots ↔ Omarchy

| Componente    | HatDots                              | Omarchy                              |
|---------------|--------------------------------------|--------------------------------------|
| Neovim        | LazyVim + aether + 20 themes         | —                                    |
| Tmux          | TPM plugins + layout script           | Keybindings + status bar              |
| Ghostty       | Shaders + config                     | Theme dinámico                       |
| Zsh           | Vi-mode, zoxide, eza, p10k           | —                                    |
| Hyprland      | Launcher scripts                     | Todo lo demás                        |
| Waybar/Walker | —                                    | Todo                                |

Omarchy es la base, HatDots es la personalización del editor y terminal.