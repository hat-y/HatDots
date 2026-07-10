# ============================================================================
# HatDots Fish Configuration  —  HatDots/HatLinux/fish/config.fish
# ----------------------------------------------------------------------------
# ⚠️  When this file is symlinked to ~/.config/fish/config.fish, it REPLACES
# any existing config.fish. If you had a previous Fish setup, back it up FIRST:
#
#     cp ~/.config/fish/config.fish ~/.config/fish/config.fish.bak
#
# Then symlink:
#
#     ln -sfn ~/projects/HatDots/HatLinux/fish/config.fish \
#              ~/.config/fish/config.fish
#
# Source: adapted from Gentleman.Dots/GentlemanFish/fish/config.fish.
# HatDots is Fedora-first; macOS branches from the upstream source are
# intentionally NOT ported. To re-enable macOS support, uncomment the block
# marked `# --- macOS PATH (DISABLED in HatDots) ---`.
# ============================================================================

# ─── 1. Fisher bootstrap ────────────────────────────────────────────────────
# Fisher is the Fish package manager (tide, fzf, etc.). Install if missing.
if status is-interactive
    if not functions -q fisher
        curl -sL https://git.io/fisher | source
        fisher install jorgebucaran/fisher
    end
end

# ─── 2. PATH setup (Linux-only; Fedora-first) ────────────────────────────────
# Justification for NOT using `set -Ux` (universal): CARAPACE_BRIDGES, BROWSER,
# and EDITOR are session-scoped in HatDots. `set -gx` propagates to child
# processes within this Fish session but does not pollute future sessions.
# This diverges from GentlemFish by intent (DG-12).

set -gx PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.bun/bin $PATH

# --- macOS PATH (DISABLED in HatDots) ---
# if test (uname) = Darwin
#     if test -f /opt/homebrew/bin/brew
#         set BREW_BIN /opt/homebrew/bin/brew
#     else if test -f /usr/local/bin/brew
#         set BREW_BIN /usr/local/bin/brew
#     end
#     set -gx PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin \
#                   $HOME/.bun/bin $HOME/.nix-profile/bin \
#                   /nix/var/nix/profiles/default/bin /usr/local/bin \
#                   $HOME/.config $HOME/.cargo/bin /usr/local/lib/* $PATH
# end

# --- Termux PATH (DISABLED in HatDots by default) ---
# if test -n "$TERMUX_VERSION"
#     set -gx PATH $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin $PATH
# end

# ─── 3. Multiplexer auto-start (Herdr > Tmux > nothing) ────────────────────
# Mirrors the Zsh guard in HatLinux/zsh/.zshrc. Identical priority, three guard
# vars (HERDR_ENV, TMUX, ZELLIJ). See spec §5 DG-5.

if status is-interactive; and not set -q HERDR_ENV; and not set -q TMUX; and not set -q ZELLIJ
    if command -q herdr
        exec herdr
    else if command -q tmux
        tmux new-session -A -s main
    end
end

# ─── 4. Tool init (each guarded; missing binaries are skipped silently) ─────
# Each tool is wrapped in `command -q` so missing binaries do NOT error.
# This is a resilience requirement (R-5) and matches design §4.2 / spec REQ-9.
if command -q starship
    starship init fish | source
end
if command -q zoxide
    zoxide init fish | source
end
if command -q atuin
    atuin init fish | source
end
if command -q fzf
    fzf --fish | source
end

set -gx PATH $HOME/.cargo/bin $PATH

# ─── 5. Carapace completions ────────────────────────────────────────────────
# NOTE: GentlemFish uses `set -Ux CARAPACE_BRIDGES` (universal). HatDots uses
# `set -gx` (session-scoped export) per DG-12 to avoid polluting new sessions.

set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

if not test -d ~/.config/fish/completions
    mkdir -p ~/.config/fish/completions
end

if not test -f ~/.config/fish/completions/.initialized
    if not test -d ~/.config/fish/completions
        mkdir -p ~/.config/fish/completions
    end
    carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
    touch ~/.config/fish/completions/.initialized
end

carapace _carapace | source

# ─── 6. UI polish ───────────────────────────────────────────────────────────
set -g fish_greeting ""

# ─── 7. Editor ──────────────────────────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim

# ─── 8. Aliases ─────────────────────────────────────────────────────────────
alias ls='eza --icons=auto --group-directories-first --classify' \
       ll='eza -lh --git --icons=auto --group-directories-first --classify' \
       la='eza -lha --git --icons=auto --group-directories-first --classify' \
       lt='eza --tree --level=2 --icons=auto --group-directories-first'

alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfnvim='nvim (fzf --preview="bat --theme=gruvbox-dark --color=always {}")'

# ─── 9. Syntax-highlight colors (Pi-matching palette) ───────────────────────
set -l foreground F3F6F9 normal
set -l selection 263356 normal
set -l comment 8394A3 brblack
set -l red CB7C94 red
set -l orange DEBA87 orange
set -l yellow FFE066 yellow
set -l green B7CC85 green
set -l purple A3B5D6 purple
set -l cyan 7AA89F cyan
set -l pink FF8DD7 magenta

set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# ─── 10. Completion pager colors ────────────────────────────────────────────
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

clear