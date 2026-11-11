# HatDots installer

A small, cross-platform, hexagonal Go program that replaces
`link-linux.sh`, `link-mac.sh` and `link-windows.ps1` with one declarative
module manifest (`modules.toml` at the repo root) and one binary.

Phase 4a shipped the core: manifest parsing, platform detection,
planning, linking, package-manager adapters, and a non-interactive CLI.
Phase 4b (done) adds the Bubbletea TUI (`internal/tui`, launched
automatically on an interactive terminal — see `cmd/hatdots/main.go`'s
`shouldLaunchTUI`), the release workflow (`.goreleaser.yaml`,
`.github/workflows/release.yml`/`installer-ci.yml`), and the bootstrap
scripts (`bootstrap.sh`/`bootstrap.ps1` at the repo root) that download
and run a release build. The three old shell/PowerShell scripts are gone;
see `odd/tasks/hatdots-unify.md`'s Phase 4b section for the parity
evidence that preceded their removal.

## Architecture

```
internal/domain     pure core: Module/Link/PackageSpec/PostInstall/Platform/
                     Manifest/Plan/Action types + BuildPlan. No I/O.
internal/manifest    parses and validates modules.toml into domain types.
internal/platform     adapter: detects OS, Omarchy, Linux distro, pkg manager.
internal/linker        adapter: applies link actions to the real filesystem;
                     implements domain.FSState for planning.
internal/pkg            adapter: builds and runs package-manager install commands.
internal/app              use cases: Load, Plan, Apply — wires the above together.
internal/parity              acceptance test: the real manifest's plan is a
                     superset of what the three old scripts created.
cmd/hatdots                 the CLI.
```

`domain.BuildPlan` never touches disk: it takes an `FSState` port (what's
already at a destination) and a `Platform` (OS/desktop/package
manager/env) as plain data, so the whole planning algorithm is tested
with in-memory fakes. `internal/linker.FSState` and `internal/linker.Linker`
are the real adapter; `internal/app` is the only place that wires the real
adapters to the domain core for the CLI.

## modules.toml schema

One `[[modules]]` table per module:

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Unique, used by `--only` and `list`. |
| `name`, `description` | string | Shown by `list` and in the plan. |
| `required` | bool | Always installed on every OS/desktop it supports (never has to be selected). |
| `default` | bool | Whether the module is pre-selected (in addition to required modules) when neither `--all` nor `--only` is given, and by the TUI's select screen (its optional modules start checked exactly when `Module.IsDefaultFor` is true). See `Module.IsDefaultFor`/`domain.DefaultSelection`. |
| `not_default_desktop` | list of `"omarchy"` | Desktops where this module should NOT be default even though `default = true` (e.g. `kde` must not auto-apply on Omarchy, which owns its own desktop config via the `hypr` module). |
| `os` | list of `"linux"`/`"mac"`/`"windows"` | Which OSes the module applies to at all. Empty = every OS. |
| `desktop` | list of `"omarchy"` | Which desktop environments the module needs. Empty = any (including none). |
| `[[modules.links]]` | array of tables | See below. |
| `[modules.packages]` | table of `<manager> = [names...]` | Package names per manager: `pacman`, `aur`, `apt`, `dnf`, `zypper`, `brew`, `winget`, `scoop`. For `pacman`/`aur`, names already satisfied (including through `provides`, e.g. `neovim-git` satisfies `neovim`) are skipped via `pacman -T` before anything is installed. |
| `[modules.casks]` | table of `<manager> = [names...]` | Same shape as `packages`, but installed with Homebrew's `--cask` (only `brew` is meaningful here). |
| `[[modules.post_install]]` | array of tables | A declarative, shown-in-the-plan command: `command` (either a path to a script tracked in the repo, resolved relative to the repo root, or a literal shell command), plus optional `os`/`desktop` filters. |

### Links

```toml
[[modules.links]]
src = "common/tmux/tmux.conf"   # repo-relative; must exist (validated).
dst = "~/.config/tmux/tmux.conf" # "~" and "$VAR"/"${VAR}"/"%VAR%" expand.
dst_mac = "~/.tmux.conf"         # override dst for one OS; dst_linux/dst_windows also exist.
os = ["linux", "mac"]            # optional: restrict this LINK (not the whole module) to these OSes.
desktop = ["omarchy"]            # optional: restrict this link to a desktop.
```

This is how one module expresses the `os.*`/`omarchy.*`/`local.*` overlay
layers (see below) without being split into per-OS modules: give the
shared bits one link with no `os`/`desktop` filter, and each OS- or
desktop-specific bit its own `[[modules.links]]` entry.

### Overlay layers

Three layers per common config, loaded in the order `os.*` ->
`omarchy.*` -> `local.*` (untracked, machine-specific, never part of the
manifest). `os.*` is generic for that OS; `omarchy.*` only applies on an
Omarchy machine (same `~/.local/share/omarchy` marker
`platform.DetectOmarchy` checks) on top of `os.linux`. See the per-module
`[[modules.links]]` entries with `os`/`desktop` filters in `modules.toml`
for exactly which files implement which layer.

