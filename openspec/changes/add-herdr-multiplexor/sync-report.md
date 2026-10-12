# Sync Report — `add-herdr-multiplexor`

**Change**: `add-herdr-multiplexor`
**Project**: `hatdots`
**Phase**: sdd-sync
**Synced at**: 2026-07-10

---

## Executive Summary

**Status: SYNCED** — New canonical spec created at `openspec/specs/multiplexer/herdr.md`.

This is the first canonical spec in the repository (no prior `openspec/specs/` directory existed). The canonical spec consolidates the full change spec (REQ-1..REQ-13, SCN-1..SCN-9, C-1..C-8, R-1..R-10) into a discoverable architecture contract under `openspec/specs/multiplexer/herdr.md`. The change is NOT moved to archive — it remains active at `openspec/changes/add-herdr-multiplexor/` for TK-13 cleanup and pending user actions.

---

## Pre-Sync Gate Check

| Gate | Status | Details |
|---|---|---|
| Change selected and unambiguous | ✅ PASS | `add-herdr-multiplexor` confirmed |
| `verify-report.md` exists | ✅ PASS | Located at `openspec/changes/add-herdr-multiplexor/verify-report.md` |
| Verification report clean (no FAIL/BLOCKED/CRITICAL) | ✅ PASS | Status: "PASS with minor findings (no blockers)". Major finding is Fish tool init guard — implementation quality, not spec issue |
| File-backed mode has domain specs | ✅ N/A | Flat spec at `spec.md` is the source for this NEW canonical spec creation (Option A) |
| Destructive delta (REMOVED/large MODIFIED) | ✅ N/A | No existing canonical spec to modify; pure creation |
| Same-domain active change collision | ✅ NONE | No other active change touches `specs/multiplexer/` |
| RENAMED Requirements block | ✅ N/A | Not present in source spec |
| Non-authoritative carve-out triggered | ❌ N/A | `nextRecommended: "sdd-verify"`, not `"resolve-via-engram"`. Status is authoritative. |

---

## Action Context

```
mode: repo-local
workspaceRoot: /home/hat/projects/HatDots
allowedEditRoots: [/home/hat/projects/HatDots]
warnings: []
```

Canonical spec path `openspec/specs/multiplexer/herdr.md` is within allowed edit roots. ✅

---

## Sync Details

### Domains Synced

| Domain | Action | Canonical Path |
|---|---|---|
| `multiplexer/herdr` | CREATED (new canonical spec) | `openspec/specs/multiplexer/herdr.md` |

### Requirements Synced

| Action | Requirement Name |
|---|---|
| ADDED | REQ-1 — Herdr-first auto-start when binary present |
| ADDED | REQ-2 — Tmux fallback when Herdr absent |
| ADDED | REQ-3 — Nested-session prevention (3 guard vars) |
| ADDED | REQ-4 — Pi-matching palette in Herdr config |
| ADDED | REQ-5 — Keybinding contract (prefix, prev/next agent, focus agent 1..9) |
| ADDED | REQ-6 — Ghostty `command =` invokes wrapper, no hardcoded tmux |
| ADDED | REQ-7 — Wrapper detects Herdr binary, falls back gracefully |
| ADDED | REQ-8 — Zsh guard parity with Fish guard |
| ADDED | REQ-9 — Fish full GentlemFish-style port |
| ADDED | REQ-10 — Documentation in both READMEs (license + version + Windows note) |
| ADDED | REQ-11 — `ghostty-tmux-new` removed after wrapper ready |
| ADDED | REQ-12 — `.tmux.conf` `bind N` updated to wrapper |
| ADDED | REQ-13 — p10k gitstatus verification under Herdr PTY |

### Scenarios Synced

| Action | Scenario Name |
|---|---|
| ADDED | SCN-1 — First Ghostty launch with Herdr installed |
| ADDED | SCN-2 — First Ghostty launch without Herdr |
| ADDED | SCN-3 — Already inside Tmux, new Ghostty |
| ADDED | SCN-4 — Already inside a Herdr pane, new shell |
| ADDED | SCN-5 — `Ctrl+Space N` pressed with Herdr active |
| ADDED | SCN-6 — `Ctrl+Space N` pressed with Tmux fallback |
| ADDED | SCN-7 — Fish shell started from TTY |
| ADDED | SCN-8 — Zsh shell started from TTY |
| ADDED | SCN-9 — Herdr binary updated upstream |

### Constraints Synced

| Action | Constraint Name |
|---|---|
| ADDED | C-1 through C-8 |

### Risks Synced

| Action | Risk Name |
|---|---|
| ADDED | R-1 through R-10 |

---

## Same-Domain Collision Scan

| Active Change | Colliding Spec | Status |
|---|---|---|
| None | — | ✅ No collisions |

---

## Destructive Sync Assessment

This is a pure **creation** sync (Option A). No existing canonical spec is modified or removed. No destructive delta approval needed. ✅

---

## Validation Checks

