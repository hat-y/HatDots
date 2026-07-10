-- salesforce.pickers — Telescope pickers for sf CLI commands.
-- All sf invocations go through salesforce.util.run_sf.

local M = {}
local util = require("salesforce.util")
local health = require("salesforce.health")

local function ensure_telescope()
  local ok = pcall(require, "telescope")
  if not ok then
    util.notify("error", "telescope.nvim is not loaded")
    return false
  end
  return true
end

local function ensure_sf_in_project()
  local s = health.check()
  if not s.sf then
    util.notify("error", "sf CLI not on PATH")
    return false
  end
  if not s.sfdx_project then
    util.notify("error", "No sfdx-project.json in workspace")
    return false
  end
  return true
end

--- Show deploy progress in a qflist, return boolean success.
local function show_qf_from_result(title, result)
  if result.ok then
    -- split stdout into qf entries (each line is one)
    local lines = vim.split(result.stdout or "", "\n", { plain = true })
    local qf = {}
    for i, line in ipairs(lines) do
      if line ~= "" then
        table.insert(qf, {
          filename = "",
          lnum = i,
          col = 1,
          text = line,
          type = "I",
        })
      end
    end
    if #qf > 0 then
      vim.fn.setqflist(qf, " ")
      vim.cmd("copen")
    end
    util.notify("info", title .. " succeeded")
    return true
  else
    util.qf_failure(title .. " failed", vim.split((result.stderr or result.stdout or ""), "\n", { plain = true }))
    return false
  end
end

function M.deploy()
  if not ensure_telescope() or not ensure_sf_in_project() then
    return
  end
  local manifest = vim.fn.input("Manifest path (default: current project): ")
  local args
  if manifest and manifest ~= "" then
    args = { "project", "deploy", "start", "--manifest", manifest, "--ignore-conflicts" }
  else
    args = { "project", "deploy", "start", "--source-dir", "force-app", "--ignore-conflicts" }
  end
  local result = util.run_sf(args, { timeout_ms = 300000 })
  show_qf_from_result("Deploy", result)
end

function M.retrieve()
  if not ensure_telescope() or not ensure_sf_in_project() then
    return
  end
  -- Auto-use manifest/package.xml when present (necessary for orgs without
  -- source tracking, like many production orgs).
  local default_manifest = vim.fn.getcwd() .. "/manifest/package.xml"
  local has_default = vim.fn.filereadable(default_manifest) == 1
  local prompt_label
  if has_default then
    prompt_label = "Manifest path (Enter for manifest/package.xml): "
  else
    prompt_label = "Manifest path (Enter for full source-dir retrieve): "
  end
  local manifest = vim.fn.input(prompt_label, has_default and "manifest/package.xml" or "")
  local args
  if manifest and manifest ~= "" then
    args = { "project", "retrieve", "start", "--manifest", manifest }
  elseif has_default then
    -- User accepted the default by leaving it; use manifest/package.xml.
    args = { "project", "retrieve", "start", "--manifest", "manifest/package.xml" }
  else
    args = { "project", "retrieve", "start", "--source-dir", "force-app" }
  end
  local result = util.run_sf(args, { timeout_ms = 300000 })
  show_qf_from_result("Retrieve", result)
end

