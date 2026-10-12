# Parked: macOS Salesforce plugins

`xixiaofinland-sf.lua.parked` and `apex_ls.lua.parked` are HatMac's Salesforce
plugin specs (`xixiaofinland/sf.nvim` + a minimal `apex_ls` LSP setup).
`fzf-lua.lua.parked` and `overseer.lua.parked` are their two dependencies
(fzf-lua for `sf.nvim`'s metadata picker, overseer.nvim for its async
terminal) — neither has any other consumer in this config, so they're parked
alongside sf.nvim rather than activated on their own.

Parked because: Phase 3 of the HatDots unification kept the Linux Salesforce
implementation (`common/nvim/lua/salesforce/*`, `plugins/salesforce.lua`,
`salesforce.md`) active and still has an open comparison against this macOS
implementation (see `odd/tasks/hatdots-unify.md`, task P3-3). These files are
`.parked` (not `.lua`) so they are not on Neovim's plugin import path; restore
them (rename back to `.lua`, drop the dependency files if sf.nvim is not
chosen) once that decision lands.