| Check | Result |
|---|---|
| Canonical spec file path is within allowed edit roots (`/home/hat/projects/HatDots`) | ✅ PASS |
| No implementation code in canonical spec | ✅ PASS (file evidence pointers, no code blocks) |
| Canonical spec covers all REQ-1..REQ-13 | ✅ PASS |
| Canonical spec covers all SCN-1..SCN-9 | ✅ PASS |
| Canonical spec covers C-1..C-8 | ✅ PASS |
| Canonical spec covers R-1..R-10 | ✅ PASS |
| Canonical spec includes acceptance criteria (AC-1..AC-9) | ✅ PASS |
| Canonical spec includes metadata footer | ✅ PASS |
| Change artifacts not modified | ✅ PASS (only reading from `openspec/changes/add-herdr-multiplexor/`) |
| No domain specs in change directory (flat spec only) | ✅ N/A (creation sync) |
| Config.yaml not modified | ✅ PASS |

---

## Verification Findings Carried Forward

The verify report identified these findings. They do NOT block sync (they are implementation quality issues, not spec gaps). They are noted here for the archive phase:

| Finding | Severity | Location | Recommendation |
|---|---|---|---|
| Fish tool init not `command -q`-guarded | MAJOR | `HatLinux/fish/config.fish:66-69` | Wrap each in `if command -q <tool>; ...; end` |
| R-7 one-line revert not documented | MINOR | `HatLinux/README.md` | Add explicit revert command line |
| Structure tree outdated | MINOR | `HatLinux/README.md:11-28` | Update tree with scripts/, herdr/, fish/ directories |
| Stale "no signal handlers" comment | NIT | `ghostty-multiplexer-new:18-19` | Update or remove stale comment |
| Root README missing fish path | NIT | `README.md` (Multiplexor section) | Add `HatLinux/fish/config.fish` to bullet list |
| Fish guard --version asymmetry | NIT | `HatLinux/fish/config.fish:58` | Document asymmetry in comments |

---

## Structured Status & Action Context Findings

**Artifact store resolution**: `openspec/config.yaml` says `artifact_store: engram`, but the native SDD status engine reports `artifactStore: "openspec"`. The status is authoritative (`isNonAuthoritative: false`; `nextRecommended: "sdd-verify"` not `"resolve-via-engram"`). Sync proceeds in openspec mode per the status engine.

**Non-authoritative carve-out**: NOT triggered. The native status provides `artifactStore: "openspec"` and authoritative dependency/blocker data.

**actionContext**: `mode: repo-local`, `workspaceRoot: /home/hat/projects/HatDots`. Canonical spec path is under this root. ✅

---

## Persistence Note

This sync report is composed for:
- **OpenSpec mirror**: `openspec/changes/add-herdr-multiplexor/sync-report.md` (written by orchestrator)
- **Canonical spec**: `openspec/specs/multiplexer/herdr.md` (written by orchestrator)

The subagent cannot write filesystem directly. Both files have been transmitted via intercom to the orchestrator session (`subagent-chat-019f4bfc`) for mirroring.

---

## Next Recommended Phase

**`sdd-archive`** — after the following conditions are met:

1. **TK-13 cleanup** completed (`git rm HatLinux/tmux/scripts/ghostty-tmux-new`)
2. **User manual verification** of SCN-1..SCN-9 procedures (pending)
3. **Major finding addressed** (Fish tool init guards) — optional but recommended before archive
4. **Minor findings reviewed** (R-7 revert docs, structure tree update)

The archive target will be: `openspec/changes/archive/YYYY-MM-DD-add-herdr-multiplexor`

---

## Output Envelope

```
status: synced
executive_summary: |
  New canonical spec created at openspec/specs/multiplexer/herdr.md. 13 requirements,
  9 scenarios, 8 constraints, 10 risks consolidated from flat change spec. No existing
  canonical spec was modified (pure creation). Sync is the first canonical spec in the
  repository. The change remains active for TK-13 cleanup and pending user actions.
domains_synced:
  - multiplexer/herdr (CREATED)
canonical_files_updated:
  - openspec/specs/multiplexer/herdr.md
requirements_synced: [REQ-1, REQ-2, REQ-3, REQ-4, REQ-5, REQ-6, REQ-7, REQ-8, REQ-9, REQ-10, REQ-11, REQ-12, REQ-13]
scenarios_synced: [SCN-1, SCN-2, SCN-3, SCN-4, SCN-5, SCN-6, SCN-7, SCN-8, SCN-9]
collisions: none
destructive_approval: not needed (pure creation)
validation_checks_passed: 10/10
pending_conditions_before_archive:
  - TK-13 cleanup (git rm ghostty-tmux-new)
  - User manual SCN matrix verification
  - Fish tool init command-q guards (major finding)
  - R-7 revert docs and structure tree update (minor findings)
next_recommended: sdd-archive (conditional on pending items)
risks:
  - none (sync is reversible — the change remains active)
skill_resolution: paths-injected (gentle-ai skill)
```

