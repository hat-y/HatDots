# HatDots — Herdr Configuration

This folder ships a Herdr configuration adapted from
[`Gentleman.Dots/herdr/config.toml`](https://github.com/Gentleman-Programming/Gentleman.Dots).
Herdr is a Rust terminal multiplexer purpose-built for AI coding workflows
(PTY-based, agent-aware). HatDots uses it as the **default multiplexer** on
Linux, with Tmux as a graceful fallback when Herdr is not installed.

## Install Herdr (manual)

HatDots does **not** install Herdr automatically (the `link-linux.sh` installer
stays out of scope). Pick one:

```bash
brew install herdr                     # macOS / Linuxbrew
cargo install herdr                    # from crates.io
# or build from upstream main:
#   https://github.com/ogulcancelik/herdr
```

After installing, link the config into place:

```bash
mkdir -p ~/.config/herdr
ln -sfn ~/projects/HatDots/HatLinux/herdr/config.toml \
          ~/.config/herdr/config.toml
```

## Keybindings

`HatLinux/herdr/config.toml` defines:

| Binding | Action |
|---|---|
| `Ctrl+a` | Herdr prefix (mirrors Tmux muscle memory) |
| `prefix + Alt+k` | Previous agent |
| `prefix + Alt+j` | Next agent |
| `prefix + Ctrl+1..9` | Focus agent N |

**Why Ctrl (not Alt / Shift) for the focus digits:**
- `Alt+1..9` is owned by `skhd` / `yabai` for space switching.
- `Shift+1..9` was unreliable in the tested terminal setup.

When Herdr is absent and Tmux takes over, the equivalent keybind inside Tmux
is `Ctrl+Space N` (Tmux prefix is `Ctrl+Space`, set in `HatLinux/tmux/.tmux.conf`).

## Guard vars

Three environment variables prevent nested multiplexer sessions:

| Var | Set by | Meaning |
|---|---|---|
| `HERDR_ENV` | Herdr | An inner shell is running inside a Herdr pane |
| `TMUX` | Tmux | An inner shell is running inside a Tmux session |
| `ZELLIJ` | Zellij | An inner shell is running inside a Zellij session |

The shell guards (`HatLinux/zsh/.zshrc` and `HatLinux/fish/config.fish`) check
all three. If any is set, the shell does **not** auto-start a multiplexer.

## Known-good version

**v0.4.x** is what this config was tested against. Upstream is pre-1.0 and
shipped fast — config keys may be renamed between minor releases (e.g.
`focus_agent` → `jump_to_agent`). On a new upstream release:

1. Diff your installed Herdr version's expected config schema against this file.
2. If a key was renamed, update `config.toml` first, then this README.
3. If the change is breaking, pin to the last-known-good commit per the
   `HatLinux/README.md` migration notes.

## ⚠️ License caveat

Herdr upstream publishes source with SPDX license `NOASSERTION`. This means
upstream does not assert a license — treat Herdr as **source-available, not
open-source by default**. Evaluate before commercial or redistributed use.

## 🪟 Windows note

Herdr has **no native Windows binary**. Use WSL, or stay on the Tmux fallback
path. macOS is not currently covered by HatDots (Fedora-first).

## Related files

- `../scripts/ghostty-multiplexer-new` — POSIX sh wrapper that picks Herdr
  (or Tmux fallback) at Ghostty launch time.
- `../fish/config.fish` — Fish shell init that applies the same multiplexer
  auto-start guard.
- `../zsh/.zshrc` — Zsh shell init with the equivalent guard.
- `../ghostty/config` — Ghostty's `command =` line points at the wrapper.
- `../tmux/.tmux.conf` — `bind N` calls the wrapper for new sessions.