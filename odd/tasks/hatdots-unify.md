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

- [x] P2-1 `git mv` terminals and shells into `common/` and `os/*`. Route:
      inline (single-writer phase, dedicated worktree). Commit `fa03b5f`.
- [x] P2-2 Move OS-only items (hypr, kde, newsboat, Brewfile, LaunchAgent,
      powershell, wezterm) into `os/*`. Commit `7980f15`.
- [x] P2-3 Load os/local overlays from the common configs (tmux, ghostty,
      zsh, fish, + newsboat's `browser` via its own `include`); carve out the
      overlay files and fold in generic drift. Commit `d9ca82f`.
- [x] P2-4 tmux: prefer fish as default shell (`run-shell` + `command -v
      fish`, falls back to `$SHELL`). Verified with a real tmux server.
      Commit `ef0415d`.
- [x] P2-5 Point link-linux.sh / link-mac.sh / link-windows.ps1 at the new
      layout (+ overlay links) and fix stale paths in README.md/SETUP.md.
      Commit `b27305d`.

### Phase 3 — Single Neovim

- [x] P3-1 Merge the three nvim copies into `common/nvim`, newest version wins on drift.
      Commits `71f7c4a` (move), `c06aea4` (fold). See "Phase 3 decisions" below.
- [x] P3-2 OS-conditional plugin imports; remove AI plugins. Commit `d23feb0`.
      Verified: `rg` scan for avante/claude-code/gemini/copilot/supermaven across
      `common/nvim` only matches the intentional disabled.lua stubs.
- [x] P3-3 Salesforce comparison and decision. Commit `b883cee`. **User
      decision: keep `xixiaofinland/sf.nvim` (option B), drop the custom
      Linux module (option A)** — portability across every OS beat a
      Linux-only hand-rolled integration. Restored `xixiaofinland-sf.lua`,
      `apex_ls.lua`, `fzf-lua.lua`, `overseer.nvim` from
      `common/nvim/parked/salesforce-mac/` (dir removed) and the Salesforce
      `<leader>S*` which-key group from
      `refs/remotes/origin/feat/harmac-config`; deleted `lua/salesforce/*`
      (10 files), `plugins/salesforce.lua`, `salesforce.md`. Split
      `akinsho/toggleterm.nvim` into its own `plugins/toggleterm.lua` (still
      needed by `lua/config/keymaps.lua`'s `<leader>tt`/`<leader>tn`, which
      call it directly — not vestigial). `os/mac/bin/hat-sf-install` moved to
      `common/bin/` (OS-agnostic) and wired into both install scripts.
      **Lost features** (sf.nvim doesn't cover these; the custom module did):
      Apex/LWC/trigger scaffolding (`new_apex_class`/`new_lwc`/`new_trigger`
      in the deleted `salesforce/scaffolds.lua`), a SOQL query picker, a
      debug-log picker, and the lualine org-indicator component. The old
      `<leader>Sd`/`Ss`/`SsA`/`SsC` test-granularity keys have no 1:1 sf.nvim
      mapping (`St`/`Stt` cover file/class). Anonymous Apex (`<leader>Sa`) and
      retrieve-by-type (`<leader>Smt`) WERE recovered via sf.nvim's own
      `SF currentFile RunAsAnonymous` / `SF mdtype list` (commit `adaca92`).
      Scaffolding could be ported later as a thin layer on top of sf.nvim if
      wanted — not done without asking, out of this task's scope.
      Verified: `+Lazy! restore` installed `sf.nvim`/`fzf-lua`/`overseer.nvim`
      cleanly (no further lock drift this time); isolated startup still
      prints `STARTUP_OK`/`HATNOTES true`/`THEME aether`, no errors;
      `exists(':SF')` → `2` after force-loading the plugin; dumping
      `nvim_get_keymap('n')` after firing `User VeryLazy` (needed in headless
      mode for the `event = "VeryLazy"` which-key-groups.lua config to run)
      found **zero** duplicate `lhs` across all 341 normal-mode maps, and all
      9 restored `<leader>S*` mappings present exactly once; `+checkhealth
      sf` was initially `1 ⚠️ 1 ❌` ("apex parser not installed") purely
      because `:Lazy restore` doesn't open an apex buffer to trigger
      nvim-treesitter's `auto_install` — forcing `:TSInstall apex soql sosl
      sflog` once resolved it to `1 ⚠️` (only the pre-existing optional
      `ctags` hint) with **0 errors**; `rg -n 'salesforce\.' common/nvim`
      only matches a historical comment in the new `toggleterm.lua`, no
      stale `require`s; all 3 nvim tests still GREEN; `git status` clean.
- [x] P3-4 Single `lazy-lock.json`. Commits `c06aea4` (add smear-cursor.nvim),
      `d23feb0` (drop supermaven-nvim), `4b1aed7` (14 stale pins re-resolved by
      a real `+Lazy! restore`, unrelated to merge decisions — see that commit).
- [x] P3-5 Follow the Omarchy theme (Ghostty + Neovim), with live reload.
      Commits `ce64d33` (nvim: `lua/config/omarchy_theme.lua` +
      `plugins/omarchy-theme-watch.lua` + tests; the watch plugin was later folded into `theme-hotreload.lua` in `f5f884b`), `5518224` (desktop overlay
      layer: `omarchy.tmux.conf`, `omarchy.ghostty`), `233c55c` (link-linux.sh
      wiring). RED/GREEN evidence:
      - `tests/omarchy_theme_smoke.lua` (path/available/spec/is_omarchy): RED
        was `module 'config.omarchy_theme' not found` before the module
        existed, then (after writing it) a second RED confirmed by
        temporarily stubbing `is_omarchy()` to `return false` and observing
        its assertion fail; GREEN after restoring the real implementation.
      - `tests/omarchy_theme_watcher_smoke.lua` (fs-event watcher): RED
        confirmed twice — once from a real bug (watching `current/` instead
        of the Omarchy base dir missed the fixture's symlink swap, since
        inotify on Linux doesn't reliably watch recursively) that changed the
        implementation, and once more by stubbing `watch()` to `return nil`.
        GREEN after fixing the watch target to the base dir and restoring the
        real implementation.
      Live verification (this machine is Omarchy): isolated instance printed
      `AVAILABLE true`, `IS_OMARCHY true`, `COLORS_NAME aether` — matches
      `~/.config/omarchy/current/theme/neovim.lua`'s actual spec on this
      machine (also "aether").

### Phase 4 — Installer

- [x] P4-1 Module manifest format and parser (TDD). Commit `900caa0`
      (domain types + manifest parser/validator).
- [x] P4-2 Platform detection, plan, linker, package adapters (TDD). Split
      into subtasks, each its own commit:
  - [x] P4-2a Detect platform and package manager. Commit `508531d`.
  - [x] P4-2b Build install plans (`domain.BuildPlan`). Commit `d688a8e`.
  - [x] P4-2c Apply links with idempotent backups (linker adapter,
        Windows junction fallback behind a build-tag-isolated interface).
        Commit `2af9c75`.
  - [x] P4-2d Package manager adapters (pacman/AUR/apt/dnf/zypper/brew/
        winget/scoop command building + Executor port). Commit `32d01b5`.
  - [x] P4-2e Non-interactive CLI (`internal/app` use cases +
        `cmd/hatdots`). Commit `d7891f5`.
  - [x] Real repo manifest (`modules.toml`) + parity tests against the
        three old scripts. Commit `63f3d10`.
- [x] P4-3 Bubbletea TUI (teatest). Commits `e28e4b0` (TUI: detect/select/
      preview/apply/result screens + unit/golden tests), `8de4898`
      (launch on interactive terminals).
- [x] P4-4 Release workflow and bootstrap scripts. Commits `26fdd87`
      (workflows + goreleaser config), `cf21f16` (bootstrap scripts +
      asset-pair test).
- [x] P4-5 Remove old installers (new task, added when the parity test
      passed on the final manifest). Scripts deleted as part of commit
      `e28e4b0` (bundled with the TUI commit by a staging-order slip —
      `git rm` had already staged the deletion before the TUI files were
      added; not rewritten after the fact per the no-history-rewrite
      rule). Docs commit `94efc94`.

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
- 2026-10-12: Phase 2 done in the same worktree, HEAD `b27305d` (5 commits:
  `fa03b5f` move terminal/shell configs, `7980f15` move os-specific configs,
  `d9ca82f` load overlays + fold drift, `ef0415d` tmux fish default-shell,
  `b27305d` fix installer paths). Checks (all observed, see each below):
  no conflict markers (`rg` scan, excluding the pre-existing `===` ASCII divider
  in `openspec/changes/add-herdr-multiplexor/design.md`); `git status` clean;
  every path in `git diff --stat --diff-filter=D decc87c HEAD` explained (67
  paths — see "Phase 2 layout decisions" and "Dropped content" below; most of
  the `terminals/ghostty/shaders/*`+`themes/*`+`shared/starship.toml` entries
  are a git-diff pairing artifact, not real loss: those were byte-identical
  duplicates of `HatMac/ghostty/shaders/*` and `HatWindows/starship.toml`, and
  git's rename detector can only credit one of two identical sources, so the
  other prints as a plain delete even though the content survives at
  `common/`); `bash -n` clean on 20 bash-shebang scripts and `zsh -n` clean on
  3 zsh-shebang scripts (found via shebang sniff, not extension) including
  `link-linux.sh`/`link-mac.sh`; `zsh -n` clean on `common/zsh/.zshrc` and
  `os/mac/zsh/os.zsh`; `fish -n` clean on `common/fish/config.fish` (no fish
  overlay exists yet — none needed, nothing mac/omarchy-specific to add); tmux
  `run-shell` default-shell fix verified against a real `tmux -L p2check -f
  common/tmux/tmux.conf new-session -d -s main \; show -g default-shell` →
  printed `default-shell /usr/bin/fish`, no stderr from the `source-file -q`
  overlay lines; `ghostty +validate-config --config-file=common/ghostty/config`
  → exit 0, no output (ghostty is installed here); every path referenced by
  `link-linux.sh`/`link-mac.sh` resolved with a small ad-hoc `rg`+loop check
  (all OK); `link-windows.ps1` paths checked by hand (all exist) since `pwsh`
  is not installed here — **unverified by the PowerShell parser**; Neovim
  diff (`HatLinux/nvim HatMac/nvim HatWindows/nvim shared/nvim`) is *not*
  empty — its one line is the explicitly-authorized
  `HatWindows/nvim/GEMINI.md` → `os/windows/docs/GEMINI.md` move (a doc, not
  nvim config/plugin code); `HatWindows/nvim/.claude/` untouched.
- 2026-10-12: Independent phase 2 verification: Linux/Omarchy effective configs
  (common + linked overlays) equivalent to the live decc87c files except the
  intended tmux fish shell; ghostty Omarchy dynamic theme was never active in the
  live config (`HatLinux/ghostty/config`), so nothing changed there; all 67
  deletions accounted for (byte-identical counterparts). One defect: mac
  `tmux-work` lost cwd detection; fixed in `3897765` (`bash -n` OK; fallback
  observed resolving to the current directory without `omarchy-cmd-terminal-cwd`).
- 2026-10-12: Phase 3 done (P3-1/P3-2/P3-4/P3-5; P3-3 followed as a separate
  task below) in the same worktree, HEAD `4b1aed7` (8 commits: `71f7c4a` move,
  `c06aea4` fold mac/windows, `d23feb0`
  remove AI plugins, `ce64d33` follow Omarchy theme + tests, `5518224` omarchy
  overlay layer, `233c55c` installer links + doc paths, `4b1aed7` stale
  lazy-lock pins). See "Phase 3 decisions" below for the per-file merge
  outcome. Checks (all observed; see "Verification" implicit in each command
  below — this phase's checks are listed here rather than in a separate
  subsection since they map directly to the task's own numbered list):
  1) `+Lazy! restore` on the isolated `NVIM_APPNAME=hatdots-unify` instance:
     completed (git checkouts all succeeded); it also rewrote 14 stale pins —
     see `4b1aed7`. Mason tool downloads (`codelldb`, `vscode-spring-boot-tools`)
     were still running when the 90s timeout hit the headless process; this is
     pre-existing config, unrelated to the merge, and not re-run to
     completion (network-bound binary download, not a plugin-restore check).
  2) Startup: printed `STARTUP_OK`, `HATNOTES true`, `THEME aether`, no lua
     errors; `+checkhealth lazy` → all ✅ (lazy.nvim, git, no other package
     manager detected, no packer_compiled.lua, luarocks disabled).
  3) AI-plugin grep: only the five intentional `disabled.lua` stub entries
     (CopilotChat, gemini-cli, copilot.lua, avante.nvim, supermaven-nvim)
     match; no live usage anywhere else in `common/nvim`.
  4) Tests: `tests/creation_smoke.lua`, `tests/omarchy_theme_smoke.lua`,
     `tests/omarchy_theme_watcher_smoke.lua` all GREEN; RED evidence recorded
     under task P3-5 above.
  5) Omarchy live check (this machine is Omarchy): isolated instance printed
     `AVAILABLE true`, `IS_OMARCHY true`, `COLORS_NAME aether`, matching
     `~/.config/omarchy/current/theme/neovim.lua`'s real spec on this box.
  6) `ghostty +validate-config --config-file=common/ghostty/config` → exit 0,
     also re-checked with the omarchy.ghostty overlay actually linked (fake
     `$HOME`) → exit 0; `tmux -L p3 -f common/tmux/tmux.conf ... show -g
     default-shell` → `/usr/bin/fish`, also re-checked with
     omarchy.tmux.conf actually linked → same, no parse errors; `bash -n`
     clean on `link-linux.sh`/`link-mac.sh`; `zsh -n` clean on
     `common/zsh/.zshrc`; `fish -n` clean on `common/fish/config.fish`.
     `link-windows.ps1` is **not** verified by the PowerShell parser in this
     environment (no `pwsh` installed, same pre-existing limitation phase 2
     already flagged) — paths checked by hand.
  7) `fd -t d '^(HatLinux|HatMac|HatWindows|shared)$' --max-depth 1` → empty.
     `git status` → clean.
- 2026-10-12: Independent phase 3 verification + parent runtime check. Found:
  (1) `plugins/omarchy-theme-watch.lua` NEVER loaded — lazy.nvim dedupes local
  specs sharing `dir` with `theme-hotreload`, so Omarchy theme switches did not
  reach Neovim (module-level watcher tests passed, wiring was untested). RED:
  new full-config check `tests/omarchy_theme_wiring_check.lua` printed
  "FAIL: omarchy theme watcher is not running after startup". Fix `f5f884b`:
  watcher started from `theme-hotreload` config, duplicate plugin deleted.
  GREEN: wiring check passed; touching the real Omarchy `neovim.lua` mtime
  fired `User LazyReload` and aether reloaded. (2) `obsidian.lua` sent Windows
  to Linux hunspell path/`xdg-open`, and macOS crashed-to-concat on unset
  `HOMEBREW_PREFIX`; fix `5d49649` (`vim.ui.open`, per-OS guarded hunspell).
  (3) undisclosed Salesforce key losses; two recovered in `adaca92`, rest
  disclosed under P3-3. Checks after fixes: 0 duplicate normal-mode lhs,
  obsidian loads, all smoke tests GREEN (run from repo root; they are
  cwd-relative).
- 2026-10-12: P3-3 decided and done, HEAD `b883cee`. User chose sf.nvim over
  the custom module; see task P3-3 above for the full restore/delete/verify
  detail. One real finding during verification: `+checkhealth sf` initially
  reported the apex treesitter parser missing — not a config defect, just
  `:Lazy restore` never opening an apex buffer to trigger `auto_install`;
  resolved by running `:TSInstall apex soql sosl sflog` once, then
  `+checkhealth sf` was clean (only the pre-existing optional ctags hint).
- 2026-10-12: Phase 4a done (P4-1/P4-2/real manifest; P4-3/P4-4 are phase
  4b), HEAD `63f3d10`, 7 commits (`900caa0` manifest schema+parser,
  `508531d` platform detection, `d688a8e` BuildPlan, `2af9c75` linker,
  `32d01b5` pkg adapters, `d7891f5` app+CLI, `63f3d10` real manifest+
  parity). New Go module `github.com/hat-y/HatDots/installer` under
  `installer/`, hexagonal: `internal/domain` (pure: Module/Link/
  PackageSpec/PostInstall/Platform/Manifest/Plan/Action + `BuildPlan`,
  disk-free via an `FSState` port), `internal/manifest` (TOML parse +
  validate), `internal/platform` (OS/Omarchy/distro/pkg-manager
  detection), `internal/linker` (real `FSState` + `Linker.Apply`,
  Windows dir-link fallback behind a build-tag-isolated
  `dirLinkStrategy` interface so the fallback decision itself is a
  Linux test), `internal/pkg` (per-manager command building + an
  `Executor` port), `internal/app` (Load/Plan/Apply use cases),
  `cmd/hatdots` (stdlib-`flag` CLI: `list`, `--all`/`--only`/
  `--dry-run`/`--yes`/`--os`/`--desktop`/`--repo`). See
  `installer/README.md` for the full schema, the required/optional
  table (provisional, open question below), and every deliberate
  deviation from the old scripts.
  RED/GREEN evidence (one line per task, full detail in each commit
  message):
  - P4-1: `go test ./internal/manifest/...` failed to build
    (`undefined: Parse, Validate`) before manifest.go/validate.go
    existed; GREEN after, 18 cases across domain+manifest.
  - P4-2a: `go test ./internal/platform/...` failed to build
    (`undefined: DetectOmarchy, DetectPkgManagerFor, ...`); GREEN after,
    11 cases.
  - P4-2b: moved `plan.go` aside, confirmed `go test
    ./internal/domain/...` failed to build (`undefined: BuildPlan,
    Action, DstState, ...`), restored it; GREEN after, 12 top-level
    cases (several table-driven).
  - P4-2c: `go test ./internal/linker/...` failed to build
    (`undefined: FSState, Linker`); GREEN after, 10 cases, including the
    Windows symlink-then-junction-fallback decision exercised purely on
    Linux via injected functions.
  - P4-2d: `go test ./internal/pkg/...` failed to build (`undefined:
    Command`); GREEN after, 14 cases across every manager.
  - P4-2e: `go test ./internal/app/...` and `go test
    ./cmd/hatdots/...` both failed to build (`undefined: Load, Event,
    run, findRepoRoot, ...`); GREEN after, 6 + 10 cases.
  - Real manifest/parity: deliberately broke tmux's `dst_mac` override
    (`~/.tmux.conf` -> `~/.tmux-BROKEN.conf`) and reran `go test
    ./internal/parity/... -run TestParity_Mac`, which failed with
    "old-script pair not covered by the new manifest's plan"; reverted,
    GREEN again.
  Full-suite verification (all observed): `go vet ./...` clean;
  `gofmt -l .` empty; `go test ./... -race -count=1` passes across all
  8 packages; `go test ./... -cover` shows 70-89% per package (parity
  has no statements of its own, by design — it's all assertions over
  the other packages' output); `GOOS=darwin go build ./...`,
  `GOOS=windows go build ./...`, and `GOARCH=arm64 GOOS=darwin go
  build ./...` all succeed; `go run ./cmd/hatdots --repo .. --dry-run
  --all --yes` on this machine (linux+omarchy, real detection) printed
  a 29-action plan reflecting this machine's actual `~/.config` state
  (several `link-replace`/`backup-then-link` actions against real
  pre-existing files, not just `link-create`); the same with `--os mac
  --desktop none` (28 actions) and `--os windows --desktop none`
  (4 actions, `LOCALAPPDATA` env var supplied manually since this
  machine is Linux) also printed plans; a before/after `git status`
  and an `ls -la ~/.config | md5sum` snapshot were byte-identical
  across all three dry runs — confirmed nothing was touched.
  Parity results per platform: linux+omarchy, linux (no desktop), mac,
  and windows each pass `installer/internal/parity`'s
  `TestParity_*`, i.e. the plan from the real manifest contains every
  `(src, dst)` pair hand-extracted from reading (never running)
  `link-linux.sh`/`link-mac.sh`/`link-windows.ps1`. Mac and Windows
  carry every old pair with zero drops. Linux drops 5 pairs, each
  documented with a reason in `installer/internal/parity/parity_test.go`'s
  `linuxDropped` and in `installer/README.md`: the shaders-only link
  (superseded by linking the whole `common/ghostty` dir, a superset),
  the heredoc-generated `~/.config/ghostty/config` (superseded by the
  tracked `common/ghostty/config`, linked directly), the two
  heredoc-generated launcher scripts (superseded by the tracked
  `common/bin/ghostty-multiplexer-new`, already wired into
  `common/ghostty/config`'s `command =` line), and the heredoc-generated
  `tmux-session-layout` (superseded by Herdr, see
  `openspec/changes/add-herdr-multiplexor`, now the primary
  multiplexer). One real gap found and fixed while building the
  parity fixture: `link-linux.sh` has always copied (not symlinked)
  `.p10k.zsh` to Linux too, which the first manifest draft missed
  entirely (the `zsh` module was mac-only); fixed by widening `zsh` to
  `os = ["linux", "mac"]` with only the `.p10k.zsh` link unfiltered
  (`.zshrc`/`os.zsh` stay mac-only), and unifying Linux to a symlink
  like mac already used instead of a copy.
  Also extended beyond strict 1:1 parity, per the task's own
  instruction to cover "everything... including the overlay layer
  from the tracker table... common/bin scripts... hypr (omarchy)...
  kde (linux)": newsboat wired up for Linux (`os/linux/newsboat/
  os.newsboat` existed but no script ever linked it), the Omarchy
  `hypr/bindings.lua`+`autostart.lua` (previously a manual step
  link-linux.sh only printed instructions for) and KDE's `kwinrc`
  (previously only in `os/linux/README.md`'s manual `ln -sf`
  instructions) are now real modules. `kglobalshortcutsrc-kzones` was
  deliberately left out — a partial fragment, not a whole-file
  replacement; see `installer/README.md`.
  Open questions for the user (none blocked implementation, both are
  documented in `installer/README.md`): (1) the required set
  `{nvim, fish, starship}` is still provisional per the original
  instruction — in particular, `starship` is required here but macOS's
  own `os/mac/Brewfile` deliberately comments it out in favor of
  `powerlevel10k`; this manifest now installs/links both on mac,
  which could mean both are "active" in `.zshrc` depending on existing
  init order — worth an explicit decision later rather than leaving
  both wired. (2) AUR helper detection (`platform.DetectPkgManagerFor`)
  is implemented and tested but not yet threaded through
  `internal/app.Apply`'s package-install step, since no module needs
  an AUR-only package yet; a small follow-up if one ever does.
- 2026-10-12: Live-machine fixes to phase 4a, HEAD `977e714`, 5 commits
  (`3d416e6`, `e212e74`, `0d61dd7`, `4f84951`, `977e714`). A parent review
  of `--all --dry-run` output on this real Omarchy machine found the
  plan would have regressed the live setup; fixed before anything was
  ever applied (this machine's `~/.config` was never actually touched —
  see verification below).
  - **hypr stale** (`3d416e6`): `os/omarchy/hypr/{bindings,autostart}.lua`
    (May) predated Omarchy's switch to its current `o.bind`/
    `o.exec_on_start` Lua API; the live files (June) already use it.
    Imported the live files verbatim as the new repo versions; carried
    the hat-news autostart over to the new API
    (`o.exec_on_start("sleep 5 && hat-news")`) and flagged the amixer
    lines as hardware-specific (this PC's ALSA card index 2) with a
    comment. Found in passing: the old repo `bindings.lua` also had a
    `SUPER+SHIFT+R` newsboat-launcher keybind with no live equivalent —
    a second repo-unique behavior beyond hat-news, not carried over
    (the live file is authoritative here); open for the user to decide
    whether to re-add it. Verified with `luac -p` (syntax only).
  - **launchers wrongly marked superseded** (`e212e74`): live
    `~/.config/hypr/bindings.lua` still binds SUPER+RETURN to
    `hatdots-launch-terminal` and SUPER+ALT+RETURN to
    `hatdots-launch-terminal-tmux`, and `common/bin/ghostty-multiplexer-new`
    still falls back to `tmux-session-layout` when herdr isn't on PATH.
    Copied all three live scripts into `os/omarchy/bin/` (stripped a
    stray trailing `SCRIPT` heredoc-artifact line from
    `hatdots-launch-terminal`; otherwise byte-identical, confirmed by
    diff), linked them from the `hypr` module, and moved their pairs
    from `internal/parity`'s `linuxDropped` to `linuxOmarchyOnlyPairs`.
    Noted, not changed: `hatdots-launch-terminal` still execs zsh while
    tmux's own default-shell is fish (phase-2 decision) — flagging the
    mismatch, not resolving it here.
  - **starship made optional/default-off** (`0d61dd7`): this machine's
    real `~/.config/starship.toml` is byte-identical to Omarchy's own
    default (`~/.local/share/omarchy/config/starship.toml`, confirmed
    with `diff`); `common/starship/starship.toml` is a Kanagawa variant
    that was never actually active anywhere (only `link-windows.ps1`
    ever linked it, for lack of any other prompt on Windows). Dropped
    `required = true`, added `default = false`, reworded the
    description. This directly resolves part of the open question
    above: starship is no longer required.
  - **kde default-selection per desktop** (`4f84951`): added
    `Module.NotDefaultDesktop`/`IsDefaultFor` and
    `domain.DefaultSelection(manifest, platform)`; wired the CLI so
    "no `--all`, no `--only`" now selects required modules plus
    `DefaultSelection`'s result (previously it selected only required
    modules, which made `default = true` purely informational — a
    second real gap this review caught). Set `kde`'s
    `not_default_desktop = ["omarchy"]` so it only auto-selects on a
    plain, non-Omarchy Linux desktop.
  - **backup-warning section** (`977e714`): `printPlan` now collects
    every `backup-then-link` destination and prints a
    "These files will be replaced (backup kept):" section before the
    y/N prompt (and in `--dry-run` output), so an overwrite is never
    buried in a long action list.
  RED/GREEN evidence (one per fix): hypr/launchers had no Go test (data
  files), verified instead with `luac -p` and `bash -n`/content diff
  against the live files. Launchers: moved the 3 pairs in
  `parity_test.go` first, reran
  `go test ./internal/parity/... -run TestParity_LinuxOmarchy`, saw it
  fail "old-script pair not covered" for all three, then added the
  hypr module links — GREEN. kde/default-selection: new domain tests
  (`TestModule_IsDefaultFor*`, `TestDefaultSelection_PerDesktop`) and a
  manifest test (`TestParse_NotDefaultDesktop`) failed to compile
  (unknown field/undefined func) before the code existed; a new CLI
  test (`TestRun_NoFlagsSelectsDefaultModulesNotEveryOptionalOne`)
  failed at runtime (default module not linked) before the CLI wiring
  — GREEN after each. Backup warning:
  `TestPrintPlan_WarnsAboutFilesThatWillBeReplaced` failed (no such
  section in stdout) before the change — GREEN after.
  Full verification (all observed): `go vet ./...` clean; `gofmt -l .`
  empty; `go test ./... -race -count=1` passes across all 8 packages;
  `GOOS=darwin`, `GOOS=windows`, `GOARCH=arm64 GOOS=darwin` builds all
  succeed. Two real dry-runs on this machine: `--all --dry-run --yes`
  → 32 actions (includes `starship` and `kde`, since `--all` always
  means every compatible module regardless of `default`), and a plain
  `--dry-run --yes` with no `--all`/`--only` → 29 actions (no
  `starship`, no `kde` — the actual default-selection behavior this
  fix was for). Both print the new backup-warning section (8 real
  files: `~/.config/ghostty`, `hypr/{bindings,autostart}.lua`, the 3
  launcher scripts, `.p10k.zsh`, plus `~/.config/starship.toml` only in
  the `--all` run). Before/after `ls -la ~/.config | md5sum` across
  both dry runs: identical (`a429c7cf8226bb80bd1e1ec641143bb5`) —
  confirmed nothing was ever touched. `git status --short` clean after
  every commit.
  Updated open question: the required set is now `{nvim, fish}`
  (`fish` linux-only) — `starship` is resolved (optional, default-off,
  per above); the user has not yet answered whether `{nvim, fish}` is
  the final required set, or whether to re-add the dropped
  newsboat-launcher hypr keybind.
- 2026-10-13: Phase 4a safety fixes, HEAD `7edf81b`, 6 commits
  (`5e708af`, `27a55c7`, `35118a5`, `deb43dd`, `4773491`, `7edf81b`).
  An independent adversarial review reported data-safety defects and
  reproduced 3 of them with probe tests; fixed in the order given,
  one commit each:
  1. **Backup collision** (`5e708af`): `linker.applyLink`'s backup name
     was second-resolution (`<dst>.hatdots-bak.<timestamp>`) and
     `os.Rename`d straight onto it — two backups of the same dst within
     the same clock second silently clobbered each other via
     rename-over-existing-file. Added `freeBackupPath`, which
     `os.Lstat`s the candidate and appends `-1`, `-2`, ... until free;
     Apply never renames onto an existing path. RED:
     `TestLinker_Apply_BackupThenLink_CollisionProofNaming` found only
     1 backup file (holding only the second original's content)
     instead of 2 before the fix. GREEN after.
  2. **Empty HOME → root paths** (`27a55c7`): `domain.ExpandPath` only
     checked `ok`, not whether the HOME value was non-empty, so a
     present-but-empty HOME turned `"~/x"` into `"/x"`; `main.go`'s
     `detectPlatform` always set `env["HOME"] = home` even when `home`
     itself was `""`. `ExpandPath` now returns `(string, error)` and
     errors on any unresolved-or-empty reference; `detectPlatform`
     never puts an empty HOME in `env` at all; `domain.BuildPlan` added
     `validateDst`, rejecting empty/relative/root/outside-home
     destinations (LOCALAPPDATA is the one documented exception, for
     nvim's Windows destination). RED: the domain package failed to
     build after `expand_test.go` was rewritten for the new signature;
     3 new `TestBuildPlan_Rejects*` cases were confirmed to fail by
     temporarily removing the `validateDst` call and rerunning them
     (3 failures), then restoring it. GREEN after.
  3. **Src containment** (`35118a5`): `manifest.validateSrcExists` only
     checked that `filepath.Join(repoRoot, src)` existed on disk, never
     that `src` itself stayed inside the repo — `src = "/etc/passwd"`
     or `src = "../../etc"` passed as long as something existed at the
     resolved path. Added `validateSrcContained`: after
     `filepath.Clean`, reject absolute or `../`-escaping src. RED: both
     new tests create the exact file the offending src would resolve
     to (so the only possible failure is the containment check, not a
     coincidental "missing src") and failed with "got nil" before the
     check existed. GREEN after.
  4. **Partial failure after backup** (`deb43dd`): if the link step
     failed right after a backup-then-link rename, the old code
     returned the bare link error — nothing named the backup, and nmo
     attempt was made to put the original back. Added
     `*BackupRestoreError` (names the backup path; tries
     `os.Rename(backup, dst)` automatically and reports whether that
     succeeded; when it didn't, its `Error()` spells out
     `mv <backup> <dst>`), wired through `applyLink` via an injected
     failing `dirStrategy` so the scenario is reproducible without a
     real broken filesystem. RED:
     `TestLinker_Apply_BackupThenLink_RestoresOriginalWhenLinkFails`
     failed to build (undefined: `BackupRestoreError`) before the type
     existed. GREEN after; the error message tests (restored vs
     not-restored wording) also pass.
  5. **Unverified `--repo` autodetection** (`4773491`): `findRepoRoot`
     accepted any directory with a file literally named `modules.toml`
     — no check it was actually a HatDots manifest. Added a required
     top-level `schema = "hatdots/v1"` marker
     (`manifest.Schema`/`HasSchemaMarker`); `findRepoRoot` now checks
     it at both the walk-up and executable-fallback steps and reports
     which one found the repo (`repoSource`). `runInstall` additionally
     requires confirmation specifically for the executable-fallback
     case: prints which repo was chosen, refuses under `--yes` (no one
     to confirm with), refuses without a TTY, otherwise asks y/N.
     `--repo` explicit and the ordinary walk-up case are unaffected;
     `list` stays confirmation-free (read-only). Added the schema line
     to the real `modules.toml` and every test fixture loaded through
     `manifest.Load`. RED: new manifest tests failed to build
     (undefined: `HasSchemaMarker`); the four new
     `TestRun_ExecutableFallback_*` CLI tests were confirmed to fail by
     temporarily stubbing out the confirmation block in `runInstall`
     and rerunning them (wrong exit code / no prompt in stdout), then
     restoring it. GREEN after.
  6. **Windows junction injection** (`7edf81b`): `mklinkJunction` execs
     `cmd /c mklink /J <dst> <src>`; cmd.exe re-parses `&`, `|`, `%`,
     `^` even inside a seemingly-quoted argument. Added
     `checkMklinkSafe` to the build-tag-free `strategy.go`, called by
     `windowsDirStrategy.link` after a failed symlink attempt and
     before invoking `mklinkJunction` — exercised by a plain Linux test
     via the already-injectable `mklinkJunction`. RED: 4 subtests
     (ampersand/pipe/percent/caret in src or dst) got no error and the
     junction fallback still ran, before the check existed. GREEN
     after; an ordinary path still reaches `mklinkJunction`.
  Full verification (all observed): `go vet ./...` clean; `gofmt -l .`
  empty; `go test ./... -race -count=1` passes across all 8 packages;
  `GOOS=darwin`, `GOOS=windows`, `GOARCH=arm64 GOOS=darwin` builds all
  succeed. Real dry-run on this machine,
  `go run ./cmd/hatdots --repo .. --dry-run --all --yes`: 32 actions,
  same shape as before these fixes (the backup-warning list still
  shows the same 8 real files). Before/after `ls -la ~/.config |
  md5sum`: identical (`df02ea2209939fa6d07746a55d3eeec8`) — confirmed
  nothing was ever touched. `git status --short` clean after every
  commit.
- 2026-10-12: Phase 4b done (P4-3 TUI, P4-4 release/bootstrap, P4-5
  remove old installers), HEAD `94efc94`, 5 commits (`e28e4b0` TUI +
  app.ApplyAction/PostInstallCommand export + old scripts deleted —
  see the staging-order note under task P4-5 above, `8de4898` launch
  on interactive terminals, `26fdd87` CI/release workflows + goreleaser
  config, `cf21f16` bootstrap scripts + asset-pair test, `94efc94`
  docs). New package `installer/internal/tui`: a Bubbletea presentation
  adapter over `internal/app` via a `Port` interface (`port.go`);
  screens `detect`/`select`/`preview`/`apply`/`result`
  (`model.go`/`screen_*.go`); terminal-suspending `tea.ExecProcess` for
  package-install/post-install actions (`exec.go`).
  RED/GREEN evidence (one line per task; full detail in each commit
  message):
  - `app.ApplyAction`/`app.PostInstallCommand`: `go test
    ./internal/app/...` failed to build (`undefined: a.ApplyAction,
    PostInstallCommand`) before they existed; GREEN after (11 cases,
    4 new).
  - TUI required-module lock: `TestUpdateSelect_SpaceCannotToggleRequiredModule`
    confirmed RED by temporarily removing the `!mod.Required` guard in
    `updateSelect`'s space case (space then toggled nvim) — restored,
    GREEN.
  - TUI result-screen bucketing: `TestSummarize_BucketsByKindAndFailure`
    confirmed RED by temporarily mapping `ActionBackupThenLink` into the
    `created` bucket instead of `backedUp` — restored, GREEN.
  - TUI apply-loop termination: `TestApply_DryRunCompletesWithoutTerminalCommandsAndReachesResult`
    confirmed RED by changing `runAction`'s base case to `idx >
    len(...)` (off-by-one) — panicked with an index-out-of-range
    reading `plan.Actions[idx]` one past the end — restored, GREEN.
  - Golden tests (`TestGolden_*`): failed with "no such file" before
    `-update` was ever run (no `testdata/*.golden` existed yet); GREEN
    after generating them and rerunning (5x in a row, byte-identical
    every time) without `-update`.
  - Result-screen bug found during the live tmux smoke run below (not
    from a pre-written test): package-install/post-install entries
    rendered as a blank line (`writeGroup` always read `a.Dst`, which
    only link-kind actions set). `TestViewResult_PackageInstallEntryShowsManagerAndPackages`
    written to reproduce it — failed (`viewResult()` contained `"  \n"`
    with no manager/package text) before the fix; GREEN after
    `writeGroup` took a `describe func(domain.Action) string` parameter
    (`linkPath` for the four link buckets, `describeAction` — already
    used by the preview screen — for packages/post-install).
  - `shouldLaunchTUI`/`runTUIFunc` (cmd/hatdots): `go test
    ./cmd/hatdots/...` failed to build (`undefined: shouldLaunchTUI`,
    `run` arg-count mismatch) before the 6th `run()` parameter
    (`isStdoutTTY`) and the new functions existed; GREEN after (9 new
    cases, including that `--dry-run` alone does NOT skip the TUI and
    `--yes` always does, even on a full TTY).
  - `bootstrap.sh`'s `hatdots_asset_pair`: `sh
    installer/scripts/test/test_asset_pair.sh` confirmed RED by mapping
    `aarch64`/`arm64` to `amd64` instead of `arm64` — 3 of 9 assertions
    failed with the wrong pair; restored, GREEN (all 9 pass).
  Full verification (all observed): `go vet ./...` clean; `gofmt -l .`
  empty; `go test ./... -race -count=1` passes across all 9 packages
  (new: `internal/tui`); `go test ./internal/tui/... -run TestGolden
  -count=5` byte-identical every run. Cross-builds: `GOOS=darwin
  GOARCH=amd64`, `GOOS=darwin GOARCH=arm64`, `GOOS=windows
  GOARCH=amd64`, `GOOS=linux GOARCH=arm64` all `go build ./cmd/hatdots`
  cleanly. `~/.local/bin/actionlint` (repo root, both new workflows,
  including its embedded shellcheck pass): clean, no output. `sh -n
  bootstrap.sh` and `bash -n bootstrap.sh`: clean. `sh
  installer/scripts/test/test_asset_pair.sh`: all 9 assertions pass.
  TUI smoke (real binary, real pty via `tmux`, `HOME` pointed at a temp
  dir with a fake `~/.config`, `--repo <this repo> --dry-run --os linux
  --desktop none`, driven with `tmux send-keys`/`capture-pane`):
  detect screen showed `OS: linux`, `Desktop: none`, `Package manager:
  pacman`, the real repo path; select screen showed `nvim`/`fish`
  locked+checked and the platform's default-selected optional modules
  (including `kde`, since `--desktop none` disables the
  Omarchy-only-exclusion); preview screen showed the plan grouped by
  module plus the backup-warning section with `Dry run: on` (seeded by
  `--dry-run`); result screen (pasted below) showed 15 created links and
  7 packages/post-install steps, each with its manager+packages or
  command text, zero failures. Real dry-run on this machine (not a fake
  HOME), `go run ./cmd/hatdots --repo .. --dry-run --all --yes`: same
  shape as phase 4a's. Before/after `ls -la ~/.config | md5sum`:
  identical across both the real-HOME dry run and (separately,
  confirmed via the fake-HOME tmux smoke never touching the real
  filesystem since `--dry-run` makes `TerminalCommands` unreachable and
  `ApplyAction` use the no-op executor) the TUI smoke — confirmed
  nothing was ever touched. `git status --short` clean after every
  commit.
  Unverified, and why: `.goreleaser.yaml` — `goreleaser` is not
  installed in this environment; checked against goreleaser's own docs
  (context7 MCP) and plain YAML parsing only, never a real
  `goreleaser check`/`--snapshot` build. `bootstrap.ps1` — `pwsh` is not
  installed in this environment; reviewed by hand against PowerShell
  5.1/7 syntax (comment-help placement, the reserved `$Args`/`$args`
  automatic-variable name avoided by renaming to `$ExtraArgs`, the
  `"$var:"` colon-after-variable parsing gotcha escaped as `` `: ``)
  instead of run. Neither `bootstrap.sh`'s nor `bootstrap.ps1`'s
  release-download/checksum-verification path has been exercised
  end-to-end against a real GitHub release, since `hat-y/HatDots` has
  no tags/releases published yet — only `hatdots_asset_pair`'s pure
  mapping function is test-covered; `ensure_repo`'s clone/update/refuse
  branches and the sha256-verify-then-extract-then-run path are
  reviewed but not run.

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
  in it now expands; superseded by the Go installer in phase 4. Note: that
  heredoc'd config is still a *different* file from `common/ghostty/config` —
  `common/ghostty/config` itself is still not linked by `link-linux.sh` (only
  its shaders dir, and now its `os.ghostty`/`omarchy.ghostty` overlay
  destinations are, as of phase 3 — see "Phase 3 decisions"). Phase 4
  replaces this installer; until then, Linux users who want
  `common/ghostty/config` itself need to link it by hand (see
  `os/linux/README.md`).
- ~~`HatLinux/fish/config.fish` hardcodes `/home/hat/.local/share/pnpm/bin`~~ —
  fixed in phase 2 (`common/fish/config.fish`, `$HOME`-based + existence-guarded).
- ~~tmux `default-shell` is zsh while the login shell on the Omarchy machine is
  fish~~ — fixed in phase 2 (prefers fish via `command -v`, falls back to `$SHELL`).
- ~~Omarchy dynamic theming... must be reintroduced under `os/omarchy` in
  phase 3~~ — done in phase 3 (task P3-5): `lua/config/omarchy_theme.lua` +
  `plugins/omarchy-theme-watch.lua` for Neovim, `os/omarchy/ghostty/
  omarchy.ghostty` for Ghostty (see "Phase 3 decisions").
- `link-windows.ps1` is not verified by the PowerShell parser in this
  environment (no `pwsh` installed); paths were checked to exist by hand.
  Same limitation phase 2 found; still true in phase 3.

## Phase 2 layout decisions

- **tmux**: `common/tmux/tmux.conf` = the phase-1-merged `terminals/tmux/tmux.conf`
  (already the agreed base), plus: the `?` Omarchy-keybindings-help bind was
  extracted to `os/omarchy/tmux/os.tmux.conf` (it hardcoded
  `omarchy-menu-tmux-keybindings`, an Omarchy-only command, and had no business
  being in a file meant for every OS). Dropped `HatLinux/tmux/.tmux.conf`
  (an older Catppuccin+CPU/RAM-status config, not linked by any installer —
  `link-linux.sh` has always linked `terminals/tmux/tmux.conf`/now
  `common/tmux/tmux.conf`) and `HatMac/tmux/tmux.conf` (same settings already
  resolved by the phase-1 merge: `escape-time 10`→0, the extra
  `copy-pipe-and-cancel` bind, the `unbind C-b` contradiction, and the
  confirm-before `K` override are all things phase 1 already decided against
  for the omarchy branch, and mac's file repeated the same patterns with no
  further unique setting). No `os/mac/tmux` overlay was created — nothing
  mac-specific survived the comparison.
- **ghostty**: `common/ghostty/config` is a fresh reconciliation of
  `terminals/ghostty/config` (old base, still doing dynamic Omarchy theming
  via `config-file`) against what `HatLinux/ghostty/config` and
  `HatMac/ghostty/config` had *both* independently drifted to — same Gentleman
  Theme palette, same dropped `confirm-close-surface`/`resize-overlay`/
  `gtk-toolbar-style`, same dropped native-split-resize keybinds (tmux/herdr
  own splits now), same dropped `cursor-style`/`shell-integration-features`/
  clipboard keybinds/performance tuning. Agreement from two independently
  edited files is strong signal that's the real intended config, so it won
  over the older base. OS-specific remainder: `command=`, `font-family`/
  `font-size`, `background-opacity-cells` → `os/mac/ghostty/os.ghostty`;
  `gtk-tabs-location`/`gtk-single-instance` (GTK-only, not Hyprland-specific)
  → `os/linux/ghostty/os.ghostty`. Dropped `HatLinux/ghostty/config` and
  `HatMac/ghostty/{config,shaders,themes}` outright (fully accounted for
  above; the mac shaders/themes dirs were byte-identical duplicates of
  `terminals/ghostty/{shaders,themes}`, now `common/`).
- **zsh**: `common/zsh/.zshrc` = `HatLinux/zsh/.zshrc` (explicitly the newest
  base) + Salesforce CLI aliases/completion folded in from `HatMac/zsh/.zshrc`
  (generic, guarded by `command -v sf`; justified because `HatLinux/nvim`
  already ships its own `lua/salesforce/*` plugin, so sf-the-CLI is plausibly
  wanted on Linux too, unlike the rest of mac's content). `os/mac/zsh/os.zsh`
  carries what's genuinely mac-only: Homebrew shellenv + Homebrew-path tool
  loading (fzf/autosuggestions/p10k/syntax-highlighting — mirrors, not
  replaces, common's own Linux-path attempts), `JAVA_HOME` for
  `brew openjdk@21`, NVM (deduped — the original had the same 4 lines twice),
  and the `STUDY_MATERIA` env var. **Dropped, not carried anywhere**: the
  `cdsf`/`hatsf`/`hatsfc` aliases (hardcoded to `~/projects/dapsa-sf/dapsa-sf`)
  — machine-specific per the existing constraint ("machine-specific values
  move to untracked local override files"); if wanted, they belong in the
  user's own untracked `~/.config/hatdots/local.zsh`, not in any tracked file.
  `HatMac/zsh/.p10k.zsh` was byte-identical to Linux's — single copy in
  `common/zsh/.p10k.zsh`, no diff to report.
- **fish**: `HatLinux/fish/config.fish` → `common/fish/config.fish` as-is,
  plus the pnpm path fix and overlay hooks. No `HatMac/fish` ever existed
  (fish isn't deployed on mac) and no omarchy-specific fish content exists,
  so no fish overlay files were created — just the hooks, ready for later.
- **newsboat**: `config`/`urls` are cross-platform except the single `browser`
  line (`xdg-open %u` vs `open %u`) — not drift, a hard per-OS necessity.
  Extended the same overlay pattern to newsboat via its own native `include`
  directive (not one of the four tools the pattern was scoped to, but the
  minimal correct fix — flagging the extension explicitly rather than hiding
  it). `urls` was byte-identical between OSes → one copy. The notifier script
  differs by more than one line (osascript vs notify-send, and Linux's calls
  `uwsm-app`) → kept as two full standalone scripts, `os/omarchy/newsboat/hat-news`
  (uwsm-app is Omarchy-only, so it's not `os/linux`) and `os/mac/newsboat/hat-news`.
- **herdr**: executed per the already-made decision — `common/herdr/config.toml`
  = `HatLinux/herdr/config.toml` + its README, `HatMac/herdr/config.toml`
  dropped outright. Mac-only settings lost: `[terminal] default_shell`,
  `onboarding = true` (vs common's `false`), `theme.name = "one-dark"` (vs
  common's `"kanagawa"`), `[session] resume_agents_on_restore`,
  `switch_workspace`, the `focus_agent`/`prefix+ctrl+1..9` vs common's
  `prefix+alt+1..9` choice, `[ui] sidebar_start_collapsed`/`status_indicators`,
  `[server]`/`[update]` tables, and both `[[keys.command]]` custom binds
  (`hat-news`, `open -a Obsidian`). `os/mac/herdr/{install.sh,
  com.user.herdr.plist.template,README.md}` kept as-is (just moved).
- **starship**: `shared/starship.toml` and `HatWindows/starship.toml` were
  byte-identical → one copy, `common/starship/starship.toml`.
- **wezterm**: kept `HatWindows/wezterm/wezterm.lua` (what `link-windows.ps1`
  actually uses) → `os/windows/wezterm/wezterm.lua`. Dropped
  `terminals/wezterm/wezterm.lua`: a Linux-shell-detecting draft (zsh/bash/
  fish launch menu, Linux fonts/OpenGLES) that no installer — not
  `link-linux.sh`, not anything else — has ever referenced; superseded/dead,
  not merely "different" from the Windows file.
- **kde/hypr**: `HatLinux/kde` → `os/linux/kde` (generic Linux desktop, not
  Hyprland-specific — KZones/KWin run under any Linux WM). `HatLinux/hypr` →
  `os/omarchy/hypr` (Hyprland-only by definition).
- **tmux scripts**: `terminals/tmux/tmux-work` → `common/bin/tmux-work`; dropped
  `HatMac/tmux/scripts/tmux-work`, a near-identical rewrite. Its `$HOME` fallback
  was NOT portable (on macOS every session opened in `$HOME`); fixed in `3897765`
  to fall back to `${PWD:-$HOME}`, matching the old mac behavior. `terminals/tmux/tmux-work-workspace` (calls `hyprctl`/
  `uwsm-app` unconditionally) → `os/omarchy/bin/`. `HatLinux/tmux/scripts/ghostty-tmux-new`
  (a documented migration-window compat shim, generic POSIX sh, no OS-specific
  calls) → `common/bin/ghostty-tmux-new`. `HatMac/tmux/scripts/ghostty-tmux-new`
  (a real, actively-linked mac implementation, zsh) → `os/mac/bin/ghostty-tmux-new`.
  `HatLinux/scripts/ghostty-multiplexer-new` → `common/bin/`.
- **Windows docs**: `API_KEYS.md`, `WEZTERM_GUIDE.md` → `os/windows/docs/`.
  `HatWindows/nvim/GEMINI.md` → `os/windows/docs/GEMINI.md` — explicitly
  instructed despite living under `nvim/`; it's a stray doc, not nvim config,
  so Neovim itself is unaffected. `HatWindows/nvim/.claude/` was **not**
  touched, as instructed.
- **READMEs**: `HatLinux/README.md` → `os/linux/README.md` (its own title says
  "Linux", not "Omarchy", and it documents generic-Linux content like KDE
  alongside Omarchy content — `os/linux` is the broader bucket of the two).
  `HatMac/README.md` → `os/mac/README.md`. Both had their structure-tree and
  path references updated to the new layout (not just the root README/SETUP).

## Phase 3 decisions

Base = `HatLinux/nvim` (phase 1 already made it the most complete copy).
Per-file comparison against Mac (`refs/remotes/origin/feat/harmac-config`)
and Windows (`refs/heads/work/linux-salesforce-herdr`, same branch as Linux
for date-comparison purposes — Windows's config lives on that same branch,
there's no separate Windows branch):

- **Identical across copies, no decision needed** (~20 files): `after/
  transparency.lua`, `.neoconf.json`, `lua/config/{autocmds,dap,
  markdown_utils,python,python-lsp,utils}.lua` (Windows's `utils.lua` was a
  strict subset, dropped), `lua/plugins/{all-themes,disable-news-alert,
  example,fff,img-clip,jupyter,luasnip,markdown(minus one AI line, see
  below),mini-surround,noice,snacks,snacks-animated-scrolling-off,telescope,
  vim-tmux-navigation,vimtex}.lua`, `luasnippets/obsidian.lua`, `plugin/
  after/transparency.lua`, `spell/*`, `stylua.toml`.
- **Linux was already a strict superset, kept verbatim** (no unique content
  lost from Mac/Windows, confirmed by direct comparison): `lua/config/
  keymaps.lua` (richer `toggleterm.Terminal:new()` API vs Mac's generic
  `:toggleterm` command — two distinct terminal behaviors, Mac's not a
  feature, a regression), `lua/plugins/{lsp,lazyextra,format,git}.lua`
  (Linux's `lsp.lua` already extracts `config.lsp_on_attach`, which is
  exactly what Mac's inline `on_attach` duplicated; Mac's `servers["*"]
  .capabilities` blink.cmp wiring is explicitly unneeded per Linux's own
  comment — LazyVim's blink extra already negotiates capabilities).
- **Union of real fixes/features, folded into Linux's file**:
  `lua/plugins/treesitter.lua` (added Mac's `apex`/`soql`/`sosl`/`sflog`
  parsers + `auto_install = true`, kept Linux's `java`/`tsx` entries and
  `prefer_git = true` — Mac's own comment calls its `prefer_git = false` a
  no-op), `lua/plugins/blink.lua` (added Mac's `fuzzy.implementation =
  "rust"`; did **not** fold Mac's `sources.providers.cmdline` entry or its
  `default`-preset keymap — Linux's `cmdline` block and `super-tab` keymap
  already cover the same ground, and Linux's `config` function strips a
  LazyVim-injected compat field Mac's simpler version doesn't handle),
  `lua/plugins/oil.lua` (added Windows's floating window + `<leader>E`,
  auto-save-on-leave, `.git` in `is_always_hidden`, sort/case_insensitive
  opts; did **not** fold Windows's `use_default_keymaps = false` + full
  custom keymap table — it restates oil.nvim's own documented defaults
  almost verbatim, so it changes nothing Linux doesn't already get for
  free), `lua/plugins/ui.lua` (added Windows's "Git Status" terminal pane in
  the snacks dashboard), `lua/plugins/obsidian.lua` (open_cmd and hunspell
  path now OS-aware via `has("macunix")` — Mac's own `<leader>onl`/`onk`
  "unique" keys turned out to already be covered by `hatnotes.creation`'s
  shared `creation.keys`, so nothing else needed folding).
- **Restructured into cross-platform files** (genuinely OS-specific code,
  per the task's own instruction, instead of three near-duplicate files):
  `init.lua` (one `if is_linux / elseif is_mac / elseif is_windows` dispatch;
  dropped the old `shared/nvim` runtimepath-append hack, see below) and
  `lua/config/options.lua` (clipboard + shell now branch on
  `vim.fn.has(...)`/`vim.fn.executable(...)` inside one file instead of
  three OS-named files; Linux's generic perf/search/split/LSP settings,
  which Mac's older `options.lua` never had, are now unconditional for
  every OS — a fold-in, not an OS branch).
- **Resolved conflicts, kept Linux, documented the loss**:
  `lua/plugins/colorscheme.lua` — Linux's version is an intentional,
  fully-commented-out "kept for reference" file (its own comment says the
  active theme lives in `theme.lua`); Mac/Windows instead set a second,
  colliding `LazyVim.opts.colorscheme` (`oxocarbon`/`kanagawa`). Dropped
  Mac/Windows's active versions — nothing unique lost, both themes already
  exist as Linux's own commented reference entries. `lua/plugins/
  which-key-groups.lua` — kept Mac's generic `[H]erdr` group (guarded the
  one macOS-only `open -a` keymap with `has("macunix")`); dropped its
  Salesforce `<leader>S*` group entirely — direct key collision (`So`, `Sp`,
  `Sr`, `St`, `SO`, ...) with the active `lua/salesforce/*` module, which
  already owns that whole namespace.
- **AI plugins removed** (task P3-2, user decision): `zbirenbaum/
  copilot.lua` and `supermaven-inc/supermaven-nvim` were active (Linux/Mac);
  `yetone/avante.nvim`, `coder/claudecode.nvim` and `marcinjahn/
  gemini-cli.nvim` were Windows-only. `olimorris/codecompanion.nvim`,
  `CopilotC-Nvim/CopilotChat.nvim` and `sudo-tee/opencode.nvim` were already
  inert (`enabled = false`) everywhere and untouched. All are now listed,
  force-disabled, in `disabled.lua`. Cleaned up the stray references that
  pointed at the removed plugins: the `supermaven-nvim` `lazy-lock.json`
  pin, the `<leader>mu` which-key hint in `markdown.lua`, and two whole docs
  that were nothing but AI-plugin setup instructions —
  `os/windows/docs/API_KEYS.md` and `GEMINI.md` — plus the one SETUP.md
  section pointing at `API_KEYS.md`. Windows's `cmp.lua` (nvim-cmp) was
  dropped outright: pure cmp config, no non-cmp content, and the rest of
  this config uses blink.cmp.
- **Mac-only generic plugins**: `smear-cursor.nvim` brought in but
  `enabled = false` by default — Ghostty already runs its own cursor-smear
  shader (`custom-shader = shaders/cursor_smear_gentleman.glsl`), so
  enabling both would smear the cursor twice. `fzf-lua.lua` and
  `overseer.lua` were **not** brought in as generic utilities: both files'
  own comments say their only purpose is serving `xixiaofinland/sf.nvim`
  (fzf-lua for its metadata picker, overseer for its async terminal), so
  they were parked alongside it instead (see Salesforce below) rather than
  activated with no consumer.
- **Salesforce (task P3-3, decided)**: initially parked Mac's `xixiaofinland-
  sf.lua`, `apex_ls.lua`, `fzf-lua.lua` and `overseer.lua`; the user then
  chose sf.nvim over the custom Linux module (see task P3-3 above for the
  restore, deletion and verification detail — commit `b883cee`).
- **`shared/nvim` → `common/nvim`**: `lua/hatnotes/` and `tests/` moved in
  directly (`git mv`); removed the `vim.opt.runtimepath:append(.../shared/
  nvim)` hack from `init.lua` and the `performance.rtp.reset = false` it
  required, now that hatnotes lives under this config's own `lua/` dir
  (already on the default runtimepath). Verified via the full isolated
  startup check (`HATNOTES true`) and the existing `creation_smoke.lua`
  test, still GREEN.
- **Omarchy theme following (task P3-5)**: see that task above for the
  module design and RED/GREEN evidence. Layer-naming fix alongside it: on
  an Omarchy machine both `os/linux` and `os/omarchy` overlays apply, so
  they needed separate overlay targets instead of sharing `os.*` — see the
  "Overlay files" table below (renamed `os/omarchy/tmux/os.tmux.conf` →
  `omarchy.tmux.conf`, added `os/omarchy/ghostty/omarchy.ghostty`, wired a
  third `omarchy.*` layer into every common config's overlay chain).
- **`lazyvim.json`**: already a clean union from phase 1 (dap.core,
  lang.angular, lang.docker, lang.prisma, lang.python, lang.rust,
  lang.typescript) with no AI extras in it; no change needed.

## Overlay files (for the phase-4 installer manifest)

Three layers per common config, loaded in order: `os.*` (linux/mac/windows)
-> `omarchy.*` (desktop environment, only linked where it applies) ->
`local.*` (untracked, machine-specific).

| Overlay file | Link target | Linked by |
|---|---|---|
| `os/linux/ghostty/os.ghostty` | `~/.config/hatdots/os.ghostty` | `link-linux.sh` (added phase 3) |
| `os/mac/ghostty/os.ghostty` | `~/.config/hatdots/os.ghostty` | `link-mac.sh` (added) |
| `os/mac/zsh/os.zsh` | `~/.config/hatdots/os.zsh` | `link-mac.sh` (added) |
| `os/linux/newsboat/os.newsboat` | `~/.config/hatdots/os.newsboat` | now wired by the phase-4 `modules.toml` `newsboat` module (was unlinked by any script through phase 3) |
| `os/mac/newsboat/os.newsboat` | `~/.config/hatdots/os.newsboat` | `link-mac.sh` (added) |
| `os/omarchy/tmux/omarchy.tmux.conf` | `~/.config/hatdots/omarchy.tmux.conf` | `link-linux.sh` (renamed from `os.tmux.conf`, see Phase 3 decisions) |
| `os/omarchy/ghostty/omarchy.ghostty` | `~/.config/hatdots/omarchy.ghostty` | `link-linux.sh` (added phase 3) |

Both omarchy.\* links are gated on `~/.local/share/omarchy` existing (same
marker `lua/config/omarchy_theme.lua`'s `is_omarchy()` checks).

No fish overlay files exist yet (none needed); `common/fish/config.fish`,
`common/zsh/.zshrc`, `common/tmux/tmux.conf` and `common/ghostty/config` all
have `os.*`/`omarchy.*`/`local.*` hooks ready for when one is (zsh/fish
`omarchy.*` added in phase 3 for symmetry, unused so far).

## Next step

Phase 4 is complete: 4a (module manifest schema+parser, platform
detection, plan builder, linker, package adapters, non-interactive CLI,
real `modules.toml`, parity tests against the three old scripts) and 4b
(Bubbletea TUI, release workflow + goreleaser config, bootstrap
scripts, old `link-*.sh`/`.ps1` removed) — see `installer/README.md`
and both progress entries above for full detail, open questions, and
known deviations/unverified items (`.goreleaser.yaml` and
`bootstrap.ps1` are reviewed but not run, since neither `goreleaser`
nor `pwsh` is installed in this environment, and the bootstrap
scripts' release-download path has never run against a real GitHub
release since none is published yet).

**Phase 5 — Close**: user verifies macOS and Windows (this environment
is Linux/Omarchy only), then decides whether/when to merge `unify` into
`main` and delete the obsolete branches. Nothing else is blocking that
decision from this side.
