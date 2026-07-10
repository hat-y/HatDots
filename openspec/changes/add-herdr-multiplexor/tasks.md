# SDD Tasks — add-herdr-multiplexor

**Change**: `add-herdr-multiplexor`  
**Project**: `hatdots`  
**Phase**: sdd-tasks (WHEN + WHO + IN WHAT ORDER)  
**Artifact store**: engram (primary) + openspec mirror (carve-out)  
**Status**: tasks → awaiting user approval before apply

---

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~349 (315 added + 34 deleted) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (8 commits) |
| Delivery strategy | single-pr |
| Chain strategy | pending |

```text
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low
```

---

## 1. Overview

This change adopts Herdr as the default Linux multiplexer in HatDots, with Tmux as a graceful fallback when Herdr is absent. A new POSIX shell wrapper (`HatLinux/scripts/ghostty-multiplexer-new`) sits between Ghostty and the chosen multiplexer, detecting binary presence and liveness before exec'ing the preferred option. Parallel Zsh and Fish shell guards (identical priority: Herdr > Tmux > nothing) prevent nested multiplexer sessions. Fish gains a full GentlemFish port (~110 lines). Herdr ships with a Pi-matching palette config. Both READMEs document the `NOASSERTION` license caveat, v0.4.x tested-against version, and Windows note. The legacy `ghostty-tmux-new` script is replaced via an 8-step sequencing plan with a compatibility shim window for safe migration. Total diff ~349 lines, well under the 400-line review budget. Single PR, no chained PR.

---

## 2. Task List

### TK-1 — Create wrapper script `HatLinux/scripts/ghostty-multiplexer-new`

**Files affected**:
- `HatLinux/scripts/ghostty-multiplexer-new` (+38 / -0) — NEW file

**Prerequisites**: None (first task; no dependencies)

**Implementation notes**:
- Create the `HatLinux/scripts/` directory (NEW folder; cross-multiplexer location per DG-1).
- Write the full wrapper content per design §3.1 preview. Shebang `#!/bin/sh` (DG-9), `set -eu`, optional positional session name defaulting to `main` (DG-7), liveness probe (`command -v herdr && herdr --version >/dev/null 2>&1`), Tmux fallback (`tmux new-session -A -s "$SESSION_NAME"`), last-resort drop into `$SHELL` with stderr warning, TRAP on `TERM INT HUP` (DG-10).
- Mark executable: `chmod +x HatLinux/scripts/ghostty-multiplexer-new`.

**Acceptance criteria**:
- File exists at `HatLinux/scripts/ghostty-multiplexer-new`.
- File mode is `100755` (executable).
- `sh -n HatLinux/scripts/ghostty-multiplexer-new` exits 0 (POSIX syntax valid).
- File starts with `#!/bin/sh` (not `#!/bin/bash`, not `#!/bin/zsh`).
- File contains the string `SESSION_NAME="${1:-main}"` (DG-7 arity).
- File contains `command -v herdr` and `herdr --version >/dev/null 2>&1` (liveness probe per R-6).
- File contains `trap ... TERM INT HUP` (DG-10).

**Verification commands**:
```bash
test -x HatLinux/scripts/ghostty-multiplexer-new && echo "executable: OK" || echo "executable: FAIL"
git ls-files -s HatLinux/scripts/ghostty-multiplexer-new | grep '^100755' && echo "mode: OK" || echo "mode: FAIL"
sh -n HatLinux/scripts/ghostty-multiplexer-new && echo "syntax: OK" || echo "syntax: FAIL"
head -1 HatLinux/scripts/ghostty-multiplexer-new | grep -q '^#!/bin/sh$' && echo "shebang: OK" || echo "shebang: FAIL"
grep -q 'SESSION_NAME="${1:-main}"' HatLinux/scripts/ghostty-multiplexer-new && echo "arity: OK" || echo "arity: FAIL"
grep -q 'command -v herdr' HatLinux/scripts/ghostty-multiplexer-new && echo "liveness-probe: OK" || echo "liveness-probe: FAIL"
grep -q 'trap.*TERM INT HUP' HatLinux/scripts/ghostty-multiplexer-new && echo "trap: OK" || echo "trap: FAIL"
```

**Estimate**: small (15 minutes)

---

### TK-2 — Author `HatLinux/herdr/config.toml`

**Files affected**:
- `HatLinux/herdr/config.toml` (+35 / -0) — NEW file

**Prerequisites**: TK-1 (wrapper must exist before Herdr config, since the wrapper invokes Herdr)

**Implementation notes**:
- Create `HatLinux/herdr/` directory (NEW folder, parallel to `HatLinux/tmux/`).
- Write the full Herdr config per design §3 (palette + keybindings). Pi-matching palette: `panel_bg = "#06080f"`, `accent = "#6FA0AF"`, `green = "#B7CC85"`, `blue = "#6FA0AF"`, `red = "#CB7C94"`, `yellow = "#DEBA87"` (REQ-4). Keybindings: `prefix = "ctrl+a"`, `previous_agent = "prefix+alt+k"`, `next_agent = "prefix+alt+j"`, `focus_agent = "prefix+ctrl+1..9"` (REQ-5). `theme.name = "one-dark"` base (REQ-4 rationale).
- Include attribution comment: `# Adapted from Gentleman.Dots/herdr/config.toml`.
- Include inline comment justifying `Ctrl+number` over `Alt+number` (skhd/yabai conflicts) and `Shift+number` (reachability) per REQ-5 documentation-required.

**Acceptance criteria**:
- File exists at `HatLinux/herdr/config.toml`.
- File contains `theme.name = "one-dark"`.
- File contains all six palette hex values: `#06080f`, `#6FA0AF`, `#B7CC85`, `#CB7C94`, `#DEBA87`.
- File contains `prefix = "ctrl+a"`.
- File contains `previous_agent = "prefix+alt+k"` and `next_agent = "prefix+alt+j"`.
- File contains `focus_agent = "prefix+ctrl+1..9"` (or equivalent range syntax).
- File contains attribution comment referencing Gentleman.Dots.

**Verification commands**:
```bash
test -f HatLinux/herdr/config.toml && echo "exists: OK" || echo "exists: FAIL"
grep -q 'theme.name = "one-dark"' HatLinux/herdr/config.toml && echo "theme: OK" || echo "theme: FAIL"
grep -q '#06080f' HatLinux/herdr/config.toml && grep -q '#6FA0AF' HatLinux/herdr/config.toml && echo "palette: OK" || echo "palette: FAIL"
grep -q 'prefix = "ctrl+a"' HatLinux/herdr/config.toml && echo "prefix: OK" || echo "prefix: FAIL"
grep -q 'previous_agent = "prefix+alt+k"' HatLinux/herdr/config.toml && echo "prev-agent: OK" || echo "prev-agent: FAIL"
grep -q 'next_agent = "prefix+alt+j"' HatLinux/herdr/config.toml && echo "next-agent: OK" || echo "next-agent: FAIL"
grep -qE 'focus_agent = "prefix\+ctrl\+[1-9]' HatLinux/herdr/config.toml && echo "focus-agent: OK" || echo "focus-agent: FAIL"
grep -q 'Gentleman.Dots' HatLinux/herdr/config.toml && echo "attribution: OK" || echo "attribution: FAIL"
```

**Estimate**: small (20 minutes)

---

### TK-3 — Author `HatLinux/herdr/README.md`

**Files affected**:
- `HatLinux/herdr/README.md` (+70 / -0) — NEW file