### Required/optional, provisional

`nvim` (all OS) and `fish` (Linux) are `required = true` per the user's
own provisional instruction for this phase — **still open for the user
to confirm**. `starship` was also provisionally required in the first
draft, but a live-machine check found this Linux box's real
`~/.config/starship.toml` is byte-identical to Omarchy's own default
(`~/.local/share/omarchy/config/starship.toml`), while
`common/starship/starship.toml` is a Kanagawa variant that was never
actually active anywhere (Windows was the only old script that ever
linked it, only because nothing else provided a prompt there); macOS's
own `os/mac/Brewfile` also deliberately comments starship out in favor
of `powerlevel10k`. Making it required would have silently replaced a
live, working prompt with an unrequested theme on first install, so
`starship` is now optional with `default = false` — selecting it is an
explicit opt-in. Every other module is optional; `default = true` marks the
modules at least one of the three old scripts installed unconditionally
on an OS it supports.

### Known deviations from the old scripts (all supersets, not regressions)

- **ghostty**: now linked as a whole directory
  (`common/ghostty` -> `~/.config/ghostty`) on both Linux and macOS, not
  just `shaders/` on Linux. This resolves the phase-3 tracker's own
  documented issue that `common/ghostty/config` was never linked on
  Linux; see `modules.toml`'s `ghostty` module and
  `installer/internal/parity`'s `linuxDropped` for the exact reasoning.
- **p10k on Linux**: `link-linux.sh` *copied* `~/.p10k.zsh`
  (`safe_copy`, not a symlink) if the file existed; this manifest
  symlinks it instead (like `link-mac.sh` already did), so edits to the
  tracked file take effect without rerunning the installer.
- **Three heredoc-generated scripts** (`hatdots-launch-terminal`,
  `hatdots-launch-terminal-tmux`, `tmux-session-layout`) and the
  heredoc-generated `~/.config/ghostty/config` are **not** reproduced:
  the generated ghostty config is superseded by the tracked
  `common/ghostty/config` (linked directly); the launcher scripts are
  superseded by the tracked `common/bin/ghostty-multiplexer-new`, which
  `common/ghostty/config`'s own `command =` line already invokes. The
  hardcoded 3-window tmux layout itself was never promoted to a tracked
  file and is superseded by Herdr (see
  `openspec/changes/add-herdr-multiplexor`), now the primary multiplexer.
- **newsboat extended to Linux**: `link-linux.sh` never linked newsboat
  at all (the phase-3 tracker's overlay table explicitly flagged
  `os/linux/newsboat/os.newsboat` as prepared-but-unwired); this manifest
  wires it up for both OSes it has tracked content for. Non-Omarchy Linux
  desktops still have no tracked `hat-news` notifier script — a
  pre-existing gap, not introduced here.
- **`os/linux/kde/config/kglobalshortcutsrc-kzones`** is intentionally
  **not** linked: it is a partial fragment meant to be merged into the
  user's real `~/.config/kglobalshortcutsrc` (which holds many unrelated
  app shortcuts), not a whole-file replacement — `os/linux/README.md`'s
  own manual instructions only ever symlinked `kwinrc` for the same
  reason.
- **AUR packages**: `platform.DetectPkgManagerFor` detects an available
  AUR helper (`yay`/`paru`), but `internal/app.Apply` does not currently
  thread it through to package-install actions, and no module in this
  manifest needs an AUR-only package. `pkg.BuildCommands` fully supports
  `domain.AUR` already; wiring the detected helper through is a small
  follow-up if a future module needs it.
- **Windows file-link fallback**: the task's directory-link fallback
  (symlink -> NTFS junction via `cmd /c mklink /J`) is implemented; the
  old `link-windows.ps1`'s additional hardlink fallback for plain *files*
  (not directories) is not replicated. Modern Windows with Developer Mode
  enabled (or an elevated process) creates file symlinks without issue;
  this is a known, low-risk gap versus the old script.

## CLI

```
hatdots list [--repo <path>]
hatdots [--repo <path>] [--all] [--only id1,id2] [--dry-run] [--yes]
        [--os linux|mac|windows] [--desktop omarchy|none]
```

`--repo` defaults to walking up from the current directory to find
`modules.toml`, falling back to the directory next to the running
executable (the layout a bootstrap/release install produces). Without a
TTY on stdin, or with `--yes`, the plan is applied without prompting;
with a TTY and neither flag, it asks `y/N` first. `--os`/`--desktop` are
hidden overrides for planning and tests — normal use auto-detects both.

