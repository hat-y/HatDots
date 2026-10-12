# Salesforce integration for HatDots (Linux)

This document covers the Salesforce development workflow integrated into the
HatDots Linux nvim configuration. Windows support is a planned follow-up and
is not covered here.

## Required system dependencies

The Salesforce module does **not** auto-install dependencies. Verify and install
them manually before use.

| Dependency  | How to check                  | Install                                                           |
| ----------- | ----------------------------- | ----------------------------------------------------------------- |
| `sf` CLI    | `sf --version`                | `npm install --global @salesforce/cli`                            |
| JDK 17+     | `java -version`               | OS package manager or `sdkman`                                    |
| `apex-ls`   | `sf plugins \| grep apex`     | `sf plugins install apex`                                         |

Run `:SfHealth` inside nvim to verify everything is wired up correctly.

## Quick start

1. Open a Salesforce project directory (one containing `sfdx-project.json`).
2. The Salesforce module auto-initializes when you open the first `.cls`,
   `.trigger`, or `.apex` file. If you don't have any of those open yet,
   you can force initialization with `:lua require("salesforce").setup()`.
3. Run `:SfHealth` to confirm prerequisites.
4. Run `:SfOrgPicker` (or `<leader>so`) to pick a target org.

## Keymaps

All Salesforce keymaps live under `<leader>S` (capital S) to avoid collisions with mini-surround:

| Keymap        | Action                                |
| ------------- | ------------------------------------- |
| `<leader>So`  | Open org picker (multi-org switcher)  |
| `<leader>SO`  | Set target-org by alias (input prompt)|
| `<leader>Sd`  | Display current org info              |
| `<leader>Sp`  | Deploy current project                |
| `<leader>Sr`  | Retrieve from current project (uses `manifest/package.xml` if present, else full `force-app/`) |
| `<leader>SrR` | Retrieve specific metadata by type    |
| `<leader>Sq`  | Run a SOQL query                      |
| `<leader>Sa`  | Run current buffer as anonymous Apex  |
| `<leader>Sl`  | Open debug log picker                 |
| `<leader>St`  | Toggle sf terminal (toggleterm)       |
| `<leader>SNA` | New Apex class (scaffold)             |
| `<leader>SNL` | New LWC bundle (scaffold)             |
| `<leader>SNT` | New Apex trigger (scaffold)           |

## User commands

| Command          | Description                              |
| ---------------- | ---------------------------------------- |
| `:SfHealth`      | Run prerequisite health check            |
| `:SfOrgPicker`   | Open the org picker                      |
| `:SfOrgDisplay`  | Display current org info                 |
| `:SfOrgSet`      | Set target-org by alias                  |
| `:SfDeploy`      | Deploy current project                   |
| `:SfRetrieve`    | Retrieve from current project            |
| `:SfRetrieveSelective` | Retrieve specific metadata by type     |
| `:SfSoql`        | Run a SOQL query                         |
| `:SfApexRun`     | Run current buffer as anonymous Apex     |
| `:SfNewApex`     | Create a new Apex class                  |
| `:SfNewLwc`      | Create a new LWC bundle                  |
| `:SfNewTrigger`  | Create a new Apex trigger                |
| `:SfLogPicker`   | Open debug log picker                    |

## Scaffolding new metadata

The three `S*` "new" shortcuts create empty metadata files inside the project's package directory (read from `sfdx-project.json`), open the new file in nvim, and are ready for editing.

- **`<leader>SNA`** / **`:SfNewApex`** — prompts for a class name, validates it (CamelCase, no spaces), and creates `force-app/main/default/classes/<Name>.cls` plus the matching `-meta.xml` with the project's `sourceApiVersion`. The class body uses `public with sharing`.
- **`<leader>SNL`** / **`:SfNewLwc`** — prompts for a component name, converts to `kebab-case` (Salesforce LWC convention), and creates the full bundle: `<name>.html`, `<name>.js` (PascalCase class), `<name>.css`, `<name>.svg`, and `<name>.js-meta.xml`. The bundle is created under `force-app/main/default/lwc/<name>/`.
- **`<leader>SNT`** / **`:SfNewTrigger`** — prompts first for the SObject name (e.g. `Account`, `MyObject__c`) and then the trigger name (default `<Object>Trigger`). Creates `force-app/main/default/triggers/<Name>.trigger` plus `-meta.xml`, with all four standard events pre-listed in the trigger signature.

