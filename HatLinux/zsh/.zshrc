# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Historial y rendimiento
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY
export EDITOR="nvim"

# Modo vi para la línea de comandos (h,j,k,l, w, b, etc.)
bindkey -v
export KEYTIMEOUT=1

# FZF (key bindings)
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh

# Inicialización completions
autoload -Uz compinit && compinit -u

# Plugins (Zsh plugins installed via git)
ZSH_PLUGINS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
[ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Zoxide & Atuin
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v atuin  >/dev/null && eval "$(atuin init zsh)"

# Aliases útiles
alias ls='eza --icons=auto --group-directories-first --classify'
alias ll='eza -lh --git --icons=auto --group-directories-first --classify'
alias la='eza -lha --git --icons=auto --group-directories-first --classify'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# Powerlevel10k (installed via link-linux.sh)
P10K_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k"
if [ -f "$P10K_DIR/powerlevel10k.zsh-theme" ]; then
  source "$P10K_DIR/powerlevel10k.zsh-theme"
fi
[ -f "$HOME/.p10k.zsh" ] && source "$HOME/.p10k.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$HOME/.local/bin:$PATH"
