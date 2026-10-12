# HatDots Unify

## Objective

One `main` branch that installs the right configuration on any device
(Omarchy/Linux, macOS, Windows) through a single cross-platform TUI installer.

## Problem

- Four divergent lines off `main` (8d6f687): `main`, remote `omarchy-config-merge`
  (hypr, newsboat, tmux-work), local work branch (salesforce, herdr, fish,
  hatnotes), remote `feat/harmac-config` (full `HatMac/` copy).
- Neovim exists as three drifting copies (`HatLinux/`, `HatWindows/`, `HatMac/`):
  ~19 files identical, ~22 drifting through fixes applied to one copy only.
- Three installers (`link-linux.sh`, `link-mac.sh`, `link-windows.ps1`) duplicate
  the same link/backup logic with different guarantees.

## Why

Copy-per-OS trees drift on every change; reorganizing branches alone would not
stop it.

## Scope

- Merge all lines into one integration branch, then restructure into
  `common/` + `os/{linux,omarchy,mac,windows}`.
- Single Neovim config with OS-conditional imports and one `lazy-lock.json`.
- Go + Bubbletea installer driven by a declarative module manifest.

## Constraints and decisions

- No chezmoi; own symlink-based installer (user decision, 2026-10-12).
- Installer: Go + Bubbletea, hexagonal (manifest/plan core, platform/linker/pkg
  adapters, tui). Modes: TUI, `--all`, `--dry-run`, `--yes`. Release binaries via
  GitHub Actions; `bootstrap.sh` / `bootstrap.ps1` download them.
- Remove AI plugins (avante, claude-code, gemini-cli).
- herdr: keep the Linux config (`HatLinux/herdr/config.toml`, from the work
  branch) as the common base; macOS-only bits go to `os/mac/`.
- Salesforce: compare Linux `lua/salesforce/*` vs macOS `xixiaofinland-sf` in
  phase 3 and keep the better one with evidence.
- Machine-specific values (e.g. `/home/hat/...` paths) move to untracked local
  override files.
- Push, PR creation and merge remain user decisions.

## TDD

- Mode: strict, enabled (source: global orchestrator configuration).
- Runner: `go test ./...` for the installer (Go not installed yet). Config-only
  phases use functional checks (`nvim --headless`, `fish -n`, `bash -n`).

## Delivery

- Strategy: `ask-on-risk`; one chained PR per phase.
- RDD: off (global). No native review runs.

## Tasks

### Phase 0 — Safety net

- [x] P0-1 Tag pre-unification refs (`pre-unify/main` -> 8d6f687, `pre-unify/work` -> 0414783). Route: inline.
- [x] P0-2 Rename ambiguous local branch `origin/omarchy-config-merge` to
      `work/linux-salesforce-herdr` and drop its confusing upstream. Route: inline.
- [x] P0-3 Commit uncommitted work as work-unit commits (4a6ab57, b1c7a79, 21b4aa1,
      87c6d73, 152b421, 477e2f6, 95adee7). Route: inline (git state only).
- [x] P0-4 Create `backup/pre-unify-wip` pointing at the committed work. Route: inline.

### Phase 1 — Merge lines

- [ ] P1-1 Create `unify` from `main`; merge work branch, `origin/omarchy-config-merge`,
      `origin/feat/harmac-config`; resolve 9 real conflicts.
- [ ] P1-2 Verify Linux still works (nvim headless startup, shells syntax).

### Phase 2 — Restructure

- [ ] P2-1 `git mv` terminals and shells into `common/` and `os/*`.
- [ ] P2-2 Move OS-only items (hypr, kde, newsboat, Brewfile, LaunchAgent,
      powershell, wezterm) into `os/*`.

### Phase 3 — Single Neovim

- [ ] P3-1 Merge the three nvim copies into `common/nvim`, newest version wins on drift.
- [ ] P3-2 OS-conditional plugin imports; remove AI plugins.
- [ ] P3-3 Salesforce comparison and decision.
- [ ] P3-4 Single `lazy-lock.json`.

### Phase 4 — Installer

- [ ] P4-1 Module manifest format and parser (TDD).
- [ ] P4-2 Platform detection, plan, linker, package adapters (TDD).
- [ ] P4-3 Bubbletea TUI (teatest).
- [ ] P4-4 Release workflow and bootstrap scripts.

### Phase 5 — Close

- [ ] P5-1 User verifies macOS and Windows.
- [ ] P5-2 Merge to `main`; delete obsolete branches (user decision).

## Progress

- 2026-10-12: Plan approved; phase 0 started.
- 2026-10-12: Phase 0 done. Checks: `require("hatnotes.creation")` true on full
  nvim startup; `creation_smoke.lua` passed; `fish -n` and `bash -n` OK. Tags and
  backup are local only (not pushed).

## Known issues found

- `link-linux.sh` ghostty heredoc changed to unquoted `GHOSTTY_EOF`, so every `$`
  in it now expands; superseded by the Go installer in phase 4.
- `HatLinux/fish/config.fish` hardcodes `/home/hat/.local/share/pnpm/bin`;
  `HatLinux/zsh/.zshrc` hardcodes `/home/hat/.opencode/bin` and `/home/hat/.bun`.

## Next step

Phase 1: create `unify` and merge the three lines.
