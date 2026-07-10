# Proposal — Add Herdr as Linux Multiplexer (Herdr default, Tmux fallback)

**Change**: `add-herdr-multiplexor`
**Project**: `hatdots`
**Artifact store**: engram (primary, `sdd/add-herdr-multiplexor/proposal`) + openspec mirror (`openspec/changes/add-herdr-multiplexor/proposal.md`)
**Status**: proposal → awaiting spec
**Author**: orchestrator (sdd-proposal subagent completed exploration phase successfully but persistence failed; content composed here from full context: exploration notes id 137, two-round user decisions, sdd-proposal acceptance-report)

---

## 1. Why now / business problem

HatDots is a personal dotfiles repo that already runs multi-agent AI coding sessions daily (Claude Code, OpenCode, Codex, Pi). The current Linux multiplexer setup is **Tmux 2.0+ with TPM plugins**, configured in `HatLinux/tmux/.tmux.conf` (Catppuccin Mocha, prefix `Ctrl+Space`) and hard-launched by `HatLinux/ghostty/config` via `command = /usr/bin/tmux ...`.

That setup is **misaligned with the actual workload**:

- Tmux is a general-purpose session manager from 2007. It has no concept of "agent" or "PTY state for an AI coding tool."
- HatDots already ships LazyVim with `avante`, `codecompanion`, `claude-code`, `copilot`, `copilot-chat`, `opencode`, `gemini` plugins. The terminal layer beneath them is blind to that.
- The Gentleman.Dots upstream — a curated, reviewed dotfiles repo by the same author of this harness — adopted **Herdr** (`ogulcancelik/herdr`, v0.4.x, ~14.6k stars, Rust ~10MB binary, PTY-based, agent-focused) as a first-class multiplexer option alongside Tmux and Zellij. Adopting the same pattern in HatDots reduces drift between personal projects and keeps AI workflows first-class.

This change closes that gap by making Herdr the **default** multiplexer on Linux while keeping Tmux as a **graceful fallback** when Herdr is not installed.

---

## 2. Target users / situations

**Helps when:**
- Running two or more AI coding agents in parallel (Claude Code + Codex, or Pi + OpenCode).
- Wanting at-a-glance agent status (Herdr shows `blocked` / `working` / `done` per pane).
- SSH-ing into a remote box and resuming an agent session (Herdr supports detach/reattach).
- Mouse-first interaction is acceptable or preferred.

