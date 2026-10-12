-- salesforce.terminal — toggleterm wrapper for running sf CLI interactively.
-- Maintains a single toggleterm instance preloaded with SF_TARGET_ORG env.

local M = {}

local terminal_handle = nil
local target_org_at_open = nil

local function build_env()
  local env = {}
  for k, v in pairs(vim.fn.environ()) do
    env[k] = v
  end
  local org = vim.g.sf_target_org or vim.b.sf_target_org
  if org and org ~= "" then
    env.SF_TARGET_ORG = org
  end
  return env
end

local function ensure_terminal()
  local ok, toggleterm = pcall(require, "toggleterm.terminal")
  if not ok then
    require("salesforce.util").notify("error", "toggleterm.nvim not loaded")
    return nil
  end
  if terminal_handle then
    return terminal_handle
  end
  terminal_handle = toggleterm.Terminal:new({
    cmd = vim.o.shell,
    dir = vim.fn.getcwd(),
    env = build_env(),
    hidden = true,
    direction = "float",
    close_on_exit = false,
    count = 99, -- distinct from LazyVim default (1) and any other terminals
  })
  target_org_at_open = vim.g.sf_target_org or vim.b.sf_target_org
  return terminal_handle
end

local function update_env_in_terminal()
  if not terminal_handle then
    return
  end
  local current = vim.g.sf_target_org or vim.b.sf_target_org
  if current ~= target_org_at_open then
    if terminal_handle:is_open() then
      -- chansend on the terminal job
      local chan = terminal_handle.job_id
      if chan and chan > 0 then
        local cmd = current and ("export SF_TARGET_ORG=" .. current .. "\n")
          or "unset SF_TARGET_ORG\n"
        vim.fn.chansend(chan, cmd)
      end
    end
    target_org_at_open = current
  end
end

function M.toggle()
  local t = ensure_terminal()
  if not t then
    return
  end
  -- Update env before toggling open
  update_env_in_terminal()
  t:toggle()
end

-- Hook into the org-changed autocmd so the running terminal picks up the new org.
vim.api.nvim_create_autocmd("User", {
  pattern = "SfTargetOrgChanged",
  group = vim.api.nvim_create_augroup("SalesforceTerminal", { clear = true }),
  callback = function()
    update_env_in_terminal()
  end,
})

return M