Selection: `--all` selects every module compatible with the platform.
`--only id1,id2` selects exactly those (plus required modules; nothing
else). With **neither** flag, the default selection is required modules
plus every optional module with `default = true` for this platform's
desktop (`domain.DefaultSelection`) — not every optional module. This
mirrors what the three old scripts actually installed without any flags,
so a plain `hatdots` run doesn't silently opt a machine into something
new (see `starship`'s `default = false` above).

The plan always prints a **"These files will be replaced (backup kept)"**
section listing every destination that will go through
`backup-then-link` (a real file or directory already there, not a
symlink) before asking for confirmation, so an overwrite is never a
surprise.

## TUI

`internal/tui` is a Bubbletea presentation adapter over `internal/app` —
it contains no business logic of its own; every decision (default
selection, plan contents, package commands) is made by `internal/domain`,
`internal/app`, or `internal/pkg` and only rendered/dispatched here. Five
screens, in order: **detect** (OS/desktop/package manager/repo) ->
**select** (required modules shown checked and locked; optional modules
toggle with space, `a` toggles all optional; unsupported-on-this-platform
modules are hidden) -> **preview** (the plan grouped by module, a
"These files will be replaced" section, package/post-install commands
listed, `d` toggles dry-run) -> **apply** (spinner/progress per action;
package-install and post-install commands that may need an interactive
terminal — e.g. a sudo password prompt — run through `tea.ExecProcess` so
the TUI suspends itself around them, see `internal/tui/exec.go`) ->
**result** (created/replaced/backed-up/skipped/failed, with recovery
hints for any failure).

Applying is a distinct, explicit action: the preview screen's hint reads
`y: apply · d: toggle dry run · esc: back`, and **`enter` is a no-op**
there — only `y` starts applying, so browsing the preview (even bumping
enter a few times) can never trigger it by accident
(`updatePreview`/`TestRapidEnterFromDetect_NeverReachesApply`). When
`--dry-run` was given on the command line, dry-run is authoritative:
`tui.WithInitialDryRun(true)` also locks the toggle, so `d` on the
preview screen can no longer turn it back off (shown as `Dry run: on
(locked by --dry-run)`); without `--dry-run`, `d` still freely toggles.
The apply and result screens label themselves truthfully for a dry run
— titles gain `" (dry run)"` and the result screen's buckets say "Would
create"/"Would replace"/"Would back up (backup kept)"/"Would run
(packages / post-install)" instead of the real-apply past tense (see
`resultLabels` in `screen_result.go`).

`cmd/hatdots` launches the TUI (`shouldLaunchTUI` in `main.go`) when both
stdin and stdout are real terminals and `--yes` was not given; `--dry-run`
does **not** suppress the TUI (it seeds — and locks — the preview
screen's own dry-run toggle instead), so a dry run on a real terminal
still gets the full interactive experience. `--all`/`--only` seed the
select screen with the same selection the non-interactive path would use
(`selectionFromFlags`; `tui.WithInitialSelection`), and the user can still
adjust it there. An unknown or incompatible `--only` id fails before the
TUI opens, with the same error as the non-interactive path.

Tests: `internal/tui/model_test.go` drives `Model.Update` directly against
a fixed, synchronous fake `Port` (`fake_port_test.go`) for state
transitions, key handling, the required-module lock, and default
selection; `internal/tui/golden_test.go` uses `teatest` to drive a real
`tea.Program` through each screen (fixed 80x24 terminal size, a colorless
lipgloss profile, and `WithoutAnimation()` to keep the spinner from racing
a real-time ticker) and golden-compares the full rendered transcript —
committed under `internal/tui/testdata/`.

## Release and bootstrap

`.goreleaser.yaml` (repo root) builds `hatdots` for linux/amd64,
linux/arm64, darwin/amd64, darwin/arm64, and windows/amd64 from
`installer/` (`builds[].dir`), archiving each as `.tar.gz` (`.zip` on
Windows) plus one `checksums.txt`. `goreleaser` itself is not installed
in this environment — the file's structure was checked against
goreleaser's own docs (fetched through the context7 MCP) and basic YAML
syntax, but never run through a real `goreleaser check`/`--snapshot`
build; treat it as **unverified** until a maintainer runs one.

`.github/workflows/release.yml` runs the installer's test suite, then
`goreleaser release --clean`, on every `v*` tag push.
`.github/workflows/installer-ci.yml` runs `go vet`, a `gofmt` check,
`go test -race`, and cross-builds (darwin amd64/arm64, windows amd64,
linux arm64) on every PR/push touching `installer/**` or `modules.toml`.
Both are `actionlint`-clean.

`bootstrap.sh` (POSIX sh, Linux/macOS) and `bootstrap.ps1` (Windows, not
verified against a real `pwsh` — none is installed in this environment,
reviewed by hand instead) clone or update the repo into
`${HATDOTS_DIR:-$HOME/projects/HatDots}` (`$env:HATDOTS_DIR` or
`$HOME\projects\HatDots` on Windows), refusing to touch an existing
directory that isn't already a HatDots clone; download the latest release
asset for the detected OS/arch, verify its sha256 against the release's
`checksums.txt` (aborting on a mismatch), extract it, and run `hatdots
--repo <dir>` with any passed-through arguments. With no release
published yet and `go` available, both fall back to `go run
./installer/cmd/hatdots`. The OS/arch -> asset-name mapping is a small,
independently testable function in each script
(`hatdots_asset_pair`/`Get-HatdotsAssetPair`);
`installer/scripts/test/test_asset_pair.sh` exercises bootstrap.sh's
version directly (`sh installer/scripts/test/test_asset_pair.sh`).
