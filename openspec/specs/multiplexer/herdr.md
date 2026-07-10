# HatDots Multiplexor — Herdr + Tmux + Fish

**Canonical spec for the Herdr-as-default multiplexer capability.**

---

## 1. Overview

Replace tmux-as-default with a multiplexer-aware setup that prefers Herdr when its binary is available, falls back to tmux when it is not, and adds Fish as a parallel shell alongside the existing Zsh. Ghostty no longer hardcodes `tmux`; it invokes a new wrapper that detects the available multiplexer and behaves correctly under nesting guards. Fish gains a full GentlemFish-style port (Fisher, PATH setup, init tools, vi-mode, syntax colors). Documentation in both READMEs reflects the new surface and the upstream Herdr `NOASSERTION` license plus a v0.4.x version caveat.

---

## 2. Glossary

| Term | Meaning in this capability |
|---|---|
| **Herdr** | Upstream Rust terminal multiplexer (`herdr`). Default when present. License upstream is `NOASSERTION`. |
| **Tmux** | Existing C terminal multiplexer. Remains the explicit fallback when Herdr binary is absent. |
| **Multiplexer / Multiplexor** | Either Herdr or Tmux. Used interchangeably. |
| **PTY** | Pseudo-terminal. Herdr attaches a child shell inside a PTY, which can affect side-channel tools (e.g. p10k gitstatusd). |
| **NOASSERTION** | SPDX license identifier used by Herdr upstream; conveys "no license asserted". Documented in both READMEs as a known caveat. |
| **Session** | A named multiplexer session (e.g. `main`). The wrapper creates one session per invocation. |
| **Pane** | A region of a multiplexer window that runs one shell. Herdr exposes "agents"; Tmux exposes "panes". |
| **Wrapper** | `HatLinux/scripts/ghostty-multiplexer-new` — a thin executable that picks Herdr or Tmux based on binary presence and nesting guards. |
| **Fallback** | The deterministic behavior when the preferred multiplexer is unavailable: lower-priority multiplexer, or no multiplexer. |
| **Upstream** | `Gentleman-Programming/Gentleman.Dots`. The reference implementation that this change adapts. |
| **Guard vars** | `HERDR_ENV`, `TMUX`, `ZELLIJ` — three environment variables that mark a nesting session for each supported multiplexer. |

---

## 3. Requirements

### REQ-1 — Herdr-first auto-start when binary present

When a shell starts in an interactive, non-nested context and the `herdr` binary is on `PATH`, the shell SHALL start Herdr as the multiplexer. The start MUST be `exec`-equivalent for the preferred path (Herdr) so the shell process is replaced (no extra idle frame). The session name SHALL default to `main` when the user provides no name.

**File evidence:** `HatLinux/scripts/ghostty-multiplexer-new` (wrapper liveness probe + exec), `HatLinux/zsh/.zshrc` (Zsh guard block), `HatLinux/fish/config.fish` (Fish guard block).

### REQ-2 — Tmux fallback when Herdr absent

When Herdr is not on `PATH` (or returns non-zero from `--version`), and the shell is interactive and non-nested, the shell SHALL start Tmux with the existing config (`-f ~/.tmux.conf`) and session name `main`. Tmux MUST be invoked via the same wrapper so the user experience is identical.

**File evidence:** `HatLinux/scripts/ghostty-multiplexer-new` (fallback path), `HatLinux/tmux/.tmux.conf` (existing config, unchanged).

### REQ-3 — Nested-session prevention (3 guard vars)

The shell guard logic SHALL inspect exactly three environment variables before starting any multiplexer: `HERDR_ENV`, `TMUX`, `ZELLIJ`. If ANY of these is set (non-empty), the shell MUST NOT start any multiplexer. The set MUST be identical in Zsh and Fish to avoid inconsistent behavior when the user switches shells mid-session.

**File evidence:** `HatLinux/zsh/.zshrc` (guard block checking all three vars), `HatLinux/fish/config.fish` (guard block checking all three vars).

### REQ-4 — Pi-matching palette in Herdr config