function M.retrieve_selective()
  if not ensure_telescope() or not ensure_sf_in_project() then
    return
  end
  local result = util.run_sf({ "org", "list", "metadata-types", "--json" })
  if not result.ok or not result.parsed or not result.parsed.result or not result.parsed.result.metadataObjects then
    util.notify("error", "Failed to list metadata types: " .. (result.stderr or "unknown"))
    return
  end
  local types = result.parsed.result.metadataObjects
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  pickers
    .new({}, {
      prompt_title = "Retrieve metadata (pick type, then name)",
      finder = finders.new_table({
        results = types,
        entry_maker = function(t)
          local name = t.xmlName or t.name or "?"
          return { value = name, display = name, ordinal = name }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection or not selection.value then
            return
          end
          local md_type = selection.value
          local component = vim.fn.input("Component name (default: * for all of this type): ", "*")
          if component == "" then
            component = "*"
          end
          local md = md_type .. ":" .. component
          local r = util.run_sf({
            "project", "retrieve", "start",
            "--metadata", md,
            "--ignore-conflicts",
          }, { timeout_ms = 300000 })
          show_qf_from_result("Retrieve " .. md, r)
          util.notify("info", "Files saved to force-app/main/default/")
        end)
        return true
      end,
    })
    :find()
end
function M.soql()
  if not ensure_telescope() or not ensure_sf_in_project() then
    return
  end
  local query = vim.fn.input("SOQL query: ")
  if query == "" then
    return
  end
  local result = util.run_sf({ "data", "query", "--query", query, "--json" })
  if not result.ok then
    util.qf_failure("SOQL failed", vim.split((result.stderr or result.stdout or ""), "\n", { plain = true }))
    return
  end
  -- Format records as a table
  local records = (result.parsed and result.parsed.result and result.parsed.result.records) or {}
  local lines = { "SOQL query result (" .. tostring(#records) .. " records)", string.rep("=", 60) }
  for _, rec in ipairs(records) do
    local parts = {}
    for k, v in pairs(rec) do
      if type(v) ~= "table" then
        table.insert(parts, tostring(k) .. "=" .. tostring(v))
      end
    end
    table.insert(lines, table.concat(parts, " | "))
  end
  if #records == 0 then
    table.insert(lines, "(no records returned)")
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo.bufhidden = "wipe"
  vim.bo.filetype = "markdown"
end

function M.apex_run()
  if not ensure_sf_in_project() then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = vim.fn.join(lines, "\n")
  if vim.trim(content) == "" then
    util.notify("info", "Current buffer is empty; nothing to run")
    return
  end
  local ft = vim.bo[bufnr].filetype
  if ft ~= "apex" and ft ~= "java" then
    util.notify("warn", "Current buffer is not an Apex file (filetype=" .. ft .. ")")
    return
  end
  -- Write buffer to a temp file
  local tmp = vim.fn.tempname() .. ".apex"
  vim.fn.writefile(lines, tmp)
  local result = util.run_sf({ "apex", "run", "--file", tmp })
  vim.fn.delete(tmp)
  if not result.ok then
    util.qf_failure("Apex run failed", vim.split((result.stderr or result.stdout or ""), "\n", { plain = true }))
    return
  end
  -- Show output
  local out = vim.split(result.stdout or "", "\n", { plain = true })
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo.bufhidden = "wipe"
end

function M.log_picker()
  if not ensure_telescope() or not ensure_sf_in_project() then
    return
  end
  local result = util.run_sf({ "apex", "log", "list", "--json" })
  if not result.ok or not result.parsed then
    util.notify("error", "Failed to list logs: " .. (result.stderr or "unknown"))
    return
  end
  local logs = (result.parsed.result) or {}
  if #logs == 0 then
    util.notify("warn", "No debug logs. Enable tracing: sf apex trace flag ...")
    return
  end
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  pickers
    .new({}, {
      prompt_title = "Apex Debug Logs",
      finder = finders.new_table({
        results = logs,
        entry_maker = function(log)
          local display = string.format("%s  %s  %s", log.Id or "?", log.Operation or "?", log.Status or "?")
          return { value = log, display = display, ordinal = (log.Id or "") .. " " .. (log.Operation or "") }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value and selection.value.Id then
            local r = util.run_sf({ "apex", "log", "get", "--log-id", selection.value.Id })
            if r.ok then
              local out = vim.split(r.stdout or "", "\n", { plain = true })
              local buf = vim.api.nvim_create_buf(false, true)
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
              vim.cmd("vsplit")
              vim.api.nvim_win_set_buf(0, buf)
              vim.bo.bufhidden = "wipe"
            else
              util.notify("error", "Failed to fetch log: " .. (r.stderr or ""))
            end
          end
        end)
        return true
      end,
    })
    :find()
end

return M