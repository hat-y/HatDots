# HatDots installer

A small, cross-platform, hexagonal Go program that replaces
`link-linux.sh`, `link-mac.sh` and `link-windows.ps1` with one declarative
module manifest (`modules.toml` at the repo root) and one binary.

Phase 4a (this package) ships the core: manifest parsing, platform
detection, planning, linking, package-manager adapters, and a
non-interactive CLI. Phase 4b adds the Bubbletea TUI, a release workflow,
and bootstrap scripts, and removes the three shell/PowerShell scripts.

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
| `default` | bool | Whether the module the three old scripts installed by default on at least one OS it covers; informational for now, meant for the phase-4b TUI's pre-selection. Has no effect on `BuildPlan`/`--all`/`--only`. |
| `os` | list of `"linux"`/`"mac"`/`"windows"` | Which OSes the module applies to at all. Empty = every OS. |
| `desktop` | list of `"omarchy"` | Which desktop environments the module needs. Empty = any (including none). |
| `[[modules.links]]` | array of tables | See below. |
| `[modules.packages]` | table of `<manager> = [names...]` | Package names per manager: `pacman`, `aur`, `apt`, `dnf`, `zypper`, `brew`, `winget`, `scoop`. |
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

`nvim`, `fish`, and `starship` are `required = true` per the user's own
provisional instruction for this phase — **open question for the user**:
confirm this set, especially `starship`, since macOS's own
`os/mac/Brewfile` deliberately comments starship out in favor of
`powerlevel10k` (now both get linked/installed on mac under this
manifest; nothing stops both running, but only one can own the prompt in
`.zshrc`, so this may be worth resolving explicitly rather than leaving
both active). Every other module is optional; `default = true` marks the
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
