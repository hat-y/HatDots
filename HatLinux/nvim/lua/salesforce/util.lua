-- salesforce.util — shared helpers for running sf CLI and surfacing results.
-- All pickers and the org module go through run_sf. No direct vim.fn.system calls.

local M = {}

--- Run an `sf` CLI command and capture output.
--- @param args string[]              -- args to pass to `sf`, e.g. { "org", "list", "--json" }
--- @param opts? { cwd?: string, input?: string, timeout_ms?: integer }
--- @return { ok: boolean, stdout: string, stderr: string, code: integer, parsed: any|nil }
function M.run_sf(args, opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local timeout_ms = opts.timeout_ms or 30000

  local cmd = { "sf" }
  for _, a in ipairs(args) do
    table.insert(cmd, a)
  end

  -- vim.system(cmd, opts, on_exit). on_exit must be a function or nil;
  -- passing {} is an error. Use opts only, let on_exit default.
  local result = vim.system(cmd, {
    cwd = cwd,
    input = opts.input,
    timeout = timeout_ms,
  }):wait()

  local stdout = result.stdout or ""
  local stderr = result.stderr or ""
  local code = result.code or 0

  local parsed = nil
  local last_arg = args[#args]
  if last_arg == "--json" and stdout ~= "" then
    local ok, decoded = pcall(vim.json.decode, stdout)
    if ok then
      parsed = decoded
    end
  end

  return {
    ok = code == 0,
    stdout = stdout,
    stderr = stderr,
    code = code,
    parsed = parsed,
  }
end

--- Notify the user with a salesforce-tagged message.
--- @param level "info"|"warn"|"error"
--- @param msg string
function M.notify(level, msg)
  vim.notify("[salesforce] " .. msg, vim.log.levels[level:upper()] or vim.log.levels.INFO)
end

--- Show a structured failure with a clickable qflist entry.
--- @param title string
--- @param lines string[]
function M.qf_failure(title, lines)
  local qf = {}
  for i, line in ipairs(lines) do
    table.insert(qf, {
      filename = "",
      lnum = i,
      col = 1,
      text = line,
      type = "E",
    })
  end
  vim.fn.setqflist(qf, " ")
  vim.notify("[salesforce] " .. title, vim.log.levels.ERROR)
  vim.cmd("copen")
end

return M