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

# --- Salesforce CLI (sf) completions ---
# Reemplazan al viejo _sfdx. Se generan al abrir shell si `sf` está en PATH.
if command -v sf >/dev/null 2>&1; then
  sf completion zsh > "${fpath[1]}/_sf" 2>/dev/null
fi

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

# --- Salesforce ---
alias sforgs='sf org list'
alias sfopen='sf org open'
alias sftest='sf apex run test --code-coverage --result-format human'
alias sflog='sf apex log tail --color'
alias sfdeploy='sf project deploy start --source-dir force-app'
alias sfretrieve='sf project retrieve start --source-dir force-app'

# Java 21 (Adoptium Temurin via brew openjdk@21). Necesario para apex-jdtls
# (LSP de Apex en nvim) y sf CLI plugins que lo requieren.
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# Acceso rápido al proyecto SF (cd + abrir editor)
alias cdsf='cd ~/projects/dapsa-sf/dapsa-sf'
alias hatsf='cd ~/projects/dapsa-sf/dapsa-sf && nvim'
alias hatsfc='cd ~/projects/dapsa-sf/dapsa-sf && code .'

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

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# study-pipeline defaults for quill's on_stop hook (added 2026-08-26)
export STUDY_MATERIA="General"
# Uncomment and edit to override per session:
# export STUDY_LANG="es"
# export STUDY_PROVIDER="ollama"