`HatLinux/herdr/config.toml` SHALL encode the Pi-matching accent palette from `Gentleman.Dots/herdr/config.toml` (verbatim copy with attribution comment): `panel_bg = "#06080f"`, `accent = "#6FA0AF"`, `green = "#B7CC85"`, `blue = "#6FA0AF"`, `red = "#CB7C94"`, `yellow = "#DEBA87"`. The `theme.name = "one-dark"` base SHALL remain.

**File evidence:** `HatLinux/herdr/config.toml` (palette hex values).

### REQ-5 — Keybinding contract (prefix, prev/next agent, focus agent 1..9)

`HatLinux/herdr/config.toml` SHALL declare the following bindings so muscle memory is portable between Herdr and Tmux fallback:

- `prefix = "ctrl+a"`
- `previous_agent = "prefix+alt+k"`
- `next_agent = "prefix+alt+j"`
- `focus_agent = "prefix+ctrl+1..9"`

The Herdr file comment MUST justify why `Ctrl+number` is used over `Alt+number` (skhd/yabai space conflicts) and `Shift+number` (reachability under current terminal).

**File evidence:** `HatLinux/herdr/config.toml` (keybinding section).

### REQ-6 — Ghostty `command =` invokes wrapper, no hardcoded tmux

`HatLinux/ghostty/config` SHALL replace the literal `command = /usr/bin/tmux -f ~/.tmux.conf new-session -A -s main` line with a call to the new wrapper. The Ghostty config SHALL NOT contain the string `tmux` in the `command =` directive. The wrapper path SHALL be the canonical wrapper at `HatLinux/scripts/ghostty-multiplexer-new`.

**File evidence:** `HatLinux/ghostty/config` (`command =` line).

### REQ-7 — Wrapper detects Herdr binary, falls back gracefully

`HatLinux/scripts/ghostty-multiplexer-new` SHALL:

1. Be a POSIX-executable text file (shell preferred for transparency).
2. Be executable (`chmod +x`) in the repo at install time.
3. If `herdr` is on `PATH`, `exec herdr "$@"` (honoring the optional positional session name, defaulting to `main` if absent).
4. Else if `tmux` is on `PATH`, run `tmux new-session -A -s "${SESSION_NAME:-main}"` honoring any extra positional args.
5. Else, print a single-line warning to stderr and `exec "$SHELL"` so the user gets a usable prompt.

The wrapper arity SHALL be exactly: optional positional session name (`$1`). Extra args SHALL be ignored with a documented note in code comments.

**File evidence:** `HatLinux/scripts/ghostty-multiplexer-new` (full implementation).

### REQ-8 — Zsh guard parity with Fish guard

`HatLinux/zsh/.zshrc` SHALL add a guard block that mirrors the Fish guard (see REQ-9) exactly:

- Same three vars: `HERDR_ENV`, `TMUX`, `ZELLIJ`.
- Same preference order: Herdr → Tmux → nothing.
- Same default session name: `main`.
- Same interactive-only condition (Zsh: `-o interactive` shells; Fish: `status is-interactive`).

The placement SHALL be after all p10k sourcing (so the prompt is ready if multiplexing falls through) and before any user `exec`.

**File evidence:** `HatLinux/zsh/.zshrc` (guard block inserted after p10k sourcing).

### REQ-9 — Fish full GentlemFish-style port

`HatLinux/fish/config.fish` SHALL be created (new file). It SHALL include the functional blocks present in `GentlemanFish/fish/config.fish`, adapted for HatDots:

- Fisher bootstrap (if `not functions -q fisher`, install via `curl -sL https://git.io/fisher`).
- PATH setup for `~/.local/bin`, `~/.opencode/bin`, `~/.bun/bin`, `~/.cargo/bin` on Linux only.
- Multiplexer auto-start using the Fish guard (REQ-3 / REQ-8 parity).
- Starship, zoxide, atuin, fzf init sourcing.
- Carapace completions bootstrap.
- `set -g fish_greeting ""` to suppress the greeting.
- vi-mode key bindings via `fish_vi_key_bindings`.
- `EDITOR=nvim`, `VISUAL=nvim`.
- Eza/GNU ls aliases (`ls`, `fzfbat`, `fzfnvim`).
- GentlemFish syntax-highlight color variables (`fish_color_*`).

