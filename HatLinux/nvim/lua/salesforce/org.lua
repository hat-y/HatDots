-- salesforce.org — multi-org state and pickers.
-- State: vim.g.sf_target_org (session), vim.b.sf_target_org (buffer).
-- Emits User SfTargetOrgChanged after successful set_target.

local M = {}
local util = require("salesforce.util")
local health = require("salesforce.health")

--- @return string|nil alias
function M.get_target()
  -- Buffer-local takes priority, then global, then sf config fallback.
  if vim.b.sf_target_org and vim.b.sf_target_org ~= "" then
    return vim.b.sf_target_org
  end
  if vim.g.sf_target_org and vim.g.sf_target_org ~= "" then
    return vim.g.sf_target_org
  end
  local s = health.check()
  return s.target_org
end

--- @param alias string
function M.set_target(alias)
  if not alias or alias == "" then
    util.notify("error", "set_target called with empty alias")
    return
  end
  local result = util.run_sf({ "config", "set", "target-org=" .. alias })
  if not result.ok then
    util.notify("error", "Failed to set target-org: " .. (result.stderr or "unknown error"))
    return
  end
  vim.g.sf_target_org = alias
  vim.b.sf_target_org = alias
  util.notify("info", "Target org set to: " .. alias)
  vim.api.nvim_exec_autocmds("User", { pattern = "SfTargetOrgChanged" })
end

--- @param alias string|nil  -- if nil, show input prompt
function M.set_by_alias(alias)
  if not alias or alias == "" then
    alias = vim.fn.input("Salesforce org alias: ")
    if alias == "" then
      return
    end
  end
  M.set_target(alias)
end

--- Open a Telescope picker listing all configured orgs.
function M.open_picker()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    util.notify("error", "telescope.nvim is not loaded")
    return
  end
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  local s = health.check()
  if not s.sf then
    util.notify("error", "sf CLI not on PATH")
    return
  end

  local result = util.run_sf({ "org", "list", "--json" })
  if not result.ok or not result.parsed then
    util.notify("error", "Failed to list orgs: " .. (result.stderr or "unknown"))
    return
  end

  local orgs = {}
  -- sf org list --json returns { status, result: { nonScratchOrgs, scratchOrgs, sandboxes, ... } }
  local r = result.parsed.result or {}
  for _, list in ipairs({ r.nonScratchOrgs, r.scratchOrgs, r.sandboxes, r.devHubs }) do
    if list then
      for _, org in ipairs(list) do
        table.insert(orgs, org)
      end
    end
  end

  if #orgs == 0 then
    util.notify("warn", "No orgs configured. Run: sf org login web")
    return
  end

  pickers
    .new({}, {
      prompt_title = "Salesforce Orgs",
      finder = finders.new_table({
        results = orgs,
        entry_maker = function(org)
          local display = string.format(
            "%s  (%s)  [%s]%s",
            org.alias or org.username or "?",
            org.username or "?",
            org.instanceUrl or "?",
            org.isDevHub and "  devhub" or ""
          )
          return {
            value = org,
            display = display,
            ordinal = (org.alias or "") .. " " .. (org.username or ""),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value and selection.value.alias then
            M.set_target(selection.value.alias)
          end
        end)
        return true
      end,
    })
    :find()
end

--- Show current org info in a scratch buffer.
function M.display()
  local s = health.check()
  if not s.sf then
    util.notify("error", "sf CLI not on PATH")
    return
  end
  local result = util.run_sf({ "org", "display", "--json" })
  if not result.ok then
    util.notify("error", "Failed to display org: " .. (result.stderr or "unknown"))
    return
  end
  local info = result.parsed and result.parsed.result or {}
  local alias = info.alias or M.get_target() or "<none>"
  local lines = {
    "Current Salesforce Org",
    "=====================",
    ("Alias:        %s"):format(info.alias or alias),
    ("Username:     %s"):format(info.username or "<unknown>"),
    ("Org ID:       %s"):format(info.id or "<unknown>"),
    ("Instance:     %s"):format(info.instanceUrl or info.instanceName or "<unknown>"),
    ("API version:  %s"):format(info.apiVersion or "<unknown>"),
    ("Edition:      %s"):format(info.edition or "<unknown>"),
    ("Dev Hub:      %s"):format(info.isDevHub and "yes" or "no"),
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Floating window centred on the editor; does not alter existing splits/layout.
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Current Salesforce Org ",
    title_pos = "center",
  })
  vim.bo[buf].bufhidden = "wipe"

  -- q or <Esc> to dismiss.
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

return M