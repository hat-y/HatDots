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
  heredoc'd config is a *different* file from `common/ghostty/config` — the
  installer never linked a ghostty config file before phase 2, only the
  shaders dir, so `common/ghostty/config`'s new os/local overlay hooks are
  not yet wired for Linux specifically (they are for mac). Phase 4 replaces
  this installer; until then, Linux users who want the overlay need to link
  `common/ghostty/config` by hand (see `os/linux/README.md`).
- ~~`HatLinux/fish/config.fish` hardcodes `/home/hat/.local/share/pnpm/bin`~~ —
  fixed in phase 2 (`common/fish/config.fish`, `$HOME`-based + existence-guarded).
- ~~tmux `default-shell` is zsh while the login shell on the Omarchy machine is
  fish~~ — fixed in phase 2 (prefers fish via `command -v`, falls back to `$SHELL`).
- Omarchy dynamic theming (symlink-based `theme.lua` sourcing
  `/home/hat/.config/omarchy/current/theme/neovim.lua`) was dropped in the merge in
  favor of the work branch's regular-file `theme.lua`; must be reintroduced under
  `os/omarchy` in phase 3. Same situation found for **Ghostty** in phase 2: both
  `HatLinux/ghostty/config` and `HatMac/ghostty/config` had already abandoned
  Ghostty's own dynamic-omarchy-theme `config-file` line in favor of a shared
  static "Gentleman Theme" palette (both OSes agreed independently) —
  `common/ghostty/config` now ships that static palette; dynamic Omarchy
  theming for Ghostty is not reintroduced anywhere (no `os/omarchy/ghostty`
  overlay exists). Flagging as a possible follow-up, not done without asking.
- `link-windows.ps1` is not verified by the PowerShell parser in this
  environment (no `pwsh` installed); paths were checked to exist by hand.

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
- **tmux scripts**: `terminals/tmux/tmux-work` (uses
  `omarchy-cmd-terminal-cwd 2>/dev/null` with a graceful `$HOME` fallback —
  already portable) → `common/bin/tmux-work`; dropped `HatMac/tmux/scripts/tmux-work`,
  a near-identical rewrite with a different (also fine) cwd-detection style and
  nothing else unique. `terminals/tmux/tmux-work-workspace` (calls `hyprctl`/
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

## Overlay files (for the phase-4 installer manifest)

| Overlay file | Link target | Linked by |
|---|---|---|
| `os/omarchy/tmux/os.tmux.conf` | `~/.config/hatdots/os.tmux.conf` | `link-linux.sh` (added) |
| `os/linux/ghostty/os.ghostty` | `~/.config/hatdots/os.ghostty` | not yet linked (see Known issues) |
| `os/mac/ghostty/os.ghostty` | `~/.config/hatdots/os.ghostty` | `link-mac.sh` (added) |
| `os/mac/zsh/os.zsh` | `~/.config/hatdots/os.zsh` | `link-mac.sh` (added) |
| `os/linux/newsboat/os.newsboat` | `~/.config/hatdots/os.newsboat` | not yet linked (Linux never linked newsboat before) |
| `os/mac/newsboat/os.newsboat` | `~/.config/hatdots/os.newsboat` | `link-mac.sh` (added) |

No fish overlay files exist yet (none needed); `common/fish/config.fish`
already has the `os.fish`/`local.fish` hooks ready for when one is.

## Next step

Phase 3: single Neovim (merge the three copies, OS-conditional plugin
imports, remove AI plugins, Salesforce comparison, one `lazy-lock.json`).
Also carries forward from phase 2: decide whether Ghostty needs its own
Omarchy dynamic-theme overlay (see Known issues).