A migration header per DG-6 SHALL be the first comment block.

**File evidence:** `HatLinux/fish/config.fish` (full implementation).

### REQ-10 — Documentation in both READMEs (license + version + Windows note)

Both `HatLinux/README.md` (Herdr section) and `README.md` (root, multiplexor overview) SHALL:

1. State the upstream Herdr license as `NOASSERTION` with a one-line human interpretation.
2. State the tested-against version is `v0.4.x` with a caveat that newer versions may not have been re-validated.
3. State explicitly: "Windows native Herdr is **out of scope** for this change. WSL is the supported Microsoft path."
4. List the wrapper path, the new fish path, and the now-moved tmux.conf binding.

**File evidence:** `HatLinux/README.md` (Herdr section), `README.md` (multiplexor overview section).

### REQ-11 — `ghostty-tmux-new` removed after wrapper ready

`HatLinux/tmux/scripts/ghostty-tmux-new` SHALL be deleted from the repo *only after* the sequencing in DG-3 is complete (compatibility shim verified, new wrapper verified, both docs updated). The deletion is a single commit that runs after all three verifications pass.

**File evidence:** `HatLinux/tmux/scripts/ghostty-tmux-new` (compatibility shim present during migration window; pending removal in TK-13).

### REQ-12 — `.tmux.conf` `bind N` updated to wrapper

`HatLinux/tmux/.tmux.conf` SHALL update the existing `bind N` line to call `ghostty-multiplexer-new` instead of `ghostty-tmux-new`. The change SHALL preserve the prompt copy and the `command-prompt` semantics.

**File evidence:** `HatLinux/tmux/.tmux.conf` (`bind N` line).

### REQ-13 — p10k gitstatus verification under Herdr PTY

The spec does NOT mandate a code change to p10k. If gitstatusd fails under Herdr's PTY, the fallback is to set `POWERLEVEL9K_VCS_DISABLED=true` or `POWERLEVEL9K_DISABLE_GITSTATUS=true`, which is already a commented branch in the existing `.zshrc`. The HatLinux README SHALL mention both knobs.

**File evidence:** `HatLinux/zsh/.zshrc` (commented escape hatches), `HatLinux/herdr/README.md` (p10k escape hatch documentation).

---

## 4. Scenarios

### SCN-1 — First Ghostty launch with Herdr installed

- **GIVEN** the user has run `./link-linux.sh` (or equivalent) and `herdr` is on `PATH`
- **AND** `$HERDR_ENV`, `$TMUX`, `$ZELLIJ` are all unset
- **WHEN** the user opens Ghostty (via desktop launcher, Win+Enter, or `ghostty` CLI)
- **THEN** the shell starts and immediately `exec`s into Herdr; the user sees the Herdr chrome
- **AND** the prompt inside the first pane renders without errors
- **AND** the status line shows the Pi-matching palette accent

### SCN-2 — First Ghostty launch without Herdr

- **GIVEN** `herdr` is NOT on `PATH` (uninstalled or behind user removal)
- **AND** `tmux` IS on `PATH`
- **AND** the three guard vars are unset
- **WHEN** the user opens Ghostty
- **THEN** the wrapper falls through to Tmux; the user sees the existing Catppuccin status line
- **AND** the session name is `main`

### SCN-3 — Already inside Tmux, new Ghostty

- **GIVEN** the user ran `tmux` from another terminal
- **AND** `$TMUX` is set
- **WHEN** the user opens a fresh Ghostty window
- **THEN** neither Herdr nor Tmux starts (guard hits); the user gets a plain shell
- **AND** `echo "TMUX=$TMUX HERDR_ENV=$HERDR_ENV ZELLIJ=$ZELLIJ"` confirms only `TMUX` is set

