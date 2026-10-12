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

# --- Salesforce CLI (sf) completions ---
# Reemplazan al viejo _sfdx. Se generan al abrir shell si `sf` está en PATH.
if command -v sf >/dev/null 2>&1; then
  sf completion zsh > "${fpath[1]}/_sf" 2>/dev/null
fi

# --- Salesforce ---
alias sforgs='sf org list'
alias sfopen='sf org open'
alias sftest='sf apex run test --code-coverage --result-format human'
alias sflog='sf apex log tail --color'
alias sfdeploy='sf project deploy start --source-dir force-app'
alias sfretrieve='sf project retrieve start --source-dir force-app'

# Disable gitstatusd auto-install (avoids errors when build tools are missing)
export GITSTATUS_AUTO_INSTALL=0

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
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
  local sh_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-syntax-highlighting"
  [ -f "$sh_dir/zsh-syntax-highlighting.zsh" ] && source "$sh_dir/zsh-syntax-highlighting.zsh"
fi

# --- PATH ---
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# Load Angular CLI autocompletion.
command -v ng >/dev/null 2>&1 && source <(ng completion script)

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- OS / local overlays ---
# Linked by the installer into ~/.config/hatdots/. Sourced last: nothing
# above depends on overlay-set state, and this still lets the overlay's own
# zsh-syntax-highlighting attempt (if any) run after everything else.
[ -f ~/.config/hatdots/os.zsh ] && source ~/.config/hatdots/os.zsh
[ -f ~/.config/hatdots/local.zsh ] && source ~/.config/hatdots/local.zsh
