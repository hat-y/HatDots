-- salesforce.tests — Apex test runner.
-- Wraps `sf apex run test` with sensible output handling for nvim:
-- notification for the summary, scratch buffer for failures and code coverage.

local M = {}
local util = require("salesforce.util")
local health = require("salesforce.health")

--- Read package directory from sfdx-project.json; fall back to "force-app".
--- @return string
local function get_package_dir()
  local cwd = vim.fn.getcwd()
  local path = cwd .. "/sfdx-project.json"
  if vim.fn.filereadable(path) == 0 then
    return "force-app"
  end
  local lines = vim.fn.readfile(path)
  local ok, parsed = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
  if not ok or not parsed or not parsed.packageDirectories then
    return "force-app"
  end
  return parsed.packageDirectories[1].path or "force-app"
end

--- Locate every *Test.cls file in the project's default package.
--- Returns a sorted list of { basename = "ClassName", path = "/abs/path" }.
--- @return table[]
local function find_test_classes()
  local pkg = get_package_dir()
  local pattern = pkg .. "/main/default/classes/*Test.cls"
  local files = vim.fn.globpath(vim.fn.getcwd(), pattern, false, true)
  local results = {}
  for _, fpath in ipairs(files) do
    local basename = vim.fn.fnamemodify(fpath, ":t:r")  -- strip .cls
    table.insert(results, { basename = basename, path = fpath })
  end
  table.sort(results, function(a, b) return a.basename < b.basename end)
  return results
end