### SCN-4 — Already inside a Herdr pane, new shell

- **GIVEN** the user is inside a Herdr pane (so `$HERDR_ENV` is set)
- **WHEN** the user runs `zsh -i` (or `fish -i`) inside that pane
- **THEN** the inner shell MUST NOT start a multiplexer (guard hits); the user gets a nested prompt
- **AND** the inner shell inherits the colors and keybindings of the host

### SCN-5 — `Ctrl+Space N` pressed with Herdr active

- **GIVEN** the user is inside Herdr with `prefix = "ctrl+a"` set
- **WHEN** the user presses `Ctrl+a N`
- **THEN** the user is prompted for a session name (free-text)
- **AND** typing `ghostty-demo` and Enter calls the wrapper, which starts a new Herdr session named `ghostty-demo`
- **AND** the user is switched into the new session

### SCN-6 — `Ctrl+Space N` pressed with Tmux fallback

- **GIVEN** Herdr is absent and Tmux is running
- **WHEN** the user presses `prefix N` in Tmux (the prefix is `Ctrl+Space` in Tmux)
- **THEN** the wrapper creates a new Tmux session named per prompt input
- **AND** the session has 2 windows: `nvim` and `shell` (matches the legacy layout)

### SCN-7 — Fish shell started from TTY (no Ghostty)

- **GIVEN** the user types `fish` in a Konsole/Tilix/TTY session
- **AND** `fish` is on `PATH` and `~/.config/fish/config.fish` is the HatDots version
- **AND** none of the three guard vars are set
- **WHEN** Fish starts interactively
- **THEN** Fish applies the GentlemFish-equivalent setup (PATH, starship, zoxide, vi-mode, syntax colors)
- **AND** Fish auto-starts Herdr (or Tmux fallback) per the guard
- **AND** the prompt renders with git branch when p10k is replaced by starship

### SCN-8 — Zsh shell started from TTY (no Ghostty)

- **GIVEN** the user opens a TTY (e.g. Ctrl+Alt+F2)
- **AND** the TTY login shell is zsh
- **AND** none of the three guard vars are set
- **WHEN** Zsh starts
- **THEN** Zsh applies its full setup (p10k, zoxide, atuin, fzf) and then auto-starts the preferred multiplexer
- **AND** no `command not found` errors appear in the startup trace

### SCN-9 — Herdr binary updated upstream (version handling)

- **GIVEN** the user just ran `brew upgrade herdr` (or rebuilt from upstream `main`) and the version is now `v0.5.x`
- **WHEN** the user opens Ghostty
- **THEN** the wrapper starts Herdr normally
- **AND** if any Herdr config keys changed schema (e.g. `focus_agent` → `jump_to_agent`), the user sees a warning and a clear pointer to `HatLinux/herdr/README.md` for the known-good-version check
- **AND** the user can revert by pinning to the upstream commit referenced in the README

---

## 5. Constraints & Invariants

- **C-1 (license + version documentation):** Every place Herdr is mentioned in repo docs MUST include the `NOASSERTION` license note and the `v0.4.x` tested-against version.
- **C-2 (scope: no installer changes):** `link-linux.sh` and `link-windows.ps1` are out of scope. The HatLinux README documents the migration steps users perform manually.
- **C-3 (Windows status):** Native Windows Herdr is unsupported. WSL is the supported Microsoft path. The root README explicitly states this.
- **C-4 (Tmux retained as binary and config):** This change does NOT remove tmux from the system or from `HatLinux/`. `HatLinux/tmux/.tmux.conf` is updated (REQ-12) but not deleted.
- **C-5 (file surface hard-limits):** Net new files: `HatLinux/scripts/ghostty-multiplexer-new`, `HatLinux/herdr/config.toml`, `HatLinux/herdr/README.md`, `HatLinux/fish/config.fish`. Net removed files: `HatLinux/tmux/scripts/ghostty-tmux-new`. Modified files: `HatLinux/ghostty/config`, `HatLinux/tmux/.tmux.conf`, `HatLinux/zsh/.zshrc`, `HatLinux/README.md`, `README.md`.
- **C-6 (no test runner):** No test framework required. Verification is manual using the SCN-1..SCN-9 procedures.
- **C-7 (Fedora-first):** HatDots is Fedora-first. The Linux PATH blocks in the Fish file are Linux-only; macOS branches from GentlemFish are intentionally NOT ported.
- **C-8 (semver of decisions):** Decisions resolved in the SDD spec (§5) are binding for apply. The next phase must not re-open DG-1..DG-8 without an explicit AC amendment.

