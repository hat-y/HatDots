# ============================================================================
# Hat's Zsh Configuration — HatDots para macOS
# Powerlevel10k + Homebrew + tooling moderno
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

# --- Homebrew environment (Apple Silicon + Intel) ---
# Cargar el prefix detectado (exporta PATH, HOMEBREW_PREFIX, etc.)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- FZF key bindings (brew pone fzf en $HOMEBREW_PREFIX/opt/fzf) ---
if [ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  # fzf-completion opcional si está instalado
  if [ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then
    source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
  fi
elif [ -f "${XDG_DATA_HOME:-$HOME/.local/share}/fzf/key-bindings.zsh" ]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/fzf/key-bindings.zsh"
fi

# --- Inicialización de completions ---
autoload -Uz compinit && compinit -u

# --- Plugins: zsh-autosuggestions (brew o local) ---
if [ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
  local as_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-autosuggestions"
  [ -f "$as_dir/zsh-autosuggestions.zsh" ] && source "$as_dir/zsh-autosuggestions.zsh"
fi

# --- Zoxide (smart cd) ---
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# --- Atuin (shell history) ---
# Descomentar para activar
# command -v atuin >/dev/null && eval "$(atuin init zsh)"

# --- Aliases (eza con iconos) ---
alias ls='eza --icons=auto --group-directories-first --classify'
alias ll='eza -lh --git --icons=auto --group-directories-first --classify'
alias la='eza -lha --git --icons=auto --group-directories-first --classify'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# --- Powerlevel10k (brew o local) ---
if [ -f "$HOMEBREW_PREFIX/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  source "$HOMEBREW_PREFIX/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
elif [ -f "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
else
  local p10k_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k"
  [ -f "$p10k_dir/powerlevel10k.zsh-theme" ] && source "$p10k_dir/powerlevel10k.zsh-theme"
fi

# Para customizar el prompt: `p10k configure` o editar ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- zsh-syntax-highlighting (DEBE ir al final) ---
if [ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
  local sh_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-syntax-highlighting"
  [ -f "$sh_dir/zsh-syntax-highlighting.zsh" ] && source "$sh_dir/zsh-syntax-highlighting.zsh"
fi

# --- PATH ---
export PATH="$HOME/.local/bin:$PATH"

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
