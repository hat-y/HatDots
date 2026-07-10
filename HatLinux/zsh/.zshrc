# ============================================================================
# Hat's Zsh Configuration
# Powerlevel10k + modern tooling
# ============================================================================

# --- Variables de entorno básicas ---
export EDITOR="nvim"

# --- Configuración del historial ---
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY

# --- Modo vi para la línea de comandos ---
bindkey -v
export KEYTIMEOUT=1

# --- FZF key bindings ---
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh

# --- Inicialización de completions ---
autoload -Uz compinit && compinit -u

# --- Plugins (carga temprana - autosuggestions puede estar aquí) ---
ZSH_PLUGINS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
[ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- Zoxide & Atuin ---
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v atuin  >/dev/null && eval "$(atuin init zsh)"

# --- Aliases ---
alias ls='eza --icons=auto --group-directories-first --classify'
alias ll='eza -lh --git --icons=auto --group-directories-first --classify'
alias la='eza -lha --git --icons=auto --group-directories-first --classify'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# --- Powerlevel10k ---
P10K_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k"

# Deshabilitar auto-instalación de gitstatusd (evita el error si no hay build tools)
export GITSTATUS_AUTO_INSTALL=0

if [ -f "$P10K_DIR/powerlevel10k.zsh-theme" ]; then
  source "$P10K_DIR/powerlevel10k.zsh-theme"
fi

# Cargar configuración de p10k
[ -f "$HOME/.p10k.zsh" ] && source "$HOME/.p10k.zsh"

# Deshabilitar segmento vcs para evitar error de gitstatus
# (el prompt va a mostrar el directorio sin info de git en tiempo real)
#typeset -g POWERLEVEL9K_VCS_DISABLED=true

# --- Multiplexer auto-start: Herdr > Tmux > nothing ---
# Guard vars HERDR_ENV, TMUX, ZELLIJ must all be unset.
# See openspec/changes/add-herdr-multiplexor/spec.md DG-5 for parity with Fish.
# If gitstatus fails under Herdr PTY, also try POWERLEVEL9K_DISABLE_GITSTATUS=true
# (R-9 escape hatch).
if [[ -o interactive ]] && [[ -z "$HERDR_ENV" && -z "$TMUX" && -z "$ZELLIJ" ]]; then
    if command -v herdr >/dev/null 2>&1 && herdr --version >/dev/null 2>&1; then
        exec herdr
    elif command -v tmux >/dev/null 2>&1; then
        tmux new-session -A -s main
    fi
fi

# --- zsh-syntax-highlighting (DEBE ir al final) ---
[ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- PATH ---
export PATH="$HOME/.local/bin:$PATH"
export PATH=/home/hat/.opencode/bin:$PATH


# Load Angular CLI autocompletion.
source <(ng completion script)

# bun completions
[ -s "/home/hat/.bun/_bun" ] && source "/home/hat/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