---

## Acceptance Report

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Composed canonical spec at openspec/specs/multiplexer/herdr.md from flat spec.md source. No scope widening: canonical spec covers exactly REQ-1..REQ-13, SCN-1..SCN-9, C-1..C-8, R-1..R-10, AC-1..AC-9, DG-1..DG-12 from the change spec. No implementation code included. No existing canonical specs modified. Change artifacts (openspec/changes/add-herdr-multiplexor/*.md) and openspec/config.yaml left untouched."
    }
  ],
  "changedFiles": [
    "openspec/specs/multiplexer/herdr.md (CANONICAL SPEC — NEW)",
    "openspec/changes/add-herdr-multiplexor/sync-report.md (SYNC REPORT — NEW)"
  ],
  "testsAddedOrUpdated": [],
  "commandsRun": [
    {
      "command": "read openspec/changes/add-herdr-multiplexor/proposal.md",
      "result": "passed",
      "summary": "Read full proposal (238 lines). Extracted AC-1..AC-9, DG-1..DG-8, scope boundaries."
    },
    {
      "command": "read openspec/changes/add-herdr-multiplexor/spec.md",
      "result": "passed",
      "summary": "Read full spec (431 lines, 10 sections). Extracted REQ-1..REQ-13, SCN-1..SCN-9, C-1..C-8, R-1..R-10, DG-1..DG-8 resolved strings."
    },
    {
      "command": "read openspec/changes/add-herdr-multiplexor/design.md",
      "result": "passed",
      "summary": "Read full design (949 lines). Extracted DG-9..DG-12 new decisions, file surface, sequencing plan."
    },
    {
      "command": "read openspec/changes/add-herdr-multiplexor/tasks.md",
      "result": "passed",
      "summary": "Read full tasks (858 lines). Confirmed TK-13 cleanup deferred."
    },
    {
      "command": "read openspec/changes/add-herdr-multiplexor/apply-progress.md",
      "result": "passed",
      "summary": "Read apply progress. Confirmed 10/13 tasks complete; TK-12/TK-13 deferred."
    },
    {
      "command": "read openspec/changes/add-herdr-multiplexor/verify-report.md",
      "result": "passed",
      "summary": "Read verify report. Status: PASS with minor findings (no blockers). Verified sync gate is open."
    },
    {
      "command": "read openspec/config.yaml",
      "result": "passed",
      "summary": "Read config. artifact_store: engram (config) vs artifactStore: openspec (status). Status authoritative (non-authoritative carve-out not triggered)."
    },
    {
      "command": "intercom list",
      "result": "passed",
      "summary": "Confirmed orchestrator session subagent-chat-019f4bfc (30b75d6c) is active in same project (HatDots)."
    }
  ],
  "validationOutput": [
    "Pre-sync gate check: 7 of 7 gates pass (or N/A for creation sync).",
    "Canonical spec covers all 13 requirements (REQ-1..REQ-13).",
    "Canonical spec covers all 9 scenarios (SCN-1..SCN-9).",
    "Canonical spec covers all 8 constraints (C-1..C-8).",
    "Canonical spec covers all 10 risks (R-1..R-10).",
    "Canonical spec covers all 9 acceptance criteria (AC-1..AC-9).",
    "Canonical spec includes metadata footer with change_origin, synced_from, synced_at, locked_decisions.",
    "No implementation code in canonical spec (file evidence pointers only).",
    "No existing canonical spec modified (pure creation — first spec in repository).",
    "Change artifacts untouched; config.yaml untouched."
  ],
  "residualRisks": [
    "Verify report findings (1 major, 2 minor, 3 nits) are carried forward but do not block sync.",
    "TK-13 cleanup still pending — change remains active; no archive yet.",
    "User must still perform manual SCN-1..SCN-9 verification.",
    "Fish tool init command-q guards missing (major finding) — should be fixed before archive."
  ],
  "noStagedFiles": true,
  "diffSummary": "Sync creates 1 new canonical spec (openspec/specs/multiplexer/herdr.md, ~420 lines) and 1 sync report (openspec/changes/add-herdr-multiplexor/sync-report.md, ~250 lines). No existing files modified. This is the first canonical spec in the openspec/specs/ directory.",
  "reviewFindings": [
    "no blockers",
    "sync is a pure creation — no conflict resolution needed",
    "verify report is passing with minor findings — findings are implementation quality, not spec correctness",
    "the sync report carries forward all verify findings for archive-phase consideration"
  ],
  "manualNotes": "The canonical spec and sync report have been sent to orchestrator session subagent-chat-019f4bfc via intercom for filesystem mirroring. The orchestrator must: (1) create openspec/specs/multiplexer/herdr.md with the canonical spec content, (2) create openspec/changes/add-herdr-multiplexor/sync-report.md with the sync report content, and (3) conditionally advance to sdd-archive after pending items are resolved."
}
