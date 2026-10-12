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

- [x] P1-1 Create `unify` from `main`; merge work branch, `origin/omarchy-config-merge`,
      `origin/feat/harmac-config`; resolve 9 real conflicts. Route: delegated direct
      (dedicated writer agent). Commits: `efdf151` (work branch, 0 conflicts, clean
      ff-capable fast merge), `a85c1b1` (omarchy-config-merge, 5 content conflicts +
      1 rename duplicate + 1 type-change conflict), `7fbc7a0` (feat/harmac-config, 2
      conflicts: `.gitignore`, `SETUP.md`).
- [x] P1-2 Verify Linux still works (nvim headless startup, shells syntax). All
      checks observed passing (see Progress below).

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
- 2026-10-12: Phase 1 done in worktree `/home/hat/projects/HatDots-worktrees/unify`
  (branch `unify`, HEAD `7fbc7a0`). Checks: no conflict markers left anywhere
  (`rg` scan clean); all `lazyvim.json`/`lazy-lock.json` for Linux/Mac/Windows
  valid JSON (`python3 -m json.tool`); `bash -n` clean on every `*.sh` and
  executable script under `HatLinux/scripts`, `HatMac`, `terminals/tmux`,
  `link-linux.sh`, `link-mac.sh` (one script, `HatMac/tmux/scripts/ghostty-tmux-new`,
  is zsh — checked with `zsh -n`, also OK); `zsh -n` clean on `HatLinux/zsh/.zshrc`
  and `HatMac/zsh/.zshrc`; `fish -n` clean on `HatLinux/fish/config.fish`; headless
  `nvim --headless -i NONE` startup of the merged `HatLinux/nvim` config printed
  `STARTUP_OK` and `HATNOTES true` (no errors, no lazy.nvim install attempts);
  `nvim -u NONE -i NONE -l shared/nvim/tests/creation_smoke.lua` printed
  `creation smoke passed`. No fix commit was needed.
- 2026-10-12: Independent verification (risk tier `high` from `gentle-ai review
  assess`, driven by pre-existing branch scripts) found 5 merge defects; fixed in one
  scoped correction commit: restored work-branch `GITSTATUS_AUTO_INSTALL=0` and
  Angular completion in `.zshrc` (completion now guarded by `command -v ng`), removed
  omarchy `bind K ... kill-session -a` override so work-branch `bind K kill-session`
  wins, restored work-branch `lazyvim.json` news value `11866`. Dropping omarchy's
  `default-command fish` confirmed as deliberate (work branch sets zsh). Checks:
  `zsh -n` OK, `lazyvim.json` valid JSON, single `bind K` in tmux.conf.

## Phase 1 merge decisions

- `HatLinux/nvim/lazyvim.json`: union of both `extras` lists (dap.core, lang.angular,
  lang.docker, lang.prisma, lang.python, lang.rust, lang.typescript), deduped;
  `news.NEWS.md` keeps the work-branch value `11866`.
- `HatLinux/nvim/lua/config/lazy.lua`: kept work branch's `lang.java` import and
  `performance.rtp.reset = false`; unioned in omarchy's `install.colorscheme` and
  `performance.rtp.disabled_plugins` list (non-overlapping sub-keys, merged into one
  `performance.rtp` table).
- `HatLinux/nvim/lua/plugins/obsidian.lua`: dropped omarchy's inline `onk`/`ona`/`onp`
  quick-note-creation blocks — functionally superseded by the work branch's shared
  `shared/nvim/lua/hatnotes/creation.lua` module (`creation.keys`) already wired into
  this file. Kept omarchy's `onm` (MOC creation in `5-MOCs`) verbatim: it is the one
  quick-note feature with no equivalent in `hatnotes.creation.lua`.
- `HatLinux/nvim/lua/plugins/theme.lua`: type conflict (work branch = 164-line regular
  file; omarchy = symlink to `/home/hat/.config/omarchy/current/theme/neovim.lua`).
  Kept the work-branch regular file per the approved policy. **Omarchy dynamic
  theming must be re-added in phase 3 under `os/omarchy`.**