--- Show a structured scratch buffer with the given title and lines.
--- @param title string
--- @param lines string[]
local function show_scratch(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.cmd("split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_buf_set_name(buf, "salesforce://" .. title)
end

--- Render summary line(s) from the parsed `sf apex run test` JSON.
--- @param result table   -- the .result field of the JSON envelope
--- @return string summary_line, integer failed_count
local function summarize(result)
  local summary = result.summary or {}
  local total = summary.testsRan or 0
  local passed = summary.passing or 0
  local failed = summary.failing or 0
  local skipped = summary.skipped or 0
  local exec_ms = summary.executionTime or 0
  local outcome = summary.outcome or "Unknown"

  local line = string.format(
    "%s — %d/%d passed, %d failed, %d skipped in %.2fs",
    outcome, passed, total, failed, skipped, exec_ms / 1000
  )
  return line, failed
end

--- Render failure detail lines for the scratch buffer.
--- @param result table
--- @return string[]
local function render_failures(result)
  local lines = { "# Failures", "" }
  local tests = result.tests or {}
  local any = false
  for _, t in ipairs(tests) do
    if t.outcome ~= "Pass" and t.outcome ~= "Skip" then
      any = true
      table.insert(lines, string.format("## %s.%s — %s", t.className or "?", t.methodName or "?", t.outcome or "?"))
      if t.message and t.message ~= "" then
        table.insert(lines, "")
        table.insert(lines, t.message)
      end
      if t.stackTrace and t.stackTrace ~= "" then
        table.insert(lines, "")
        table.insert(lines, "```")
        table.insert(lines, t.stackTrace)
        table.insert(lines, "```")
      end
      table.insert(lines, "")
    end
  end
  if not any then
    return {}
  end
  return lines
end

--- Render coverage lines for the scratch buffer.
--- `sf apex run test --result-format json --code-coverage` exposes a single
--- aggregated `testRunCoverage` value (percentage). Per-class coverage is not
--- available through this CLI path; to get that you need the Tooling API.
--- @param result table
--- @return string[]
local function render_coverage(result)
  local pct = result.testRunCoverage
  if pct == nil then
    return {}
  end
  return {
    "# Code coverage",
    "",
    string.format("Total covered: %.1f%%", pct),
  }
end

--- Run Apex tests for a specific class name. Internal helper.
--- @param class_name string
--- @param opts? { coverage?: boolean }
local function run_class_impl(class_name, opts)
  opts = opts or {}
  local s = health.check()
  if not s.sf then
    util.notify("error", "sf CLI not on PATH")
    return
  end
  if not s.sfdx_project then
    util.notify("error", "No sfdx-project.json in workspace")
    return
  end

  local args = { "apex", "run", "test", "--class-names", class_name, "--result-format", "json" }
  if opts.coverage then
    table.insert(args, "--code-coverage")
  end

  util.notify("info", "Running tests for " .. class_name .. "...")
  local result = util.run_sf(args, { timeout_ms = 600000 })  -- 10 min

  if not result.ok then
    util.notify("error", "sf apex run test failed: " .. (result.stderr or "unknown"))
    if result.stdout and result.stdout ~= "" then
      show_scratch("tests-failed", vim.split(result.stdout, "\n", { plain = true }))
    end
    return
  end

  local parsed = result.parsed
  if not parsed or not parsed.result then
    util.notify("error", "Could not parse sf apex run test output")
    return
  end

  local summary_line, failed = summarize(parsed.result)
  if failed == 0 then
    util.notify("info", summary_line)
  else
    util.notify("error", summary_line)
  end

  local scratch_lines = {}
  local failures = render_failures(parsed.result)
  if #failures > 0 then
    for _, l in ipairs(failures) do
      table.insert(scratch_lines, l)
    end
  end
  local coverage = render_coverage(parsed.result)
  if #coverage > 0 then
    if #scratch_lines > 0 then
      table.insert(scratch_lines, "")
    end
    for _, l in ipairs(coverage) do
      table.insert(scratch_lines, l)
    end
  end
  if #scratch_lines > 0 then
    show_scratch("tests-result", scratch_lines)
  end
end

--- Run a specific Apex test class by name.
--- @param class_name? string
function M.run_class(class_name)
  if not class_name or class_name == "" then
    class_name = vim.fn.input("Test class name: ")
    if class_name == "" then
      return
    end
  end
  class_name = class_name:gsub("%.cls$", "")
  run_class_impl(class_name, { coverage = true })
end

--- Run the Apex test class whose buffer is currently focused.
function M.run_buffer()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" or not bufname:match("%.cls$") then
    util.notify("error", "Current buffer is not an Apex class (.cls)")
    return
  end
  local class_name = vim.fn.fnamemodify(bufname, ":t:r")
  if not class_name:match("Test$") then
    local answer = vim.fn.input(
      class_name .. " does not end in 'Test'. Run anyway? [y/N] "
    )
    if answer:lower() ~= "y" then
      return
    end
  end
  run_class_impl(class_name, { coverage = true })
end

--- Telescope picker that lists every *Test.cls in the project and runs the
--- selected one against the active org.
function M.run_picker()
  local ok_telescope = pcall(require, "telescope")
  if not ok_telescope then
    util.notify("error", "telescope.nvim is not loaded")
    return
  end
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local classes = find_test_classes()
  if #classes == 0 then
    util.notify("warn", "No *Test.cls files found in this project")
    return
  end

  pickers
    .new({}, {
      prompt_title = "Apex Test Classes",
      finder = finders.new_table({
        results = classes,
        entry_maker = function(c)
          return {
            value = c,
            display = c.basename,
            ordinal = c.basename,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value then
            run_class_impl(selection.value.basename, { coverage = true })
          end
        end)
        return true
      end,
    })
    :find()
end

--- Run every *Test.cls in the project. Issues a single combined `sf apex run
--- test` invocation; coverage aggregated across all classes.
function M.run_all()
  local classes = find_test_classes()
  if #classes == 0 then
    util.notify("warn", "No *Test.cls files found in this project")
    return
  end
  local names = {}
  for _, c in ipairs(classes) do
    table.insert(names, c.basename)
  end
  util.notify("info", "Running " .. #names .. " test class(es)...")

  local s = health.check()
  if not s.sf then
    util.notify("error", "sf CLI not on PATH")
    return
  end

  local result = util.run_sf({
    "apex", "run", "test",
    "--class-names", table.concat(names, ","),
    "--result-format", "json",
    "--code-coverage",
  }, { timeout_ms = 900000 })  -- 15 min

  if not result.ok then
    util.notify("error", "sf apex run test failed: " .. (result.stderr or "unknown"))
    return
  end

  local parsed = result.parsed
  if not parsed or not parsed.result then
    util.notify("error", "Could not parse sf apex run test output")
    return
  end

  local summary_line, failed = summarize(parsed.result)
  if failed == 0 then
    util.notify("info", summary_line)
  else
    util.notify("error", summary_line)
  end

  local scratch_lines = {}
  local failures = render_failures(parsed.result)
  for _, l in ipairs(failures) do
    table.insert(scratch_lines, l)
  end
  local coverage = render_coverage(parsed.result)
  if #coverage > 0 then
    if #scratch_lines > 0 then
      table.insert(scratch_lines, "")
    end
    for _, l in ipairs(coverage) do
      table.insert(scratch_lines, l)
    end
  end
  if #scratch_lines > 0 then
    show_scratch("tests-all-result", scratch_lines)
  end
end

return M