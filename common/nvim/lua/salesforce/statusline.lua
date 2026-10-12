-- salesforce.statusline — lualine component showing the active Salesforce org.
-- Hidden when not in a Salesforce project or when no org is targeted.
-- Falls back gracefully if lualine API differs from expected.

local M = {}
local health = require("salesforce.health")

local function is_visible()
  local s = health.check()
  return s.sfdx_project
end

local function component()
  if not is_visible() then
    return ""
  end
  local org = vim.b.sf_target_org or vim.g.sf_target_org or health.check().target_org
  if not org or org == "" then
    return "[SF:default]"
  end
  return "[SF:" .. org .. "]"
end
M.component = component
M.is_visible = is_visible

local function try_lualine_v3()
  -- lualine v3 exposes sections table; we append a custom component to lualine_c.
  local ok_sections, sections = pcall(require, "lualine.sections")
  if not ok_sections or type(sections) ~= "table" then
    return false
  end
  sections.lualine_c = sections.lualine_c or {}
  table.insert(sections.lualine_c, {
    component,
    cond = is_visible,
    icon = " ",
    color = function()
      local s = health.check()
      if s.target_org then
        return { fg = "#00AFFA" }
      end
      return { fg = "#808080" }
    end,
  })
  -- Trigger a lualine refresh so the new component renders.
  pcall(function()
    require("lualine").refresh()
  end)
  return true
end

local function try_vim_opt_statusline()
  -- Fallback: append a %{...} expression to vim.opt.statusline.
  -- This works when lualine is NOT controlling the statusline (e.g., plain nvim).
  pcall(vim.api.nvim_set_option_value, "statusline", "%{v:lua.require'salesforce.statusline'.component()}", { append = true })
end

function M.setup()
  if try_lualine_v3() then
    return
  end
  try_vim_opt_statusline()
end

return M