The `<leader>SN*` shortcuts are designed to be called repeatedly without leaving normal mode: each one returns focus to the new file's buffer at the body of the class / template / trigger.

## Multi-org workflow

The org picker lists every configured org (from `sf org list`). Selecting one:

1. Runs `sf config set target-org=<alias>`.
2. Sets `vim.g.sf_target_org` for the current nvim session.
3. Emits the `SfTargetOrgChanged` autocmd, which updates the statusline
   component and pushes the new value into any open sf terminal.

Per-workspace state is tracked via `vim.b.sf_target_org` so different projects
can have different active orgs within the same nvim instance.

## SF terminal

`<leader>st` opens a toggleterm preloaded with the active org context:

```sh
echo $SF_TARGET_ORG
```

When you switch orgs via the picker, the running terminal receives an
`export SF_TARGET_ORG=<new-alias>` automatically — you do not need to reopen.

## SOQL queries

`<leader>sq` prompts for a SOQL string, runs `sf data query --json`, and shows
the formatted records in a split buffer. Pagination through `nextRecordsUrl` is
not yet handled in the buffer view — for paginated queries, use `sf data query`
directly.

## Anonymous Apex

`<leader>sa` (or `:SfApexRun`) executes the current buffer as anonymous Apex
against the active org. The buffer must have an Apex filetype (`.cls`, `.trigger`,
or `.apex`); otherwise the command refuses with a notification.

## Debug logs

`<leader>sl` lists recent debug logs from `sf apex log list`. Selecting one
fetches the full log via `sf apex log get` and opens it in a split.

If no logs are visible, enable tracing first:

```sh
sf apex trace flag --create --tracelevel DEBUGINFO
```

## Troubleshooting

Start with `:SfHealth`. It will report:

- Missing `sf` CLI → install it.
- Missing `apex-ls` plugin → `sf plugins install apex`.
- Apex-ls JAR not found at expected paths → check
  `~/.local/share/sf/client/plugins/apex/` or set
  `vim.g.sf_apex_ls_path` manually.
- No sfdx-project.json → not in a Salesforce project.

The statusline component (top-right of the editor) shows the active org alias
when you are in a Salesforce project. If it does not appear, the project root
may not contain `sfdx-project.json`.

## Known limitations

- SOQL syntax highlighting for `.soql` files is not included (vim-soql is
  dormant; this is a planned follow-up).
- Apex DAP debugger is not integrated; debug logs (read-only) are.
- Visualforce / Aura / LWC tooling is not included.
- Windows support is not implemented (planned follow-up).
- `~/.sfdx/` is the standard CLI credential storage; per-workspace credential
  isolation is not implemented.

## File layout

```
HatLinux/nvim/
├── lua/
│   ├── config/
│   │   ├── lsp_on_attach.lua        # shared LSP on_attach helper (new)
│   │   └── ... (unchanged)
│   ├── plugins/
│   │   ├── lsp.lua                  # uses lsp_on_attach (modified)
│   │   ├── salesforce.lua           # toggleterm dep spec (new)
│   │   └── ... (unchanged)
│   └── salesforce/
│       ├── init.lua                 # setup, keymaps, commands
│       ├── util.lua                 # run_sf, notify, qf_failure
│       ├── health.lua               # prerequisite checks
│       ├── org.lua                  # multi-org state + picker
│       ├── pickers.lua              # Telescope pickers for sf commands
│       ├── lsp.lua                  # apex-ls setup
│       ├── terminal.lua             # toggleterm wrapper
│       └── statusline.lua           # lualine component
├── lazy-lock.json                   # adds toggleterm (modified)
└── salesforce.md                    # this file (new)
```