-- salesforce.health — prerequisite checks for the Salesforce module.
-- Probes: `sf` on PATH, apex-ls plugin via `sf plugins`, JDK via `sf apex --version`,
-- `sfdx-project.json` walking up from cwd, current `sf config get target-org`.

local M = {}
local util = require("salesforce.util")

local cached = nil

--- Find sfdx-project.json by walking up from cwd.
--- @return string|nil
local function find_sfdx_project()
  local start = vim.fn.getcwd()
  local path = start
  while path and path ~= "/" do
    local candidate = path .. "/sfdx-project.json"
    if vim.uv.fs_stat(candidate) then
      return candidate
    end
    local parent = vim.fn.fnamemodify(path, ":h")
    if parent == path then
      break
    end
    path = parent
  end
  return nil
end

--- @return { sf: boolean, apex_ls: boolean, jdk: boolean, sfdx_project: boolean, target_org: string|nil }
function M.check()
  if cached then
    return cached
  end

  -- Probe sf CLI
  local sf_ok = vim.fn.executable("sf") == 1

  -- Probe apex-ls plugin
  local apex_ls_ok = false
  if sf_ok then
    local result = util.run_sf({ "plugins" })
    if result.ok and result.stdout:find("apex") then
      apex_ls_ok = true
    end
  end

  -- Probe JDK via sf apex --version
  local jdk_ok = false
  if sf_ok and apex_ls_ok then
    local result = util.run_sf({ "apex", "--version" })
    if result.ok then
      jdk_ok = true
    end
  end

  -- Probe sfdx-project.json
  local project = find_sfdx_project()
  local project_ok = project ~= nil

  -- Probe target-org
  local target_org = nil
  if sf_ok then
    -- Use --json: plain output is an ASCII table with many newlines that
    -- would explode nvim_buf_set_lines downstream. JSON returns the value
    -- cleanly as parsed.result[1].value.
    local result = util.run_sf({ "config", "get", "target-org", "--json" })
    if result.ok and result.parsed and result.parsed.result then
      local entry = result.parsed.result[1]
      if entry and entry.value and entry.value ~= "" then
        target_org = entry.value
      end
    end
  end

  cached = {
    sf = sf_ok,
    apex_ls = apex_ls_ok,
    jdk = jdk_ok,
    sfdx_project = project_ok,
    sfdx_project_path = project,
    target_org = target_org,
  }
  return cached
end

--- Print a human-readable diagnosis.
function M.diagnose()
  local s = M.check()
  local lines = {
    "Salesforce health check",
    "=======================",
    ("sf CLI on PATH:           %s"):format(s.sf and "OK" or "MISSING (install Salesforce CLI)"),
    ("apex-ls plugin installed: %s"):format(s.apex_ls and "OK" or "MISSING (run: sf plugins install apex)"),
    ("JDK 17+ available:        %s"):format(s.jdk and "OK" or "MISSING (apex-ls requires JDK 17+)"),
    ("sfdx-project.json found:  %s"):format(
      s.sfdx_project and ("OK (" .. (s.sfdx_project_path or "?") .. ")") or "MISSING (not in a Salesforce project)"
    ),
    ("Current target-org:       %s"):format(s.target_org or "<none>"),
  }
  -- Flatten in case any item embeds newlines (defensive).
  -- nvim_buf_set_lines rejects items containing \n.
  local flat = {}
  for _, l in ipairs(lines) do
    for _, sub in ipairs(vim.split(l, "\n", { plain = true })) do
      table.insert(flat, sub)
    end
  end
  -- Render into a floating window centred on the editor.
  -- Floating windows do not affect the user's existing splits/layout,
  -- and close with q or <Esc>.
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, flat)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#flat + 2, vim.o.lines - 6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Salesforce Health ",
    title_pos = "center",
  })
  vim.bo[buf].bufhidden = "wipe"

  -- Close with q or <Esc> for predictable dismissal.
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

--- Initialize health checks; refresh on workspace change.
function M.init()
  -- Refresh cache on directory change.
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("SalesforceHealth", { clear = true }),
    callback = function()
      cached = nil
    end,
  })
end

return M