---

## 6. Out of Scope

- `link-linux.sh` changes
- `link-windows.ps1` changes
- Nushell support
- Removing `tmux` from the system
- Windows-native Herdr (anything other than WSL)
- macOS support (HatDots stays Fedora-first)
- Upgrading `p10k` schema or migrating from `p10k` to `starship` in Zsh
- A dotfiles-managed homebrew bundle for Herdr
- New keybindings beyond what is needed to mirror Tmux fallback muscle memory

---

## 7. Acceptance Criteria

| AC | Description | Maps to |
|---|---|---|
| **AC-1** | Herdr is installed and `herdr --version` succeeds | REQ-1, REQ-7; SCN-9 |
| **AC-2** | First Ghostty launch starts Herdr | REQ-1, REQ-6, REQ-7; SCN-1 |
| **AC-3** | Fish starts cleanly from TTY (no nesting) | REQ-3, REQ-8, REQ-9; SCN-7 |
| **AC-4** | Zsh starts cleanly from TTY (no nesting) | REQ-3, REQ-8; SCN-8 |
| **AC-5** | p10k gitstatus shows branch inside Herdr pane | REQ-13; SCN-1 |
| **AC-6** | `Ctrl+Space N` inside Herdr creates new session | REQ-5, REQ-7; SCN-5 |
| **AC-7** | `Ctrl+Space N` inside Tmux fallback creates new session | REQ-12; SCN-6 |
| **AC-8** | When Herdr binary absent, Tmux launches instead | REQ-2, REQ-7; SCN-2 |
| **AC-9** | Both READMEs document license + version + Windows note | REQ-10 |

---

## 8. Open Risks

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| **R-1** | Herdr PTY swap breaks p10k gitstatusd handshake | Medium | REQ-13 verification + documented escape hatches in `.zshrc` and README |
| **R-2** | Herdr upstream drops/renames config keys in a future release | Medium | Track upstream `main` + version note in `herdr/README.md` |
| **R-3** | User has stale `~/.local/bin/ghostty-tmux-new` symlink after migration | Low | Compatibility shim window + README `rm -f` migration step |
| **R-4** | Two-doc duplication of license/version text drifts over time | Low | Root README is the canonical source; per-folder README mirrors only Herdr-specific prose |
| **R-5** | Fish/HatLinux tests against a fish version that diverges from the user's installed fish | Low | Fish bootstrap uses `command -q`/guards so missing binaries are skipped, not fatal |
| **R-6** | Wrapper PATH-ordering picks a `herdr` shim that fails | Low | Zsh guard `herdr --version` liveness probe; wrapper does the same |
| **R-7** | Existing Ghostty users who want pure tmux lose that on next ghostty config reload | Low | README one-line revert documented |
| **R-8** | Herdr `NOASSERTION` license blocks downstream packaging (e.g. nix home-manager mass-install) | Low | Documented in both READMEs; users who hit this opt out of Herdr and stay on Tmux fallback |
| **R-9** | p10k new release changes the VCS disable flag name | Low | Escape hatches document two flags (`VCS_DISABLED` + `DISABLE_GITSTATUS`) to cover current and previous schemas |
| **R-10** | Wrapper is invoked before `PATH` is fully resolved in the user's shell session | Low | Wrapper runs as its own process and uses `command -v` from its own fresh PATH inheritance from Ghostty |

---

## 9. Files Touched

