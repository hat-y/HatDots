# HatDots — Guía de Reinstalación

## Alcance y portabilidad

HatDots contiene configuraciones de editor y terminal; **HatNotes** es el vault de Obsidian separado. HatDots no clona, enlaza ni respalda HatNotes.

La instalación corre a través de un único instalador Go + Bubbletea (`hatdots`, ver `installer/README.md`) manejado por `modules.toml`. Para ver qué módulos aplican a cada plataforma, correé `hatdots list` o mirá ese manifest directamente.

### Vault de Obsidian

HatNotes es un compañero **requerido solo para los comandos de creación de Obsidian/Neovim**. Antes de usarlos, cloná o sincronizá HatNotes y verificá que las diez plantillas estén en `$HATNOTES_PATH/7-Tmpl`; el resto de los dotfiles de HatDots sigue siendo usable sin HatNotes.

Las configuraciones de Neovim en Linux y Windows usan `HATNOTES_PATH` si está definido; si no, Neovim expande `~/HatNotes`. El módulo compartido vive en `common/nvim/lua/hatnotes/` (parte de la config unificada desde Phase 3, ya no un `shared/nvim` aparte).

```bash
export HATNOTES_PATH="$HOME/ruta/a/HatNotes" # Linux, antes de abrir nvim
```

```powershell
$env:HATNOTES_PATH = "C:\ruta\a\HatNotes" # PowerShell, antes de abrir nvim
```

### Reemplazos y backups

`hatdots` respalda cualquier archivo o directorio real que vaya a reemplazar (acción `backup-then-link`, con un nombre de backup libre de colisiones) antes de crear el symlink; un symlink ya apuntando al destino correcto se deja intacto (`link-skip-identical`). La preview (CLI o TUI) siempre lista qué se va a respaldar antes de aplicar nada.

> **No edites a mano los archivos que HatDots enlaza.** `~/.config/nvim`, `~/.config/ghostty`, `~/.config/hypr/bindings.lua`, etc. son symlinks al repo: escribir en ellos (por ejemplo con un `cat > ... << EOF`) modifica el archivo versionado. Los cambios propios de una máquina van en `~/.config/hatdots/local.*`.

## Flujo completo: Omarchy fresco → HatDots

Cuando reinstalés Omarchy o tengas un sistema limpio, seguí estos pasos en orden.

---

## 1. Omarchy (primero)

```bash
# Seguir la guía de Omarchy
# omarchy install
```

Omarchy instala: Hyprland, Waybar, Walker, Mako, Ghostty, tmux, Alacritty, Kitty, Foot, Fastfetch, Btop, ~230 bin scripts. También deja `TERMINAL=ghostty` en `~/.config/uwsm/default`, que es lo que HatDots espera.

---

## 2. Dependencias

No hace falta instalarlas a mano: cada módulo de `modules.toml` declara sus paquetes y `hatdots` los instala con `pacman` (o `apt`/`dnf`/`zypper`/`brew`/`winget`/`scoop`). Antes de instalar consulta `pacman -T`, así que un paquete ya provisto por otro (por ejemplo `neovim-git` en lugar de `neovim`) se saltea en vez de reemplazarse. Instalar un paquete faltante pide tu contraseña de `sudo`.

### Multiplexor (opcional, recomendado)

HatDots prefiere **Herdr** sobre Tmux cuando el binario `herdr` está en PATH, con Tmux como fallback automático. El wrapper `common/bin/ghostty-multiplexer-new` decide en cada arranque. Fish shell (`common/fish/config.fish`) y Zsh (`common/zsh/.zshrc`) aplican el mismo guard. El módulo `herdr` solo declara el paquete para `brew`, así que en Linux el instalador enlaza la config pero no instala el binario:

```bash
sudo pacman -S herdr      # Omarchy: viene en su propio repo (`omarchy`)
cargo install herdr       # otras distros
```

⚠️ **License caveat**: Herdr upstream publica con SPDX `NOASSERTION` (source-available, no OSS por defecto). Evaluá antes de uso comercial o redistribución.

⚠️ **Version warning**: la config se escribió contra **v0.4.x** y upstream es pre-1.0, así que versiones más nuevas pueden haber renombrado config keys (e.g. `focus_agent` → `jump_to_agent`).

🪟 **Windows**: Herdr no tiene binario nativo. Usá WSL, o quedate en Tmux fallback.

Ver `common/herdr/README.md` para detalles completos y `os/linux/README.md` para el setup.

---

## 3. Instalar HatDots

```bash
curl -fsSL https://raw.githubusercontent.com/hat-y/HatDots/main/bootstrap.sh | sh
```

`bootstrap.sh` clona el repo en `${HATDOTS_DIR:-$HOME/projects/HatDots}`, descarga el binario `hatdots` de la última release (verificando su sha256) y lo corre; si todavía no hay ninguna release publicada y tenés Go, cae a `go run ./installer/cmd/hatdots`. Con una terminal real abre una TUI interactiva (detección → selección de módulos → preview → aplicar); en la preview, aplicar es siempre con `y` explícito (`enter` no hace nada), y el dry-run queda bloqueado en "on" si lo pasaste por `--dry-run` (`d` ya no puede apagarlo). `--only`/`--all` preseleccionan los módulos de la TUI; con `--yes` se aplica sin TUI (`hatdots --all --yes`) para scripting. Ver `installer/README.md` y `SETUP.md` para el detalle completo, incluidos los overlays `~/.config/hatdots/os.*`/`omarchy.*`/`local.*`.