- `HatLinux/nvim/lua/plugins/omarchy-theme-hotreload.lua` vs `theme-hotreload.lua`:
  byte-identical rename/copy conflict; dropped the `omarchy-` named duplicate, kept
  `theme-hotreload.lua` (work-branch name).
- `terminals/tmux/tmux.conf`: reconstructed as one coherent file (4 overlapping
  conflict hunks caused by reordering). Work branch wins same-setting conflicts:
  `default-shell /bin/zsh` (dropped omarchy's `default-command fish`, contradictory
  once shell is zsh), `prefix2 C-b` kept (dropped omarchy's `unbind C-b`),
  `escape-time 0` (not 10), copy-mode `y` bound to `copy-selection-and-cancel` (not
  omarchy's extra `copy-pipe-and-cancel "clip"`), and the work-branch's own
  minimal/blue status-bar theme over omarchy's "Gentleman Theme" colors (same status
  options, different values). Unioned in non-conflicting additions from omarchy:
  `set -g mode-keys vi` (session-level, in addition to the existing `setw` one),
  `set -s extended-keys on`, `set -g -a terminal-overrides '*:Ms=...'` (OSC52 clip
  passthrough, additive to the existing RGB override), `status-justify left`,
  `unbind %` / `unbind '"'` plus the `d` split key (non-overlapping with work's
  existing `h`/`v` split keys). Omarchy's `K` confirm-before bulk-session-kill override
  was removed in the correction commit (same key, work branch wins). Removed one literal duplicate of
  the "smart C-l" passthrough binding that existed twice in the work branch's own
  content (kept the one correctly placed after `run '~/.tmux/plugins/tpm/tpm'`, per
  its own comment: "Must come AFTER TPM run").
- `.gitignore`: trivial union, kept work branch's extra entries (`.pi/`,
  `.pi-subagents/`, `*.bak`); harmac side had nothing new here.
- `SETUP.md`: kept work branch's "Referencia Técnica" doc first (unchanged), closed
  out and completed harmac's truncated Windows/Linux quick-install blocks (the 3-way
  diff had silently dropped their continuation — closing fence, Linux steps,
  `Requisitos`, `Características`, `Configuración Post-Instalación`, `Atajos
  Útiles`, `Problemas Comunes`, `Contribuciones`, `Licencia` — because they fell
  outside the two marked conflict hunks), and appended all of that unique harmac
  content at the end of the file, each section tagged "(desde feat/harmac-config)".
  Deliberately did **not** duplicate harmac's own "📁 Estructura del Repositorio"
  section: it's a stale, pre-merge directory listing that would contradict the
  work branch's accurate "Estructura del repo" section already in the doc; no
  decisions or features were lost by skipping it. Per policy, no further polish
  was done — SETUP.md gets rewritten in a later phase.
- `HatMac/*` (full tree, 100+ files): added cleanly, no conflicts.

## Known issues found

- `link-linux.sh` ghostty heredoc changed to unquoted `GHOSTTY_EOF`, so every `$`
  in it now expands; superseded by the Go installer in phase 4.
- `HatLinux/fish/config.fish` hardcodes `/home/hat/.local/share/pnpm/bin`
  (`HatLinux/zsh/.zshrc` uses `$HOME` after the merge).
- tmux `default-shell` is zsh while the login shell on the Omarchy machine is fish;
  confirm the intended tmux shell in phase 2.
- Omarchy dynamic theming (symlink-based `theme.lua` sourcing
  `/home/hat/.config/omarchy/current/theme/neovim.lua`) was dropped in the merge in
  favor of the work branch's regular-file `theme.lua`; must be reintroduced under
  `os/omarchy` in phase 3.

## Next step

Phase 2: restructure into `common/` + `os/*`.
