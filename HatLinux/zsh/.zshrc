# ============================================================================
# Hat's Zsh Configuration — HatDots adapted for CachyOS/Omarchy
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

# --- Plugins: zsh-autosuggestions ---
# CachyOS: system-wide. Fallback: ~/.local/share/zsh/
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
else
  local as_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-autosuggestions"
  [ -f "$as_dir/zsh-autosuggestions.zsh" ] && source "$as_dir/zsh-autosuggestions.zsh"
fi

# --- Zoxide (smart cd) ---
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# --- Atuin (shell history) ---
# command -v atuin >/dev/null && eval "$(atuin init zsh)"

# --- Aliases ---
alias ls='eza --icons=auto --group-directories-first --classify'
alias ll='eza -lh --git --icons=auto --group-directories-first --classify'
alias la='eza -lha --git --icons=auto --group-directories-first --classify'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# --- Powerlevel10k ---
# CachyOS: system-wide
if [ -f /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]; then
  source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
else
  local p10k_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k"
  [ -f "$p10k_dir/powerlevel10k.zsh-theme" ] && source "$p10k_dir/powerlevel10k.zsh-theme"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- zsh-syntax-highlighting (DEBE ir al final) ---
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
  local sh_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-syntax-highlighting"
  [ -f "$sh_dir/zsh-syntax-highlighting.zsh" ] && source "$sh_dir/zsh-syntax-highlighting.zsh"
fi

# --- PATH ---
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
