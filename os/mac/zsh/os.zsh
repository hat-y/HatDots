# macOS overlay for common/zsh/.zshrc. Linked by the hatdots installer into
# ~/.config/hatdots/os.zsh. Sourced at the very end of the common file, so
# ordering relative to common's own sections does not matter: nothing below
# depends on compinit/theme state set up earlier, and ~/.p10k.zsh (already
# sourced by common) is safe to source before its theme loads — it only
# `typeset -g`s POWERLEVEL9K_* variables and no-ops its `p10k reload` call
# when the `p10k` function isn't defined yet.

# --- Homebrew environment (Apple Silicon + Intel) ---
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- FZF key bindings (brew pone fzf en $HOMEBREW_PREFIX/opt/fzf) ---
if [ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  if [ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then
    source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
  fi
fi

# --- Plugins: zsh-autosuggestions (brew) ---
if [ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Java 21 (Adoptium Temurin via brew openjdk@21). Necesario para apex-jdtls
# (LSP de Apex en nvim) y sf CLI plugins que lo requieren.
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# --- Powerlevel10k (brew) ---
if [ -f "$HOMEBREW_PREFIX/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  source "$HOMEBREW_PREFIX/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
elif [ -f "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
fi

# --- zsh-syntax-highlighting (brew; must come after everything else) ---
if [ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# study-pipeline defaults for quill's on_stop hook (added 2026-08-26)
export STUDY_MATERIA="General"
# Uncomment and edit to override per session:
# export STUDY_LANG="es"
# export STUDY_PROVIDER="ollama"
