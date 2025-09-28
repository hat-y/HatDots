eval "$(starship init bash)"
eval "$(zoxide init bash)"
alias ls='eza --icons --group --git'
alias ll='eza -l --icons --group --git'
alias la='eza -la --icons --group --git'
alias vim='nvim'; alias nv='nvim .'; alias g='git'


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