**Does NOT help when:**
- Single-terminal workflows with no AI agents (Tmux + cat is enough).
- User has muscle memory for Tmux keybindings and refuses to learn new ones.
- Windows without WSL (Herdr has no native Windows binary).
- Hard requirement for a non-NOASSERTION license (Herdr's license field is `NOASSERTION` — surface this caveat).

---

## 3. Current-state gap vs desired state

### Before (today)

| Layer | Behavior |
|---|---|
| Ghostty launches | `command = /usr/bin/tmux -f ~/.tmux.conf new-session -A -s main` (hardcoded) |
| Shell auto-start | None. `.zshrc` has no multiplexer guard. |
| Fish shell | Not configured in HatDots at all. |
| Tmux session creation | `HatLinux/tmux/scripts/ghostty-tmux-new` (called via `bind N` in `.tmux.conf`) creates `ghostty-$NAME` session with 2 windows (nvim + shell). |
| Agent awareness | None. Tmux doesn't know about Claude Code / Codex. |

### After (this change)

| Layer | Behavior |
|---|---|
| Ghostty launches | `command = ~/.local/bin/ghostty-multiplexer-new main` — wrapper detects Herdr binary; uses Herdr session API if present, else falls back to Tmux (mirroring current `ghostty-tmux-new` behavior). |
| Zsh auto-start | `HatLinux/zsh/.zshrc` gains an auto-start guard: if `command -v herdr` && not in TMUX/ZELLIJ/HERDR_ENV, start Herdr; else if `command -v tmux` && not in TMUX/ZELLIJ/HERDR_ENV, start Tmux. |
| Fish shell | `HatLinux/fish/config.fish` added — full GentlemFish port: auto-start guard, starship, zoxide, atuin, carapace, vi-mode, Pi-matching colors, aliases. |
| Session creation | `HatLinux/scripts/ghostty-multiplexer-new` replaces `HatLinux/tmux/scripts/ghostty-tmux-new`. Multiplexer-aware wrapper. |
| Agent awareness | Herdr's PTY-based status detection is exposed by default (when Herdr is the active multiplexer). Tmux fallback path is unchanged. |

---

## 4. Scope boundaries (first slice)

### NEW files (4)
- `HatLinux/herdr/config.toml` — Pi-matching palette (panel_bg `#06080f`, accent `#6FA0AF`, green `#B7CC85`, blue `#6FA0AF`, red `#CB7C94`, yellow `#DEBA87`); prefix `ctrl+a`; `previous_agent = "prefix+alt+k"`; `next_agent = "prefix+alt+j"`; `focus_agent = "prefix+ctrl+1..9"`. Ported from `Gentleman.Dots/herdr/config.toml`.
- `HatLinux/herdr/README.md` — concise docs for this folder (palette rationale, keybinding reference, install command hint).
- `HatLinux/fish/config.fish` — full GentlemFish port (~100 lines). Auto-start guard prefers Herdr, falls back to Tmux. Bootstrap, PATH setup, starship/zoxide/atuin/fzf/carapace init, vi-mode, Pi-matching syntax colors, aliases.
- `HatLinux/scripts/ghostty-multiplexer-new` — multiplexer-aware wrapper. Detects `command -v herdr`; if present, runs Herdr session commands; else falls back to current `ghostty-tmux-new` behavior (preserves session-name arg, ghostty prefix, 2-window layout).

### EDITED files (4)
- `HatLinux/ghostty/config` — change `command = /usr/bin/tmux -f ~/.tmux.conf new-session -A -s main` to `command = ~/.local/bin/ghostty-multiplexer-new main`.
- `HatLinux/zsh/.zshrc` — add multiplexer auto-start guard block. Keep all existing content (p10k, fzf, zoxide, atuin, eza, completions, bun).
- `HatLinux/tmux/.tmux.conf` — update `bind N` to call the new wrapper: `bind N command-prompt -p "Nombre de sesión:" "run-shell '~/.local/bin/ghostty-multiplexer-new %%'"`.
- `HatLinux/README.md` — note that Herdr replaces Tmux as default; Tmux remains fallback. Add Herdr installation hint.

### DELETED files (1)
- `HatLinux/tmux/scripts/ghostty-tmux-new` — superseded by `ghostty-multiplexer-new`.

### UNCHANGED (hard constraint)
- `HatLinux/zsh/.p10k.zsh` — powerlevel10k prompt config.
- `HatLinux/kde/` — KDE/Hyprland context.
- `HatWindows/` — Windows side (no native Herdr support upstream).
- `terminals/`, `shared/` — shared configs.
- `link-linux.sh`, `link-windows.ps1` — installer scripts (out of scope this slice).

---

## 5. Non-goals (explicit)

1. **No `link-linux.sh` changes.** User explicitly chose port-mínimo scope; installer stays as-is.
2. **No `link-windows.ps1` changes.** Windows native Herdr does not exist upstream.
3. **No Nushell config.** User explicitly excluded Nushell.
4. **No Tmux removal.** Tmux binary stays; `.tmux.conf` stays; it remains the fallback path.
5. **No theme overhaul.** Only Herdr gets a new theme; Ghostty/Catppuccin stay.
6. **No Herdr binary installation.** User installs Herdr themselves (`brew install herdr` or `cargo install herdr`); we only ship config + auto-start logic.
7. **No TUI installer addition.** HatDots doesn't ship one; we don't port Gentleman's TUI installer either.
8. **No chained-PR / multi-area refactor.** Single-PR scope (review budget 400 lines, current diff estimate ~120 lines).

---

## 6. Product implications / edge cases

| # | Edge case | Mitigation |
|---|---|---|
| E1 | Herdr binary not installed | Wrapper checks `command -v herdr`; falls back to Tmux path. Same behavior as today. |
| E2 | Herdr nested in Tmux (or vice versa) | Both shell patches check `TMUX` / `ZELLIJ` / `HERDR_ENV` guards before auto-start. Herdr sets `HERDR_ENV` itself when spawning a pane. |
| E3 | License `NOASSERTION` | Surface in `HatLinux/README.md` and `README.md` Herdr section. Link to upstream license file. Recommend users evaluate before commercial use. |
| E4 | Windows users | `HatWindows/` stays as-is. Note in `README.md`: "Herdr has no native Windows binary. Use WSL or stay on Tmux-equivalent." |
| E5 | Herdr v0.4.x rapid API changes | Recommend loose version pinning in `HatLinux/herdr/README.md` (track upstream `main`; revisit every release). Do not pin in our config.toml — Herdr config is forward-compatible across v0.4.x patch versions per upstream. |
| E6 | Wrapper path resolution | Ghostty uses `~/.local/bin/ghostty-multiplexer-new`; link-linux.sh already symlinks HatLinux/scripts/ into `~/.local/bin/`. Confirm path during spec phase (open gap DG-1). |
| E7 | p10k gitstatus under Herdr PTY | Herdr uses real PTY, so p10k's gitstatus should work. Verify during apply phase (open gap DG-2). |
| E8 | KDE/Hyprland `Ctrl+Space N` keybind | Was bound to `ghostty-tmux-new`; now points to wrapper. Tmux fallback path preserves the binding. If Herdr is active, the wrapper invokes Herdr session creation; equivalent UX. |
| E9 | `HatLinux/tmux/scripts/ghostty-tmux-new` deletion breaks anyone who has it linked elsewhere | Deleted only after `ghostty-multiplexer-new` exists and is symlinked at the same path. Spec phase must sequence this (open gap DG-3). |
| E10 | Fish guard logic differs from Zsh guard logic | Both must encode the same priority: Herdr > Tmux > nothing. Spec phase must verify both guards produce identical behavior (open gap DG-5). |

---

## 7. Business / product tradeoffs

| Tradeoff | Winner | Why |
|---|---|---|
| Mouse-first vs keyboard-first UX | Herdr (when available) | Aligns with Pi/Engram toolchain's UX; keyboard-first users can opt out by uninstalling Herdr. |
| Single binary vs plugin ecosystem | Single binary (Herdr) | Simpler ops, one less moving part (no TPM, no plugin manager for Herdr). Tmux plugins remain for fallback path. |
| Learning curve | Acceptable | Wrapper hides most of it; keybindings mirror Tmux conventions (`ctrl+a` prefix, `alt+j/k` nav). |
| License clarity | Tmux wins | Herdr is `NOASSERTION`. We document the caveat; user decides. |
| Windows support | Tmux wins (today) | No native Herdr. HatDots Windows side unchanged. |
| Maturity | Tmux wins | Herdr is v0.4.x, pre-1.0. We mitigate via Tmux fallback always being available. |

---

## 8. Acceptance criteria (proposal-level)

This change is **done** when:

1. `HatLinux/herdr/config.toml` exists with Pi-matching palette and the three keybinding sections (`keys.prefix`, `keys.previous_agent`, `keys.next_agent`, `keys.focus_agent`).
2. `HatLinux/fish/config.fish` exists and is a working Fish shell init that: bootstraps Fisher if absent, sets PATH (Termux/macOS/Linux branches), auto-starts Herdr-or-Tmux, inits starship/zoxide/atuin/fzf/carapace, enables vi-mode, applies Pi-matching syntax colors.
3. `HatLinux/zsh/.zshrc` is unchanged in existing tooling; gains a multiplexer guard that prefers Herdr over Tmux, identical behavior to the Fish guard.
4. `HatLinux/scripts/ghostty-multiplexer-new` exists, is executable, detects Herdr binary, falls back to Tmux path with same session-name arg and 2-window layout as the current `ghostty-tmux-new`.
5. `HatLinux/ghostty/config` `command = ...` line points to the new wrapper.
6. `HatLinux/tmux/.tmux.conf` `bind N` line points to the new wrapper.
7. `HatLinux/tmux/scripts/ghostty-tmux-new` is removed.
8. `HatLinux/herdr/README.md` and `HatLinux/README.md` document: Herdr install command (`brew install herdr` / `cargo install herdr`), Herdr default + Tmux fallback model, license caveat (NOASSERTION), v0.4.x version warning, Windows note.
9. `README.md` (root) gains a Herdr section in the multiplexer overview.

---

## 9. Open decision gaps for spec phase

These are intentionally **not** resolved at proposal level — the spec/design phases must close them.

- **DG-1**: Wrapper script location — `HatLinux/scripts/` vs `HatLinux/herdr/scripts/`. Recommendation: `HatLinux/scripts/` (cross-multiplexer, lives outside both tmux/ and herdr/ trees).
- **DG-2**: Verify p10k gitstatus behavior under Herdr PTY during apply phase.
- **DG-3**: Sequencing of `ghostty-tmux-new` deletion — must happen only after `ghostty-multiplexer-new` is created AND linked at the same path AND `.tmux.conf` `bind N` is updated.
- **DG-4**: Herdr version handling — confirm with upstream whether `config.toml` is forward-compatible across v0.4.x patch versions, or whether we need a pinned config block.
- **DG-5**: Fish guard logic parity with Zsh guard logic — both must encode identical priority (Herdr > Tmux > nothing). Spec phase defines the exact condition strings.
- **DG-6**: Whether Fish `~/.config/fish/config.fish` should be created from scratch or include a migration header that warns existing Fish users about overrides.
- **DG-7**: Whether the wrapper should accept multiple session-name args or just one.
- **DG-8**: License section placement — `HatLinux/README.md` only vs `README.md` root vs both.

---

## 10. References (Gentleman.Dots precedent)

- `Gentleman.Dots/herdr/config.toml` — palette + keybinding source.
- `Gentleman.Dots/GentlemanFish/fish/config.fish` — full GentlemFish port reference.
- `Gentleman.Dots/GentlemanNushell/config.nu` — guard pattern reference (Nushell excluded for HatDots).
- `Gentleman.Dots/docs/manual-installation.md` — Herdr installation guidance.

---

## 11. Risks (severity-tagged)

| Risk | Severity | Mitigation |
|---|---|---|
| License `NOASSERTION` | Medium | Document in README; user opts in. |
| v0.4.x pre-1.0 instability | Medium | Tmux fallback always available; track upstream. |
| Windows users unsupported | Low (acknowledged) | HatWindows/ unchanged; README documents WSL recommendation. |
| Wrapper script failure (e.g., Herdr crashes) | Low | Tmux fallback path is independent; user can disable Herdr to force Tmux. |
| Wrapper path resolution (`~/.local/bin/`) | Low | link-linux.sh already manages this; verify in apply phase. |
| Nested sessions | Low | Three guard vars (`TMUX`, `ZELLIJ`, `HERDR_ENV`) prevent this in all current multiplexers. |
| Fish + Zsh parallel drift | Medium | Both guards must encode identical priority (DG-5); spec phase enforces parity test. |
| p10k gitstatus under Herdr PTY | Low | Real PTY preserves gitstatus behavior; verify in apply (DG-2). |
| Tmux session scripts deleted before wrapper ready | Medium | DG-3 sequencing; delete only after wrapper linked + bind updated. |
| Inferred scope drift in subagent writes | Low | Proposal locked; spec phase inherits; design/tasks gate before apply. |

---

## 12. Artifacts

- **Engram**: `sdd/add-herdr-multiplexor/proposal` (this document).
- **OpenSpec mirror**: `openspec/changes/add-herdr-multiplexor/proposal.md` (this document).
- **Predecessor**: `sdd/add-herdr-multiplexor/explore` (observation id 137).
- **Next recommended phase**: `sdd-spec` (after user approval).

---

## Status envelope

```yaml
status: success
executive_summary: |
  Proposal complete for adopting Herdr as default Linux multiplexer in HatDots
  with Tmux as graceful fallback. Scope expanded from initial "port mínimo"
  to include Ghostty wrapper (Decision A1), full GentlemFish port (Decision B1),
  and multiplexer-aware script wrapper (Decision C2). 12 sections covered,
  8 decision gaps enumerated for spec phase.
artifacts:
  - topic_key: sdd/add-herdr-multiplexor/proposal
    mirror: openspec/changes/add-herdr-multiplexor/proposal.md
artifacts_written_summary:
  - Why now / business problem
  - Target users / situations
  - Current-state gap vs desired state
  - Scope boundaries (first slice)
  - Non-goals
  - Product implications / edge cases (10 cases)
  - Business / product tradeoffs (6 tradeoffs)
  - Acceptance criteria (9 criteria)
  - Open decision gaps (8 gaps for spec phase)
  - References (Gentleman.Dots precedent)
  - Risks (10 risks, severity-tagged)
  - Status envelope
next_recommended: sdd-spec
risks:
  - license NOASSERTION (medium)
  - v0.4.x pre-1.0 instability (medium)
  - Fish/Zsh guard parity (medium, gated by DG-5)
  - ghostty-tmux-new deletion sequencing (medium, gated by DG-3)
  - Windows unsupported (low, documented)
  - p10k gitstatus under Herdr PTY (low, gated by DG-2)
skill_resolution: gentle-ai (paths-injected from subagent exploration; orchestrator composed final proposal from acceptance-report + exploration notes + user decisions)
```

---

**Phase gate**: proposal phase COMPLETE. Awaiting user approval to advance to `sdd-spec`. Do not start spec, design, or tasks until user explicitly approves.