**Prerequisites**: TK-2 (Herdr config must exist before documenting it)

**Implementation notes**:
- Write the full Herdr README per design §8.2 preview. Include: installation commands (`brew install herdr` / `cargo install herdr` / upstream `main` link), first-time setup `ln -sfn` commands (DG-11), keybinding reference table, guard vars explanation, `NOASSERTION` license caveat (REQ-10, DG-8), v0.4.x version warning (REQ-10, DG-4), Windows note (REQ-10, C-3), known-good version line (R-2 mitigation), cross-link to root README ("see root README for architecture overview").
- Include p10k gitstatus escape hatches (`POWERLEVEL9K_VCS_DISABLED=true` and `POWERLEVEL9K_DISABLE_GITSTATUS=true`) per R-1 / REQ-13.

**Acceptance criteria**:
- File exists at `HatLinux/herdr/README.md`.
- File contains the string `NOASSERTION`.
- File contains the string `v0.4.x`.
- File contains a Windows note (e.g., "Herdr has no native Windows binary" or "Use WSL").
- File contains installation commands (`brew install herdr` or `cargo install herdr`).
- File contains a keybinding reference table (or list) with prefix, previous_agent, next_agent, focus_agent.
- File contains a cross-link to the root README (e.g., "see root README").
- File contains p10k gitstatus escape hatches (`POWERLEVEL9K_VCS_DISABLED` or `POWERLEVEL9K_DISABLE_GITSTATUS`).

**Verification commands**:
```bash
test -f HatLinux/herdr/README.md && echo "exists: OK" || echo "exists: FAIL"
grep -q 'NOASSERTION' HatLinux/herdr/README.md && echo "license-caveat: OK" || echo "license-caveat: FAIL"
grep -q 'v0.4.x' HatLinux/herdr/README.md && echo "version-warning: OK" || echo "version-warning: FAIL"
grep -qi 'windows\|wsl' HatLinux/herdr/README.md && echo "windows-note: OK" || echo "windows-note: FAIL"
grep -q 'brew install herdr\|cargo install herdr' HatLinux/herdr/README.md && echo "install-commands: OK" || echo "install-commands: FAIL"
grep -q 'prefix.*ctrl+a\|Ctrl+a' HatLinux/herdr/README.md && echo "keybindings: OK" || echo "keybindings: FAIL"
grep -qi 'root README\|see root' HatLinux/herdr/README.md && echo "cross-link: OK" || echo "cross-link: FAIL"
grep -q 'POWERLEVEL9K_VCS_DISABLED\|POWERLEVEL9K_DISABLE_GITSTATUS' HatLinux/herdr/README.md && echo "p10k-escape-hatch: OK" || echo "p10k-escape-hatch: FAIL"
```

**Estimate**: small (25 minutes)

---

### TK-4 — Author `HatLinux/fish/config.fish`

**Files affected**:
- `HatLinux/fish/config.fish` (+110 / -0) — NEW file

**Prerequisites**: TK-1 (wrapper must exist before Fish guard references it)

