# Skill Registry - HatDots

**Generated**: 2026-05-07  
**Project**: hatdots  
**Type**: Dotfiles/Configuration Repository

---

## User Skills Available

The following skills are available in the user's skill directory (`~/.config/opencode/skills/`):

| Skill | Trigger | Description |
|-------|---------|-------------|
| **branch-pr** | Creating PRs, opening PRs, preparing changes for review | PR creation workflow following issue-first enforcement |
| **career-ops** | Job search automation, evaluate offers, generate CVs | AI job search command center |
| **chained-pr** | PR >400 lines, planning chained/stacked PRs | Split large changes into reviewable slices |
| **cognitive-doc-design** | Writing guides, READMEs, RFCs, architecture docs | Documentation with progressive disclosure |
| **comment-writer** | Drafting feedback, review comments, async collaboration | Warm, direct, human comments |
| **go-testing** | Writing Go tests, using teatest | Go testing patterns including Bubbletea TUI |
| **issue-creation** | Creating GitHub issues, reporting bugs | Issue creation following issue-first enforcement |
| **judgment-day** | "judgment day", "review adversarial", "dual review" | Parallel adversarial review protocol |
| **prd-creator** | Creating PRDs, product requirements | Comprehensive Product Requirements Documents |
| **skill-creator** | Creating new skills, agent instructions | Creates AI agent skills |
| **work-unit-commits** | Implementing changes, preparing commits | Structure commits as deliverable work units |

### SDD Skills (System)

| Skill | Trigger | Description |
|-------|---------|-------------|
| **sdd-explore** | Thinking through features, investigating codebase | Explore ideas before committing |
| **sdd-propose** | Creating change proposals | Intent, scope, and approach |
| **sdd-spec** | Writing specifications | Requirements with BDD scenarios |
| **sdd-design** | Technical design documents | Architecture decisions and approach |
| **sdd-tasks** | Implementation task breakdown | Checklist of tasks |
| **sdd-apply** | Implementing tasks from changes | Code implementation |
| **sdd-verify** | Validating implementation | Verify against specs |
| **sdd-archive** | Archiving completed changes | Sync delta specs to main |
| **sdd-elicit** | Requirements elicitation from user stories | Interactive Q&A for requirements |
| **sdd-onboard** | SDD workflow walkthrough | Guided end-to-end onboarding |
| **sdd-init** | "sdd init", "iniciar sdd", "openspec init" | Initialize SDD context |

---

## Project Conventions

### Agent Instructions
**Status**: ❌ No project-level agent instructions found

Checked locations:
- `AGENTS.md` — Not found
- `agents.md` — Not found
- `CLAUDE.md` — Not found
- `.cursorrules` — Not found
- `GEMINI.md` — Not found (project root)

**Note**: `HatWindows/nvim/GEMINI.md` exists but is plugin-specific documentation, not project-wide agent instructions.

### Project Structure Conventions
Based on repository analysis:

```
HatDots/
├── .atl/                    # Agent tooling (created by sdd-init)
│   └── skill-registry.md    # This file
├── .git/                    # Git repository
├── shared/                  # Cross-platform configs
│   └── starship.toml        # Starship prompt config
├── terminals/               # Terminal emulator configs
│   ├── wezterm/             # WezTerm (cross-platform)
│   └── ghostty/             # Ghostty (Linux optional)
├── HatLinux/                # Linux-specific configs
│   └── nvim/                # Neovim (LazyVim)
│       ├── init.lua         # Platform detection + bootstrap
│       ├── lua/
│       │   ├── config/      # Core config modules
│       │   └── plugins/     # LazyVim plugin specs
│       ├── lazy-lock.json   # Plugin versions lock
│       └── lazyvim.json     # LazyVim extras config
├── HatWindows/              # Windows-specific configs
│   └── nvim/                # Neovim (LazyVim + AI plugins)
│       ├── .claude/         # Claude-specific settings
│       ├── GEMINI.md        # Gemini CLI documentation
│       └── ... (similar structure to Linux)
├── link-linux.sh            # Linux symlink deployment
├── link-windows.ps1         # Windows symlink deployment
└── SETUP.md                 # Setup documentation
```

### Coding Conventions (Lua)
- **Module pattern**: `return { ... }` for plugin specs
- **Config modules**: `require("config.module")` pattern
- **Platform detection**: `vim.fn.has("win32")`, `vim.fn.has("unix")`
- **Leader key**: Space (`<leader>`)
- **Plugin manager**: Lazy.nvim (via LazyVim)

---

## Usage

Skills are auto-loaded based on trigger patterns. For example:
- Running `/sdd-new fix-neovim-startup` → triggers `sdd-propose`
- Saying "judgment day on this config" → triggers `judgment-day`
- Creating a PR → triggers `branch-pr` or `chained-pr` (if >400 lines)