**New:**
- `HatLinux/scripts/ghostty-multiplexer-new` — POSIX shell wrapper (Herdr/Tmux launcher)
- `HatLinux/herdr/config.toml` — Pi-matching palette and keybindings
- `HatLinux/herdr/README.md` — Install, keybinding, license, and version docs
- `HatLinux/fish/config.fish` — Full GentlemFish port with multiplexer guard

**Modified:**
- `HatLinux/ghostty/config` — `command =` line → wrapper invocation
- `HatLinux/tmux/.tmux.conf` — `bind N` → wrapper invocation
- `HatLinux/zsh/.zshrc` — Zsh guard block added after p10k sourcing
- `HatLinux/README.md` — Herdr section with license, version, and migration steps
- `README.md` (root) — Multiplexor overview with Herdr/Tmux/Fish mention

**Removed (after migration):**
- `HatLinux/tmux/scripts/ghostty-tmux-new` — superseded by wrapper

---

## 10. Decisions (Locked)

The following design decisions are locked and must not be re-opened without an explicit AC amendment:

| ID | Decision | Value |
|---|---|---|
| **DG-1** | Wrapper location | `HatLinux/scripts/ghostty-multiplexer-new` (cross-multiplexer folder) |
| **DG-2** | p10k gitstatus | Verify during apply; no code change to p10k |
| **DG-3** | Deletion sequencing | 8-step plan with compatibility shim window |
| **DG-4** | Version policy | Track upstream `main`; document v0.4.x |
| **DG-5** | Guard parity exact strings | Zsh: `[[ -o interactive ]] && [[ -z "$HERDR_ENV" && -z "$TMUX" && -z "$ZELLIJ" ]]`; Fish: `if status is-interactive; and not set -q HERDR_ENV; and not set -q TMUX; and not set -q ZELLIJ` |
| **DG-6** | Fish migration header | Warning block at top with backup + symlink instructions |
| **DG-7** | Wrapper arity | One optional positional arg (session name); default = `main` |
| **DG-8** | License docs placement | Both READMEs (root canonical; per-folder mirrors) |
| **DG-9** | Wrapper shebang | `#!/bin/sh` (POSIX), NOT bash, NOT zsh |
| **DG-10** | Signal trap | Wrapper traps TERM/INT/HUP for tmux fallback cleanup |
| **DG-11** | Ghostty config edit | In-repo only; README migration step required for `ln -sfn` |
| **DG-12** | Fish env scope | `set -gx` (session-scoped), NOT `set -Ux` (universal) |

---

## 11. Verification Procedures

A reviewer can independently verify each acceptance criterion with the following minimal steps (no test framework required):

1. `which herdr && herdr --version` → expect non-zero output and zero exit.
2. `cd ~/projects/HatDots && ./link-linux.sh` (or manual equivalents from SCN-1..SCN-9).
3. Open Ghostty from desktop launcher → expect Herdr chrome (SCN-1) or Tmux fallback (SCN-2).
4. Inside any tmux session: `tmux source-file ~/.tmux.conf`, then `prefix N`, type a name → expect new session (SCN-5 / SCN-6).
5. `chsh -s $(which fish)` (one-time, optional), then log in fresh. Expect Fish comes up with starship + vi-mode + GentlemFish colors.
6. Manually inspect `HatLinux/README.md` Herdr section AND root `README.md` multiplexor overview for `NOASSERTION`, `v0.4.x`, Windows note.
7. To verify SCN-3 / SCN-4 nesting: from inside Herdr, `fish -i` or `zsh -i` → expect plain shell, no multiplexer start.
8. To verify SCN-9 version handling: temporarily rename `herdr` binary out of PATH, run wrapper, confirm Tmux fallback, then restore.

---

---
change_origin: add-herdr-multiplexor
synced_from: openspec/changes/add-herdr-multiplexor/spec.md
artifact_store: engram (sdd/add-herdr-multiplexor/spec), openspec mirror
synced_at: 2026-07-10
locked_decisions: [DG-1, DG-2, DG-3, DG-4, DG-5, DG-6, DG-7, DG-8, DG-9, DG-10, DG-11, DG-12]
---