**Implementation notes**:
- Create `HatLinux/fish/` directory (NEW folder, parallel to `HatLinux/zsh/`).
- Write the full Fish config per design §4.1 preview. 10 init blocks in order: (1) Fisher bootstrap, (2) PATH setup (Linux-only, `set -gx`), (3) multiplexer auto-start guard (Herdr > Tmux > nothing, three guard vars `HERDR_ENV`/`TMUX`/`ZELLIJ` per DG-5), (4) tool init (starship/zoxide/atuin/fzf), (5) Carapace completions (`set -gx CARAPACE_BRIDGES` per DG-12), (6) UI polish (`fish_greeting ""`), (7) editor (`EDITOR=nvim`), (8) aliases (eza/fzfbat/fzfnvim), (9) syntax-highlight colors (Pi-matching palette), (10) pager colors.
- Include migration header per DG-6 (warning block about symlink override, backup command, source attribution).
- Include commented-out macOS/Termux PATH blocks (C-7: Fedora-first; easy to restore).
- Include ATTRIBUTION comment for DG-12 divergence (`set -gx` vs GentlemFish's `set -Ux`).

**Acceptance criteria**:
- File exists at `HatLinux/fish/config.fish`.
- File starts with a migration header comment block (DG-6) containing the string "REPLACES" or "back it up".
- File contains `fisher install jorgebucaran/fisher` (Fisher bootstrap).
- File contains `set -gx PATH` (PATH setup, session-scoped per DG-12).
- File contains the multiplexer guard: `if status is-interactive; and not set -q HERDR_ENV; and not set -q TMUX; and not set -q ZELLIJ` (DG-5 exact string).
- File contains `exec herdr` and `tmux new-session -A -s main` inside the guard.
- File contains `starship init fish | source`, `zoxide init fish | source`, `atuin init fish | source`, `fzf --fish | source`.
- File contains `set -gx CARAPACE_BRIDGES` (DG-12, session-scoped).
- File contains `set -g fish_greeting ""`.
- File contains `set -gx EDITOR nvim` and `set -gx VISUAL nvim`.
- File contains eza aliases (`alias ls='eza` or similar).
- File contains Pi-matching syntax colors (`set -g fish_color_command` or similar).
- File contains commented-out macOS PATH block (`# --- macOS PATH (DISABLED in HatDots) ---` or similar).

**Verification commands**:
```bash
test -f HatLinux/fish/config.fish && echo "exists: OK" || echo "exists: FAIL"
head -20 HatLinux/fish/config.fish | grep -q 'REPLACES\|back it up' && echo "migration-header: OK" || echo "migration-header: FAIL"
grep -q 'fisher install jorgebucaran/fisher' HatLinux/fish/config.fish && echo "fisher: OK" || echo "fisher: FAIL"
grep -q 'set -gx PATH' HatLinux/fish/config.fish && echo "path-setup: OK" || echo "path-setup: FAIL"
grep -q 'status is-interactive; and not set -q HERDR_ENV; and not set -q TMUX; and not set -q ZELLIJ' HatLinux/fish/config.fish && echo "guard: OK" || echo "guard: FAIL"
grep -q 'exec herdr' HatLinux/fish/config.fish && grep -q 'tmux new-session -A -s main' HatLinux/fish/config.fish && echo "multiplexer-priority: OK" || echo "multiplexer-priority: FAIL"
grep -q 'starship init fish | source' HatLinux/fish/config.fish && echo "starship: OK" || echo "starship: FAIL"
grep -q 'set -gx CARAPACE_BRIDGES' HatLinux/fish/config.fish && echo "carapace: OK" || echo "carapace: FAIL"
grep -q 'set -g fish_greeting ""' HatLinux/fish/config.fish && echo "greeting: OK" || echo "greeting: FAIL"
grep -q 'set -gx EDITOR nvim' HatLinux/fish/config.fish && echo "editor: OK" || echo "editor: FAIL"
grep -q "alias ls='eza" HatLinux/fish/config.fish && echo "eza-aliases: OK" || echo "eza-aliases: FAIL"
grep -q 'set -g fish_color_command' HatLinux/fish/config.fish && echo "syntax-colors: OK" || echo "syntax-colors: FAIL"
grep -q 'macOS PATH (DISABLED' HatLinux/fish/config.fish && echo "macos-disabled: OK" || echo "macos-disabled: FAIL"
```

**Estimate**: medium (40 minutes)

---

### TK-5 — Edit `HatLinux/ghostty/config` — replace `command =` line

**Files affected**:
- `HatLinux/ghostty/config` (+1 / -1) — MODIFIED

**Prerequisites**: TK-1 (wrapper must exist before Ghostty references it)

**Implementation notes**:
- Replace the literal line `command = /usr/bin/tmux -f ~/.tmux.conf new-session -A -s main` with `command = ~/.local/bin/ghostty-multiplexer-new main` per REQ-6 + design §6.
- REQ-6 invariant: "the Ghostty config SHALL NOT contain the string `tmux` in the `command =` directive." The new line satisfies this.
- Note DG-11: this is an in-repo edit; the live `~/.config/ghostty/config` is generated by `link-linux.sh` heredoc on first install, so the README must include a manual `ln -sfn` migration step (already documented in TK-3 and TK-8).

**Acceptance criteria**:
- File `HatLinux/ghostty/config` exists.
- The `command =` line is exactly: `command = ~/.local/bin/ghostty-multiplexer-new main`.
- `grep '^command' HatLinux/ghostty/config` does NOT contain the string `tmux` (REQ-6).
- The old line `/usr/bin/tmux -f ~/.tmux.conf` is gone.

**Verification commands**:
```bash
grep '^command = ' HatLinux/ghostty/config | grep -q 'ghostty-multiplexer-new main' && echo "command-line: OK" || echo "command-line: FAIL"
! grep '^command = ' HatLinux/ghostty/config | grep -q 'tmux' && echo "no-tmux: OK" || echo "no-tmux: FAIL"
! grep -q '/usr/bin/tmux -f ~/.tmux.conf' HatLinux/ghostty/config && echo "old-line-gone: OK" || echo "old-line-gone: FAIL"
```

**Estimate**: small (5 minutes)

---

### TK-6 — Edit `HatLinux/tmux/.tmux.conf` — replace `bind N` line

**Files affected**:
- `HatLinux/tmux/.tmux.conf` (+1 / -1) — MODIFIED

**Prerequisites**: TK-10 (compatibility shim must exist before `.tmux.conf` references the wrapper, per DG-3 step 3 sequencing)

**Implementation notes**:
- Replace the literal line `bind N command-prompt -p "Nombre de sesión:" "run-shell '~/.local/bin/ghostty-tmux-new %%'"` with `bind N command-prompt -p "Nombre de sesión:" "run-shell '~/.local/bin/ghostty-multiplexer-new %%'"` per REQ-12 + design §7.
- Preserve the prompt copy ("Nombre de sesión:") and `command-prompt` semantics.
- Per DG-3 step 3: this edit happens AFTER the compatibility shim (TK-10) is in place, so stale symlinks still work via shim → wrapper.

**Acceptance criteria**:
- File `HatLinux/tmux/.tmux.conf` exists.
- The `bind N` line is exactly: `bind N command-prompt -p "Nombre de sesión:" "run-shell '~/.local/bin/ghostty-multiplexer-new %%'"`.
- The old line referencing `ghostty-tmux-new` is gone.
- The prompt string "Nombre de sesión:" is preserved.

**Verification commands**:
```bash
grep '^bind N ' HatLinux/tmux/.tmux.conf | grep -q 'ghostty-multiplexer-new' && echo "bind-N: OK" || echo "bind-N: FAIL"
! grep '^bind N ' HatLinux/tmux/.tmux.conf | grep -q 'ghostty-tmux-new' && echo "old-bind-gone: OK" || echo "old-bind-gone: FAIL"
grep '^bind N ' HatLinux/tmux/.tmux.conf | grep -q 'Nombre de sesión:' && echo "prompt-preserved: OK" || echo "prompt-preserved: FAIL"
```

**Estimate**: small (5 minutes)

---

### TK-7 — Edit `HatLinux/zsh/.zshrc` — insert guard block after p10k sourcing

**Files affected**:
- `HatLinux/zsh/.zshrc` (+15 / -0) — MODIFIED

**Prerequisites**: TK-1 (wrapper must exist before Zsh guard references it)

**Implementation notes**:
- Insert the guard block per design §5.2 exact preview. Placement: AFTER all p10k sourcing (after the line `[ -f "$HOME/.p10k.zsh" ] && source "$HOME/.p10k.zsh"`) and BEFORE any user `exec` (REQ-8 placement rationale: p10k must be ready if guard falls through).
- Exact block (DG-5):
  ```zsh
  # --- Multiplexer auto-start: Herdr > Tmux > nothing ---
  # Guard vars HERDR_ENV, TMUX, ZELLIJ must all be unset.
  # See openspec/changes/add-herdr-multiplexor/spec.md DG-5 for parity with Fish.
  if [[ -o interactive ]] && [[ -z "$HERDR_ENV" && -z "$TMUX" && -z "$ZELLIJ" ]]; then
      if command -v herdr >/dev/null 2>&1 && herdr --version >/dev/null 2>&1; then
          exec herdr
      elif command -v tmux >/dev/null 2>&1; then
          tmux new-session -A -s main
      fi
  fi
  ```
- REQ-8 invariant: guard parity with Fish (TK-4). Both encode identical priority: Herdr > Tmux > nothing, three guard vars, interactive-only.
- R-1 mitigation: if p10k gitstatus breaks under Herdr PTY, the escape hatches are already in the existing `.zshrc` as commented lines (`# typeset -g POWERLEVEL9K_VCS_DISABLED=true`). The README documents both flags.

**Acceptance criteria**:
- File `HatLinux/zsh/.zshrc` exists.
- Guard block is present after p10k sourcing.
- Guard block contains `[[ -o interactive ]] && [[ -z "$HERDR_ENV" && -z "$TMUX" && -z "$ZELLIJ" ]]` (DG-5 exact string).
- Guard block contains `exec herdr` and `tmux new-session -A -s main`.
- Guard block contains `herdr --version >/dev/null 2>&1` (liveness probe per R-6).
- Existing p10k sourcing block is unchanged (`[ -f "$HOME/.p10k.zsh" ] && source "$HOME/.p10k.zsh"` still present).
- Existing tooling (fzf, zoxide, atuin, eza, completions, bun) is unchanged.

**Verification commands**:
```bash
grep -q '\[\[ -o interactive \]\] && \[\[ -z "$HERDR_ENV" && -z "$TMUX" && -z "$ZELLIJ" \]\]' HatLinux/zsh/.zshrc && echo "guard: OK" || echo "guard: FAIL"
grep -q 'exec herdr' HatLinux/zsh/.zshrc && grep -q 'tmux new-session -A -s main' HatLinux/zsh/.zshrc && echo "multiplexer-priority: OK" || echo "multiplexer-priority: FAIL"
grep -q 'herdr --version >/dev/null 2>&1' HatLinux/zsh/.zshrc && echo "liveness-probe: OK" || echo "liveness-probe: FAIL"
grep -q '\[ -f "$HOME/.p10k.zsh" \] && source "$HOME/.p10k.zsh"' HatLinux/zsh/.zshrc && echo "p10k-unchanged: OK" || echo "p10k-unchanged: FAIL"
grep -q 'zoxide init zsh' HatLinux/zsh/.zshrc && echo "existing-tooling: OK" || echo "existing-tooling: FAIL"
```

**Estimate**: small (15 minutes)

---

### TK-8 — Update `HatLinux/README.md` — add Herdr section

**Files affected**:
- `HatLinux/README.md` (+30 / -0) — MODIFIED

**Prerequisites**: TK-3 (Herdr README must exist before cross-linking to it)

**Implementation notes**:
- Insert the Herdr section per design §8.2 exact preview. Placement: after the existing `### Ghostty + Tmux` section, before `### KDE/KWin` and `### Zsh` sections.
- Include: installation commands, first-time setup `ln -sfn` commands (DG-11), keybinding reference table, guard vars explanation, `NOASSERTION` license caveat (REQ-10, DG-8), v0.4.x version warning (REQ-10, DG-4), Windows note (REQ-10, C-3), cross-link to root README ("see root README for architecture overview").
- Preserve all existing sections (KDE/KWin, Zsh, Ghostty+Tmux).

**Acceptance criteria**:
- File `HatLinux/README.md` exists.
- Herdr section is present (e.g., `### Herdr (default multiplexer)` or similar heading).
- Section contains `NOASSERTION`.
- Section contains `v0.4.x`.
- Section contains Windows note.
- Section contains installation commands.
- Section contains `ln -sfn` migration steps for wrapper, Herdr config, Ghostty config, Fish config.
- Section contains `rm -f ~/.local/bin/ghostty-tmux-new` migration step (R-3 cleanup).
- Section contains cross-link to root README.
- Existing sections (KDE/KWin, Zsh, Ghostty+Tmux) are unchanged.

**Verification commands**:
```bash
grep -q '### Herdr' HatLinux/README.md && echo "herdr-section: OK" || echo "herdr-section: FAIL"
grep -q 'NOASSERTION' HatLinux/README.md && echo "license-caveat: OK" || echo "license-caveat: FAIL"
grep -q 'v0.4.x' HatLinux/README.md && echo "version-warning: OK" || echo "version-warning: FAIL"
grep -qi 'windows\|wsl' HatLinux/README.md && echo "windows-note: OK" || echo "windows-note: FAIL"
grep -q 'ln -sfn.*ghostty-multiplexer-new' HatLinux/README.md && echo "migration-wrapper: OK" || echo "migration-wrapper: FAIL"
grep -q 'rm -f ~/.local/bin/ghostty-tmux-new' HatLinux/README.md && echo "migration-cleanup: OK" || echo "migration-cleanup: FAIL"
grep -qi 'root README' HatLinux/README.md && echo "cross-link: OK" || echo "cross-link: FAIL"
grep -q '### KDE/KWin' HatLinux/README.md && echo "existing-kde: OK" || echo "existing-kde: FAIL"
```

**Estimate**: small (20 minutes)

---

### TK-9 — Update root `README.md` — add multiplexor overview

**Files affected**:
- `README.md` (+15 / -0) — MODIFIED

**Prerequisites**: TK-8 (HatLinux README must exist before cross-linking to it)

**Implementation notes**:
- Insert the multiplexor overview per design §9.2 exact preview. Placement: after the existing "Componentes" section, as a new subsection `### Multiplexor (Herdr default / Tmux fallback)`.
- Include: architecture overview (wrapper prefers Herdr, falls back to Tmux), Fish shell mention, keybinding note, `NOASSERTION` license caveat (REQ-10, DG-8), v0.4.x version warning (REQ-10, DG-4), Windows note (REQ-10, C-3), cross-link to `HatLinux/herdr/README.md` ("see HatLinux/herdr/README.md for version-specific notes").
- The root README is the canonical source of truth for the multiplexor overview (DG-8 rationale).

**Acceptance criteria**:
- File `README.md` (root) exists.
- Multiplexor overview section is present (e.g., `### Multiplexor (Herdr default / Tmux fallback)` or similar heading).
- Section contains `NOASSERTION`.
- Section contains `v0.4.x`.
- Section contains Windows note.
- Section mentions the wrapper path (`HatLinux/scripts/ghostty-multiplexer-new`).
- Section mentions Fish shell (`HatLinux/fish/config.fish`).
- Section contains cross-link to `HatLinux/herdr/README.md`.

**Verification commands**:
```bash
grep -q '### Multiplexor\|### Multiplexer' README.md && echo "multiplexor-section: OK" || echo "multiplexor-section: FAIL"
grep -q 'NOASSERTION' README.md && echo "license-caveat: OK" || echo "license-caveat: FAIL"
grep -q 'v0.4.x' README.md && echo "version-warning: OK" || echo "version-warning: FAIL"
grep -qi 'windows\|wsl' README.md && echo "windows-note: OK" || echo "windows-note: FAIL"
grep -q 'HatLinux/scripts/ghostty-multiplexer-new' README.md && echo "wrapper-path: OK" || echo "wrapper-path: FAIL"
grep -q 'HatLinux/fish/config.fish' README.md && echo "fish-path: OK" || echo "fish-path: FAIL"
grep -q 'HatLinux/herdr/README.md' README.md && echo "cross-link: OK" || echo "cross-link: FAIL"
```

**Estimate**: small (15 minutes)

---

### TK-10 — Compatibility shim at `HatLinux/tmux/scripts/ghostty-tmux-new`

**Files affected**:
- `HatLinux/tmux/scripts/ghostty-tmux-new` (+2 / -32) — MODIFIED (content replaced with one-line delegation)

**Prerequisites**: TK-1 (canonical wrapper must exist before shim delegates to it)

**Implementation notes**:
- Replace the content of `HatLinux/tmux/scripts/ghostty-tmux-new` with a one-line compatibility shim per design §10 step 2:
  ```sh
  #!/bin/sh
  exec ~/.local/bin/ghostty-multiplexer-new "$@"
  ```
- Keep the file name (`ghostty-tmux-new`) and file mode (`chmod +x`). The file REMAINS at this path during steps 2–7 of the DG-3 sequencing plan; it is only `git rm`'d at step 8 (TK-13).
- Rationale: users who already have `~/.local/bin/ghostty-tmux-new` symlinked can continue using the old path; the shim transparently delegates to the new wrapper. This keeps the migration window safe (DG-3 step 2).

**Acceptance criteria**:
- File `HatLinux/tmux/scripts/ghostty-tmux-new` still exists (not deleted yet).
- File content is exactly:
  ```sh
  #!/bin/sh
  exec ~/.local/bin/ghostty-multiplexer-new "$@"
  ```
- File mode is `100755` (executable).
- File starts with `#!/bin/sh`.
- File contains `exec ~/.local/bin/ghostty-multiplexer-new "$@"`.

**Verification commands**:
```bash
test -f HatLinux/tmux/scripts/ghostty-tmux-new && echo "exists: OK" || echo "exists: FAIL"
test -x HatLinux/tmux/scripts/ghostty-tmux-new && echo "executable: OK" || echo "executable: FAIL"
head -1 HatLinux/tmux/scripts/ghostty-tmux-new | grep -q '^#!/bin/sh$' && echo "shebang: OK" || echo "shebang: FAIL"
grep -q 'exec ~/.local/bin/ghostty-multiplexer-new "$@"' HatLinux/tmux/scripts/ghostty-tmux-new && echo "delegation: OK" || echo "delegation: FAIL"
wc -l < HatLinux/tmux/scripts/ghostty-tmux-new | grep -q '^2$' && echo "line-count: OK" || echo "line-count: FAIL"
```

**Estimate**: small (5 minutes)

---

### TK-11 — Manual verification per spec SCN-1..SCN-9

**Files affected**: None (verification only; no file changes)

**Prerequisites**: TK-5, TK-6, TK-7, TK-8, TK-9, TK-10 (all file edits must be complete before verification)

**Implementation notes**:
- Execute the manual verification procedures from design §12.3 (verbatim from spec §11). For each SCN, document the expected outcome and whether it passed.
- SCN-1: `which herdr && herdr --version` → `unset HERDR_ENV TMUX ZELLIJ; ghostty` → expect Herdr chrome.
- SCN-2: Temporarily `mv $(which herdr) $(which herdr).bak`; reload ghostty → expect Tmux fallback.
- SCN-3: From inside tmux, open new Ghostty → expect plain shell (no nested start).
- SCN-4: From inside Herdr pane, run `zsh -i` then `fish -i` → expect plain shell.
- SCN-5: Inside Herdr, press `Ctrl+a N` → expect new session prompt.
- SCN-6: Inside Tmux fallback, press `prefix N` → expect new session.
- SCN-7: `fish -i` from TTY → expect starship + vi-mode + GentlemFish colors.
- SCN-8: `zsh -i` from TTY → expect p10k + multiplexer guard fires.
- SCN-9: Temporarily rename `herdr` binary → expect wrapper falls back to Tmux.
- REQ-13: Inside Herdr → Zsh, navigate to a git repo → expect p10k git branch renders (or escape hatches documented in README).

**Acceptance criteria**:
- All 9 SCN procedures (SCN-1..SCN-9) pass.
- REQ-13 verification passes (p10k gitstatus works under Herdr PTY, OR escape hatches are documented in README).
- Verification log documents each SCN with pass/fail status and any notes.

**Verification commands**:
```bash
# SCN-1: Herdr launch
which herdr && herdr --version && echo "SCN-1 prerequisite: OK"
# (Manual: open Ghostty, expect Herdr chrome)

# SCN-2: Tmux fallback
mv $(which herdr) $(which herdr).bak 2>/dev/null && echo "SCN-2 setup: herdr hidden"
# (Manual: open Ghostty, expect Tmux chrome)
mv $(which herdr).bak $(which herdr) 2>/dev/null && echo "SCN-2 teardown: herdr restored"

# SCN-3: Nested tmux prevention
# (Manual: from inside tmux, open Ghostty, expect plain shell)
echo "TMUX=$TMUX HERDR_ENV=$HERDR_ENV ZELLIJ=$ZELLIJ"

# SCN-4: Nested Herdr prevention
# (Manual: from inside Herdr, run `zsh -i` and `fish -i`, expect plain shell)

# SCN-5/SCN-6: Keybinding verification
# (Manual: inside Herdr/Tmux, press prefix+N, type session name, expect new session)

# SCN-7: Fish from TTY
# (Manual: `fish -i` from TTY, expect starship + vi-mode + colors)

# SCN-8: Zsh from TTY
# (Manual: `zsh -i` from TTY, expect p10k + guard fires)

# SCN-9: Version handling
# (Manual: rename herdr binary, run wrapper, expect Tmux fallback)

# REQ-13: p10k gitstatus under Herdr PTY
# (Manual: inside Herdr → Zsh, navigate to git repo, expect branch in prompt)
```

**Estimate**: medium (60 minutes — includes setup, manual testing, documentation)

---

### TK-12 — Apply review lens (review-resilience)

**Files affected**: None (review only; no file changes)

**Prerequisites**: TK-11 (all verification must pass before review)

**Implementation notes**:
- Apply the `review-resilience` lens (shell/process integration, partial failures, recovery, degraded dependencies). This is the best-fit lens for this change because:
  - The wrapper invokes external binaries (`herdr`, `tmux`) and must handle their absence/failure gracefully.
  - The shell guards must handle missing binaries, nested sessions, and PTY handoffs.
  - The migration path (compatibility shim, README `ln -sfn` steps) must handle stale symlinks and partial migration states.
- Review focus areas:
  - Wrapper signal handling (DG-10): does the TRAP on `TERM INT HUP` correctly clean up if exec fails?
  - Liveness probe robustness (R-6): does `command -v herdr && herdr --version` correctly skip dead shims?
  - Guard var parity (DG-5): do Zsh and Fish guards encode identical priority?
  - Migration safety (DG-3): is the compatibility shim window safe? Can a user abort mid-migration?
  - p10k gitstatus (R-1): are the escape hatches documented and testable?

**Acceptance criteria**:
- Review log documents findings per category: signal handling, liveness probe, guard parity, migration safety, p10k escape hatches.
- Review log flags any blockers or recommendations.
- No unresolved blockers (all findings are either acceptable or have a mitigation plan).

**Verification commands**:
```bash
# Review is a manual process; no automated verification.
# Reviewer inspects:
# - HatLinux/scripts/ghostty-multiplexer-new (signal handling, liveness probe)
# - HatLinux/zsh/.zshrc guard block (parity with Fish)
# - HatLinux/fish/config.fish guard block (parity with Zsh)
# - HatLinux/tmux/scripts/ghostty-tmux-new (compatibility shim)
# - HatLinux/README.md (migration steps, escape hatches)
```

**Estimate**: small (30 minutes)

---

### TK-13 — Cleanup: `git rm HatLinux/tmux/scripts/ghostty-tmux-new`

**Files affected**:
- `HatLinux/tmux/scripts/ghostty-tmux-new` (+0 / -2) — DELETED

**Prerequisites**: TK-11, TK-12 (all verification and review must pass before deletion)

**Implementation notes**:
- After all verifications (TK-11) and review (TK-12) pass, delete the compatibility shim and the legacy script:
  ```bash
  git rm HatLinux/tmux/scripts/ghostty-tmux-new
  ```
- This is DG-3 step 8 (the final step in the 8-step sequencing plan).
- README already instructs users to `rm -f ~/.local/bin/ghostty-tmux-new` (TK-8 / TK-3).
- After deletion, no references to `ghostty-tmux-new` should remain in repo source (except in README migration step instructions).

**Acceptance criteria**:
- File `HatLinux/tmux/scripts/ghostty-tmux-new` no longer exists in the repo.
- `git status` shows the file as deleted.
- `grep -r 'ghostty-tmux-new' HatLinux/` returns zero hits (except in README migration instructions).
- `ls HatLinux/tmux/scripts/` shows the directory is empty or contains only other scripts (not `ghostty-tmux-new`).
- `ls HatLinux/scripts/` shows only `ghostty-multiplexer-new`.

**Verification commands**:
```bash
! test -f HatLinux/tmux/scripts/ghostty-tmux-new && echo "deleted: OK" || echo "deleted: FAIL"
git status | grep -q 'deleted:.*ghostty-tmux-new' && echo "git-status: OK" || echo "git-status: FAIL"
! grep -r 'ghostty-tmux-new' HatLinux/ | grep -v 'README.md' && echo "no-references: OK" || echo "no-references: FAIL"
ls HatLinux/scripts/ | grep -q 'ghostty-multiplexer-new' && echo "new-wrapper: OK" || echo "new-wrapper: FAIL"
```

**Estimate**: small (5 minutes)

---

## 3. Task Ordering / Dependency Graph

```text
TK-1 (wrapper)
  ├─→ TK-2 (herdr config)
  │     └─→ TK-3 (herdr README)
  │           └─→ TK-8 (HatLinux README)
  │                 └─→ TK-9 (root README)
  ├─→ TK-4 (fish config)
  ├─→ TK-5 (ghostty config)
  ├─→ TK-7 (zsh guard)
  └─→ TK-10 (compatibility shim)
        └─→ TK-6 (tmux.conf bind N)

TK-5, TK-6, TK-7, TK-8, TK-9, TK-10 ─→ TK-11 (manual verification)
TK-11 ─→ TK-12 (review lens)
TK-11, TK-12 ─→ TK-13 (cleanup: git rm)
```

**Explicit dependencies**:
- TK-2 blockedBy: TK-1
- TK-3 blockedBy: TK-2
- TK-4 blockedBy: TK-1
- TK-5 blockedBy: TK-1
- TK-6 blockedBy: TK-10
- TK-7 blockedBy: TK-1
- TK-8 blockedBy: TK-3
- TK-9 blockedBy: TK-8
- TK-10 blockedBy: TK-1
- TK-11 blockedBy: TK-5, TK-6, TK-7, TK-8, TK-9, TK-10
- TK-12 blockedBy: TK-11
- TK-13 blockedBy: TK-11, TK-12

**Parallelizable tasks**:
- TK-2, TK-4, TK-5, TK-7, TK-10 can all run in parallel after TK-1 completes.
- TK-3 and TK-8 are sequential (TK-3 → TK-8 → TK-9).

---

## 4. Sequencing Implementation (mapping design §10 steps to tasks)

Design §10 defines an 8-step sequencing plan (DG-3 expanded). Each step is independently verifiable. The plan ensures that at no point are both `bind N` and `command =` simultaneously broken, and the wrapper is never invoked before it exists.

| Design §10 Step | Task(s) | Action | Verification |
|-----------------|---------|--------|--------------|
| **Step 1**: Create wrapper | TK-1 | Create `HatLinux/scripts/ghostty-multiplexer-new`, `chmod +x` | `git ls-files -s` shows mode `100755`; `sh -n` succeeds |
| **Step 2**: Compatibility shim | TK-10 | Replace `HatLinux/tmux/scripts/ghostty-tmux-new` content with one-line `exec` delegation | Old symlinks still work; `~/.local/bin/ghostty-tmux-new foo` runs the wrapper |
| **Step 3**: Edit `.tmux.conf` `bind N` | TK-6 | Replace `bind N` to call wrapper directly | Inside tmux: `tmux source-file ~/.tmux.conf`, then `prefix N`, type a name → new session |
| **Step 4**: Edit Ghostty `command =` | TK-5 | Replace `command =` to wrapper | Restart Ghostty → expect Herdr chrome (with herdr) or Tmux chrome (without) |
| **Step 5**: Manual verify SCN-1/SCN-2/SCN-3 | TK-11 | Open Ghostty, test Herdr/Tmux fallback, test nesting | All three SCN procedures pass |
| **Step 6**: Edit `.zshrc` guard block | TK-7 | Insert guard after p10k sourcing | `unset HERDR_ENV TMUX ZELLIJ; zsh -i` from TTY → guard fires |
| **Step 7**: Author herdr config/README, fish config, update READMEs | TK-2, TK-3, TK-4, TK-8, TK-9 | Create new files, update docs | `cat` each file; verify content; `fish -i` from TTY → guard + GentlemFish init |
| **Step 8**: Remove compatibility shim | TK-13 | `git rm HatLinux/tmux/scripts/ghostty-tmux-new` | `ls HatLinux/tmux/scripts/` shows shim is gone |

**Sequencing rationale**:
- Steps 1–2 (TK-1, TK-10) establish the wrapper and the safety net (shim).
- Steps 3–4 (TK-6, TK-5) update the callers (`.tmux.conf` and Ghostty config) to use the wrapper directly.
- Step 5 (TK-11) verifies the three most-common scenarios (Herdr launch, Tmux fallback, nesting prevention).
- Step 6 (TK-7) adds the Zsh guard (after verifying the wrapper works).
- Step 7 (TK-2, TK-3, TK-4, TK-8, TK-9) adds the remaining new files and documentation.
- Step 8 (TK-13) cleans up the shim after all verifications pass.

**TK-12 (review lens)** is applied after TK-11 (verification) but before TK-13 (cleanup), so the reviewer can inspect the compatibility shim in place.

---

## 5. Commit Boundaries

Recommended commit-per-task (8 commits within the single PR). Each commit is independently revertable and bisectable.

| Commit | Task(s) | Commit message |
|--------|---------|----------------|
| **1** | TK-1 | `feat: add ghostty-multiplexer-new wrapper (POSIX sh)` |
| **2** | TK-10 | `refactor: replace ghostty-tmux-new with compatibility shim` |
| **3** | TK-6 | `feat: update .tmux.conf bind N to use new wrapper` |
| **4** | TK-5 | `feat: update ghostty config to use new wrapper` |
| **5** | TK-7 | `feat: add multiplexer auto-start guard to .zshrc` |
| **6** | TK-2, TK-3, TK-4 | `feat: add herdr config/README + fish config.fish` |
| **7** | TK-8, TK-9 | `docs: add Herdr section to HatLinux README + multiplexor overview to root README` |
| **8** | TK-13 | `refactor: remove legacy ghostty-tmux-new script` |

**Commit 2 (shim) and Commit 8 (removal) are intentionally separate** so a reviewer can bisect regressions against either step (design §14 reviewer note).

---

## 6. Review Workload Forecast (per task)

| Task | Files | Lines added | Lines deleted | Total changed |
|------|-------|-------------|---------------|---------------|
| TK-1 | `HatLinux/scripts/ghostty-multiplexer-new` | 38 | 0 | 38 |
| TK-2 | `HatLinux/herdr/config.toml` | 35 | 0 | 35 |
| TK-3 | `HatLinux/herdr/README.md` | 70 | 0 | 70 |
| TK-4 | `HatLinux/fish/config.fish` | 110 | 0 | 110 |
| TK-5 | `HatLinux/ghostty/config` | 1 | 1 | 2 |
| TK-6 | `HatLinux/tmux/.tmux.conf` | 1 | 1 | 2 |
| TK-7 | `HatLinux/zsh/.zshrc` | 15 | 0 | 15 |
| TK-8 | `HatLinux/README.md` | 30 | 0 | 30 |
| TK-9 | `README.md` | 15 | 0 | 15 |
| TK-10 | `HatLinux/tmux/scripts/ghostty-tmux-new` | 2 | 32 | 34 |
| TK-11 | (verification only) | 0 | 0 | 0 |
| TK-12 | (review only) | 0 | 0 | 0 |
| TK-13 | `HatLinux/tmux/scripts/ghostty-tmux-new` | 0 | 2 | 2 |
| **TOTAL** | — | **317** | **36** | **353** |

**Review budget analysis**:
- Total changed lines: ~353 (317 added + 36 deleted).
- Review budget: 400 lines.
- **Risk: Low** (353 < 400).
- **Chained PRs recommended: No** (single PR is sufficient).

**Largest contributors**:
- TK-4 (Fish config): 110 lines — unavoidable (full GentlemFish port per REQ-9).
- TK-3 (Herdr README): 70 lines — unavoidable (REQ-10 documentation).
- TK-10 (shim): 34 lines — transitional (2 added, 32 deleted); net -30 lines.

**Mitigation**: No `link-linux.sh` changes (C-2) saves ~30 lines. No macOS/Termux branches in Fish (C-7) saves ~20 lines. No Nushell / no Windows / no p10k schema changes keep scope tight.

---

## 7. Verification Matrix (TK → REQ/SCN)

| Task | Spec items covered | Verification method |
|------|-------------------|---------------------|
| TK-1 | REQ-7, SCN-1, SCN-2 | `sh -n` syntax check; file exists + executable; content matches design §3.1 |
| TK-2 | REQ-4, REQ-5 | `cat` config; grep for palette hex values, keybinding strings, attribution comment |
| TK-3 | REQ-10, REQ-13, R-1, R-2 | `cat` README; grep for `NOASSERTION`, `v0.4.x`, Windows note, escape hatches, cross-link |
| TK-4 | REQ-3, REQ-9, SCN-7 | `cat` config; grep for migration header, guard block, tool init, syntax colors |
| TK-5 | REQ-6, SCN-1, SCN-2 | `grep '^command'`; verify no `tmux` in line; verify new line matches design §6 |
| TK-6 | REQ-12, SCN-6 | `grep '^bind N'`; verify new line matches design §7; verify prompt preserved |
| TK-7 | REQ-3, REQ-8, SCN-3, SCN-4, SCN-8 | `grep` guard block; verify DG-5 exact strings; verify p10k unchanged |
| TK-8 | REQ-10, REQ-11, R-3 | `grep` Herdr section; verify `NOASSERTION`, `v0.4.x`, Windows note, migration steps |
| TK-9 | REQ-10 | `grep` multiplexor overview; verify `NOASSERTION`, `v0.4.x`, Windows note, cross-link |
| TK-10 | REQ-11, R-3 | `cat` shim; verify content is 2-line delegation; verify executable |
| TK-11 | REQ-1..REQ-13, SCN-1..SCN-9 | Manual verification per design §12.3; document pass/fail per SCN |
| TK-12 | R-1, R-3, R-6, DG-3, DG-5, DG-10 | Review lens (resilience); document findings |
| TK-13 | REQ-11, R-3 | `git status` shows deleted; `grep` shows no references (except README migration) |

---

## 8. Pre-Apply Checklist

Before TK-1 starts, the following conditions MUST be true:

- [ ] **Working tree clean**: `git status` shows no uncommitted changes.
- [ ] **Branch created**: `git checkout -b add-herdr-multiplexor` (or similar feature branch).
- [ ] **Herdr install path confirmed**: User has confirmed where Herdr is installed (e.g., `~/.cargo/bin/herdr`, `~/.local/bin/herdr`, or `/usr/bin/herdr`). This affects PATH setup in Fish/Zsh guards.
- [ ] **Tmux version confirmed**: `tmux -V` returns 2.0+ (REQ-2 rationale: `-A` flag requires tmux 2.0+).
- [ ] **Fish shell installed**: `which fish` returns a path (REQ-9 requires Fish to test the guard).
- [ ] **Ghostty config location confirmed**: User has confirmed `~/.config/ghostty/config` exists (DG-11: in-repo edit does not auto-apply; README migration step required).
- [ ] **Backup of existing Fish config (if any)**: If user has an existing `~/.config/fish/config.fish`, they have backed it up per DG-6 migration header.
- [ ] **User has read and approved the design**: The design document (`openspec/changes/add-herdr-multiplexor/design.md`) has been reviewed and approved by the user.
- [ ] **User understands the migration steps**: The user has read the README migration steps (TK-8 / TK-3) and understands they must manually run `ln -sfn` commands to apply the changes to their live config.

---

## 9. Risks per Task

| Task | Risks created | Risks mitigated |
|------|---------------|-----------------|
| TK-1 | R-6 (dead herdr shim on PATH) — created by the liveness probe logic | R-10 (wrapper invoked before PATH resolved) — mitigated by `command -v` semantics |
| TK-2 | R-2 (Herdr upstream drops/renames config keys) — created by shipping a config tied to v0.4.x | None |
| TK-3 | R-4 (two-doc duplication drifts) — created by cross-linking to root README | R-1 (p10k gitstatus under Herdr PTY) — mitigated by documenting escape hatches |
| TK-4 | R-5 (Fish version drift) — created by shipping Fish config with tool init | R-3 (stale ghostty-tmux-new symlink) — mitigated by Fish guard preferring Herdr |
| TK-5 | R-7 (existing Ghostty users lose pure-tmux behavior) — created by changing `command =` | None |
| TK-6 | R-3 (stale ghostty-tmux-new symlink) — created by updating `bind N` | R-3 — mitigated by compatibility shim (TK-10) |
| TK-7 | R-1 (p10k gitstatus under Herdr PTY) — created by Zsh guard firing before p10k is ready | R-1 — mitigated by placement after p10k sourcing |
| TK-8 | R-4 (two-doc duplication drifts) — created by cross-linking to root README | R-3 (stale ghostty-tmux-new symlink) — mitigated by documenting `rm -f` migration step |
| TK-9 | R-4 (two-doc duplication drifts) — created by cross-linking to HatLinux README | R-8 (Herdr NOASSERTION blocks downstream packaging) — mitigated by documenting caveat |
| TK-10 | R-3 (stale ghostty-tmux-new symlink) — created by introducing the shim | R-3 — mitigated by making the shim a transparent delegation |
| TK-11 | None (verification only) | R-1, R-2, R-3, R-5, R-6, R-7, R-8, R-9, R-10 — all risks verified |
| TK-12 | None (review only) | R-1, R-3, R-6, DG-3, DG-5, DG-10 — all reviewed |
| TK-13 | R-3 (stale ghostty-tmux-new symlink) — created by removing the shim | R-3 — mitigated by ensuring all verifications passed before removal |

---

## 10. Output Envelope

```yaml
status: success
executive_summary: |
  Tasks breakdown complete for adopting Herdr as default Linux multiplexer in HatDots.
  13 tasks enumerated (TK-1..TK-13), covering 4 new files (wrapper, herdr config/README,
  fish config), 5 modified files (ghostty config, tmux.conf, zshrc, HatLinux README,
  root README), and 1 file deletion (legacy ghostty-tmux-new). Tasks follow the 8-step
  sequencing plan from design §10 (DG-3), with a compatibility shim window for safe
  migration. Total diff ~353 lines (317 added + 36 deleted), well under the 400-line
  review budget. Single PR recommended; no chained PR. Manual verification (SCN-1..SCN-9)
  and review-resilience lens are explicit tasks.
artifacts:
  - topic_key: sdd/add-herdr-multiplexor/tasks
    mirror_path: openspec/changes/add-herdr-multiplexor/tasks.md
artifacts_written_summary:
  - Review workload forecast (353 lines, Low risk, single PR)
  - Overview (one-paragraph change summary)
  - Task list (TK-1..TK-13 with files, prerequisites, implementation notes, acceptance criteria, verification commands, estimates)
  - Task ordering / dependency graph (explicit blockedBy relationships)
  - Sequencing implementation (mapping design §10 steps to tasks)
  - Commit boundaries (8 commits with messages)
  - Review workload forecast per task (line counts)
  - Verification matrix (TK → REQ/SCN mapping)
  - Pre-apply checklist (9 conditions)
  - Risks per task (risks created / mitigated)
  - Output envelope
tasks_count: 13
total_estimated_minutes: 295 (15 + 20 + 25 + 40 + 5 + 5 + 15 + 20 + 15 + 5 + 60 + 30 + 5 = 260 minutes of work + 35 minutes buffer = 295 minutes)
review_workload_summary: |
  ~353 changed lines (317 added + 36 deleted). Under the 400-line review budget.
  Single PR recommended; no chained PR. Largest contributors: TK-4 (Fish config, 110 lines),
  TK-3 (Herdr README, 70 lines), TK-10 (shim, 34 lines transitional).
next_recommended: sdd-apply
risks:
  - R-1 (medium): p10k gitstatusd under Herdr PTY — mitigated by README escape hatches, verified in TK-11
  - R-2 (medium): Herdr upstream drops/renames config keys — mitigated by known-good version in herdr/README.md
  - R-3 (low): stale ghostty-tmux-new symlink — mitigated by compatibility shim (TK-10) + README migration step (TK-8)
  - R-4 (low): two-doc duplication drifts — mitigated by cross-linking between READMEs
  - R-5 (low): Fish version drift — mitigated by `command -q` guards
  - R-6 (low): dead herdr shim on PATH — mitigated by liveness probe in wrapper + Zsh guard
  - R-7 (low): existing Ghostty users lose pure-tmux behavior — mitigated by README one-line revert
  - R-8 (low): Herdr NOASSERTION blocks downstream packaging — mitigated by documenting caveat in both READMEs
  - R-9 (low): p10k renames VCS disable flag — mitigated by documenting both old + new flag names
  - R-10 (low): wrapper invoked before PATH resolved — mitigated by `command -v` semantics
skill_resolution: gentle-ai (paths-injected from parent; read /home/hat/.pi/agent/npm/node_modules/gentle-pi/skills/gentle-ai/SKILL.md before work began)
```

---

## Acceptance Report

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Composed full SDD tasks breakdown covering 13 tasks (TK-1..TK-13), mapping to the 8-step sequencing plan from design §10. Tasks enumerate concrete implementation units with files affected (+additions/-deletions), prerequisites (blockedBy), implementation notes (referencing design §X), acceptance criteria (concrete, checkable), verification commands (shell commands a reviewer can run), and estimates (small/medium/large + minutes). Task ordering graph, commit boundaries, review workload forecast (~353 lines under 400 budget), verification matrix (TK → REQ/SCN), pre-apply checklist (9 conditions), and risks per task (R-1..R-10) are all documented. Scope held to the 4 new + 5 modified + 1 deleted file list from spec §10; no link-linux.sh / link-windows.ps1 / Nushell / macOS / p10k schema / Windows native changes. DG-1..DG-12 not re-litigated."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Evidence included: (a) 13 tasks with full details (files, prerequisites, implementation notes, acceptance criteria, verification commands, estimates); (b) explicit dependency graph showing TK-N blockedBy relationships; (c) 8-step sequencing plan mapped to tasks (design §10 steps → TK-N); (d) 8 commit boundaries with commit messages; (e) per-task review workload forecast summing to ~353 lines; (f) verification matrix mapping each TK to REQ/SCN from spec; (g) pre-apply checklist (9 conditions); (h) risks per task (risks created / mitigated); (i) output envelope with status, executive_summary, artifacts, next_recommended, risks, skill_resolution."
    }
  ],
  "changedFiles": [],
  "testsAddedOrUpdated": [],
  "commandsRun": [
    {
      "command": "read /home/hat/projects/HatDots/openspec/changes/add-herdr-multiplexor/proposal.md",
      "result": "passed",
      "summary": "Read complete proposal (238 lines); locked DG-1, DG-3, DG-4, DG-5, DG-6, DG-7, DG-8 decisions."
    },
    {
      "command": "read /home/hat/projects/HatDots/openspec/changes/add-herdr-multiplexor/spec.md",
      "result": "passed",
      "summary": "Read complete spec (431 lines); REQ-1..REQ-13, SCN-1..SCN-9, DG-1..DG-8 resolved strings, R-1..R-10 mitigations."
    },
    {
      "command": "read /home/hat/projects/HatDots/openspec/changes/add-herdr-multiplexor/design.md",
      "result": "passed",
      "summary": "Read complete design (949 lines); 14 sections, DG-9..DG-12 new decisions, full file previews, exact diffs, 8-step sequencing, workload forecast (~349 lines)."
    },
    {
      "command": "read /home/hat/projects/HatDots/openspec/config.yaml",
      "result": "passed",
      "summary": "Read openspec config; confirmed review_budget_lines=400, strict_tdd=false, execution_mode=interactive, chained_pr_strategy=auto-forecast."
    },
    {
      "command": "read /home/hat/.pi/agent/npm/node_modules/gentle-pi/skills/gentle-ai/SKILL.md",
      "result": "passed",
      "summary": "Read gentle-ai skill; confirmed SDD phase discipline, review lens selection, workload forecasting rules."
    }
  ],
  "validationOutput": [
    "No automated tests run (strict_tdd=false). All verification is manual via shell commands in task acceptance criteria.",
    "Task ordering verified: TK-1 (wrapper) is the root; TK-2..TK-10 depend on TK-1; TK-11 depends on TK-5..TK-10; TK-12 depends on TK-11; TK-13 depends on TK-11+TK-12.",
    "Sequencing verified: design §10 steps 1..8 map to TK-1, TK-10, TK-6, TK-5, TK-11, TK-7, TK-2/TK-3/TK-4/TK-8/TK-9, TK-13 respectively.",
    "Review workload verified: ~353 changed lines (317 added + 36 deleted) is under the 400-line budget.",
    "Single PR recommended: no chained PR needed (353 < 400).",
    "13 tasks enumerated (TK-1..TK-13), meeting the minimum floor requirement."
  ],
  "residualRisks": [
    "R-1 (medium): p10k gitstatusd under Herdr PTY — verify during apply (TK-11); README escape hatches documented (TK-3/TK-8).",
    "R-3 (low): stale ghostty-tmux-new symlink — compatibility shim (TK-10) + README migration step (TK-8/TK-3) + cleanup (TK-13).",
    "R-6 (low): dead herdr shim on PATH — liveness probe in wrapper (TK-1) + Zsh guard (TK-7).",
    "link-linux.sh is OUT OF SCOPE (C-2). Users with stale or post-installation state MUST run the manual `ln -sfn` steps from README (TK-3/TK-8). Failure to do so = the in-repo change does not apply."
  ],
  "noStagedFiles": true,
  "diffSummary": "Tasks breakdown proposes 13 implementation units (TK-1..TK-13) covering 4 new files (wrapper script ~38 LoC, herdr/config.toml ~35 LoC, herdr/README.md ~70 LoC, fish/config.fish ~110 LoC) and 5 modified files (ghostty/config 1-line change, tmux.conf 1-line change, zshrc +15 lines guard block, HatLinux/README +30 lines Herdr section, root README +15 lines multiplexor overview) and 1 file removal (tmux/scripts/ghostty-tmux-new, 32 lines, gated by 8-step sequencing). Total ~353 changed lines, under 400 review budget. Single PR recommended; no chained PR.",
  "reviewFindings": [
    "no blockers",
    "reviewer note: task TK-12 (review lens) is review-resilience, which is the best fit for shell/process integration changes. If the team prefers a different lens (review-readability / review-risk / review-reliability), swap TK-12's lens accordingly.",
    "reviewer note: total estimated minutes = 295 (4.9 hours). This is a reasonable estimate for a senior developer working through the 8-step sequencing plan with manual verification.",
    "reviewer note: pre-apply checklist includes 9 conditions. If any condition is false, halt before TK-1 and resolve.",
    "reviewer note: the tasks are persisted to openspec/changes/add-herdr-multiplexor/tasks.md (mirror) and Engram topic sdd/add-herdr-multiplexor/tasks (primary). The orchestrator will handle persistence."
  ],
  "manualNotes": "This tasks breakdown is ready for user approval. After approval, the next phase is sdd-apply. The orchestrator will persist this artifact to Engram + openspec mirror. The tasks follow the 8-step sequencing plan from design §10 (DG-3) and cover all 13 REQ + 9 SCN from the spec. Review workload is ~353 lines, well under the 400-line budget. Single PR is sufficient; no chained PR needed."
}
```

---

**Phase gate**: tasks phase COMPLETE. Awaiting user approval to advance to `sdd-apply`. Do not start apply until user explicitly approves.