Conviene mirar el plan antes de aplicar:

```bash
hatdots --dry-run
```

---

## 4. Qué deja instalado (Omarchy)

Con la selección por defecto en Omarchy, `hatdots` crea, entre otros, estos symlinks al repo (`~/projects/HatDots/...`):

| Módulo     | Destino                                                    | Origen en el repo                          |
|------------|------------------------------------------------------------|--------------------------------------------|
| nvim       | `~/.config/nvim`                                           | `common/nvim`                              |
| fish       | `~/.config/fish/config.fish`                               | `common/fish/config.fish`                  |
| tmux       | `~/.config/tmux/tmux.conf`, `~/.config/hatdots/omarchy.tmux.conf` | `common/tmux/`, `os/omarchy/tmux/`  |
| ghostty    | `~/.config/ghostty` (config, shaders, themes), `~/.config/hatdots/{os,omarchy}.ghostty` | `common/ghostty`, `os/linux/ghostty/`, `os/omarchy/ghostty/` |
| herdr      | `~/.config/herdr/config.toml`                              | `common/herdr/config.toml`                 |
| newsboat   | `~/.config/newsboat/{config,urls}`, `~/.local/bin/hat-news` | `common/newsboat/`, `os/omarchy/newsboat/` |
| hypr       | `~/.config/hypr/{bindings,autostart}.lua`                  | `os/omarchy/hypr/`                         |
| hypr       | `~/.local/bin/{hatdots-launch-terminal,hatdots-launch-terminal-tmux,tmux-session-layout}` | `os/omarchy/bin/` |
| zsh        | `~/.p10k.zsh`                                              | `common/zsh/.p10k.zsh`                     |

Notas:

- **Ghostty** usa la paleta Gentleman (fondo `#06080f`) también en Omarchy. Para que siga el tema activo de Omarchy, descomentá la línea `config-file` de `os/omarchy/ghostty/omarchy.ghostty`, o ponela en `~/.config/hatdots/local.ghostty` para hacerlo en una sola máquina.
- **Neovim** sí sigue el tema activo de Omarchy, con recarga en vivo.
- **Hyprland**: `bindings.lua` deja `SUPER + RETURN` → `hatdots-launch-terminal` y `SUPER + ALT + RETURN` → `hatdots-launch-terminal-tmux`; `autostart.lua` corre `hat-news` al iniciar. Si Hyprland no los toma solo, `hyprctl reload`.
- **Zsh en Linux**: solo se enlaza `~/.p10k.zsh`; tu `~/.zshrc` queda como está (el `.zshrc` del repo se enlaza únicamente en macOS).
- **Tmux**: el post-install clona TPM en `~/.config/tmux/plugins/tpm`. Los plugins se instalan desde tmux con `Ctrl+Space` y después `I`.

---

## 5. Nvim — primer arranque

```bash
nvim  # Lazy instala todo automáticamente
```

`lazy-lock.json` es uno solo para todos los OS. Si los plugins en disco quedaron en otras versiones (por ejemplo, venías de otra config), alinealos con el lock del repo:

```bash
nvim --headless '+Lazy! restore' +qa
```

Si hubo errores en el primer arranque, mové los caches y volvé a abrir:

```bash
mv ~/.local/share/nvim/lazy/lazy.nvim/.cache ~/.local/share/nvim/lazy/lazy.nvim/.cache.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
```

---

## Checklist final

```bash
readlink ~/.config/nvim                           # → .../HatDots/common/nvim
tmux show -g default-shell                        # /usr/bin/fish (si fish está instalado)
ghostty +validate-config                          # sin errores
ghostty +show-config | rg '^background = '        # background = #06080f
fd -e glsl . ~/.config/ghostty/shaders/ | wc -l   # 52 shaders
command -v hatdots-launch-terminal hatdots-launch-terminal-tmux   # 2 launchers
hyprctl configerrors                              # vacío
fd -H -d 4 hatdots-bak ~/.config ~/.local/bin     # backups de lo que se reemplazó
```

---

## División HatDots ↔ Omarchy

| Componente    | HatDots                                        | Omarchy                              |
|---------------|------------------------------------------------|--------------------------------------|
| Neovim        | LazyVim + sf.nvim + temas; sigue el tema activo | Tema activo                          |
| Fish          | Config completa (shell por defecto de tmux)    | —                                    |
| Tmux          | TPM plugins + layout script + overlay Omarchy  | Keybindings + status bar             |
| Ghostty       | Config, shaders y paleta Gentleman             | Tema dinámico (opcional, desactivado) |
| Herdr         | Config del multiplexor                         | —                                    |
| Zsh           | `.p10k.zsh` (prompt estilo Pure)               | —                                    |
| Hyprland      | Bindings, autostart y launcher scripts         | Todo lo demás                        |
| Newsboat      | Config, feeds y notificador `hat-news`         | —                                    |
| Waybar/Walker | —                                              | Todo                                 |

Omarchy es la base, HatDots es la personalización del editor y terminal.
