-- salesforce.scaffolds — local scaffolding for new metadata files.
-- All functions create files inside the project's package directory using
-- sfdx-project.json conventions, and open the resulting file in nvim.

local M = {}
local util = require("salesforce.util")

--- Read sfdx-project.json from cwd and return the relevant fields.
--- Falls back to standard defaults if the file is missing or malformed.
--- @return { packageDir: string, apiVersion: string }
local function read_project_config()
  local cwd = vim.fn.getcwd()
  local path = cwd .. "/sfdx-project.json"
  if vim.fn.filereadable(path) == 0 then
    return { packageDir = "force-app", apiVersion = "67.0" }
  end
  local lines = vim.fn.readfile(path)
  local content = table.concat(lines, "\n")
  local ok, parsed = pcall(vim.fn.json_decode, content)
  if not ok or type(parsed) ~= "table" then
    return { packageDir = "force-app", apiVersion = "67.0" }
  end
  local packageDir = "force-app"
  if parsed.packageDirectories and parsed.packageDirectories[1] then
    packageDir = parsed.packageDirectories[1].path or "force-app"
  end
  return {
    packageDir = packageDir,
    apiVersion = tostring(parsed.sourceApiVersion or "67.0"),
  }
end

--- Read git config user.name if available, else return "".
--- @return string
local function get_git_author()
  local handle = io.popen("git config user.name 2>/dev/null")
  if not handle then
    return ""
  end
  local ok, result = pcall(function() return handle:read("*a") end)
  handle:close()
  if not ok or not result then
    return ""
  end
  return vim.trim(result)
end

--- Prompt the user for a string. Aborts if empty.
--- @param label string
--- @param default? string
--- @return string|nil   -- nil when the user provided no input
local function prompt(label, default)
  local value = vim.fn.input(label, default or "")
  if value == "" then
    return nil
  end
  return value
end

--- Validate a Salesforce identifier (class, trigger, or base object name).
--- Allows letters, digits, and underscores; must start with a letter.
--- Use is_valid_object_name for SObject names that may carry the __c suffix.
--- @param name string
--- @return boolean
local function is_valid_identifier(name)
  if not name or name == "" then
    return false
  end
  return string.find(name, "^[A-Za-z][A-Za-z0-9_]*$") ~= nil
end

--- Validate a Salesforce SObject name (may carry the __c suffix).
--- @param name string
--- @return boolean
local function is_valid_object_name(name)
  if not name or name == "" then
    return false
  end
  if is_valid_identifier(name) then
    return true
  end
  return string.find(name, "^[A-Za-z][A-Za-z0-9_]*__c$") ~= nil
end

--- Convert a string to kebab-case for LWC naming convention.
--- @param name string
--- @return string
local function to_kebab(name)
  local s = name:gsub("_", "-")
  s = s:gsub("([a-z0-9])([A-Z])", "%1-%2")
  s = s:gsub("([A-Z]+)([A-Z][a-z])", "%1-%2")
  return s:lower()
end

--- Build a PascalCase identifier from a kebab-case or snake_case string.
--- @param name string
--- @return string
local function to_pascal(name)
  local parts = {}
  for p in name:gmatch("[^%-_]+") do
    table.insert(parts, p:sub(1, 1):upper() .. p:sub(2):lower())
  end
  return table.concat(parts, "")
end

--- @param name? string  -- optional override, used for headless tests
function M.new_apex_class(name)
  local cfg = read_project_config()
  if not name then
    name = prompt("New Apex class name: ")
  end
  if not name then
    return
  end
  name = name:gsub("%s+", "")
  if not is_valid_identifier(name) then
    util.notify("error", "Invalid class name: " .. name)
    return
  end
  local dir = cfg.packageDir .. "/main/default/classes/"
  vim.fn.mkdir(dir, "p")
  local cls_path = dir .. name .. ".cls"
  local meta_path = dir .. name .. ".cls-meta.xml"
  if vim.fn.filereadable(cls_path) == 1 then
    util.notify("error", "Class already exists: " .. cls_path)
    return
  end
  local author = get_git_author()
  local author_line = author ~= "" and (" * @author " .. author .. "\n") or ""
  local cls_content = table.concat({
    "/**",
    " * @description TODO: add description",
    " *" .. (author_line ~= "" and ("\n" .. author_line:sub(1, -2)) or ""),
    " */",
    "public with sharing class " .. name .. " {",
    "",
    "}",
    "",
  }, "\n")
  local meta_content = table.concat({
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">',
    "    <apiVersion>" .. cfg.apiVersion .. "</apiVersion>",
    "    <status>Active</status>",
    "</ApexClass>",
    "",
  }, "\n")
  vim.fn.writefile(vim.split(cls_content, "\n", { plain = true }), cls_path)
  vim.fn.writefile(vim.split(meta_content, "\n", { plain = true }), meta_path)
  vim.cmd("edit " .. vim.fn.fnameescape(cls_path))
  util.notify("info", "Created " .. name .. ".cls")
end

--- @param _name? string  -- optional override, used for headless tests
function M.new_lwc(_name)
  local cfg = read_project_config()
  local raw = _name or prompt("New LWC name (kebab-case): ")
  if not raw then
    return
  end
  local name = to_kebab(raw:gsub("%s+", ""))
  if name == "" or string.find(name, "[^%w%-]") then
    util.notify("error", "Invalid LWC name: " .. raw)
    return
  end
  local dir = cfg.packageDir .. "/main/default/lwc/" .. name .. "/"
  vim.fn.mkdir(dir, "p")
  local js_path = dir .. name .. ".js"
  if vim.fn.filereadable(js_path) == 1 then
    util.notify("error", "LWC already exists: " .. name)
    return
  end
  local class_name = to_pascal(name)
  local files = {
    [name .. ".html"] = table.concat({
      "<template>",
      "    ",
      "</template>",
      "",
    }, "\n"),
    [name .. ".js"] = table.concat({
      "import { LightningElement } from 'lwc';",
      "",
      "export default class " .. class_name .. " extends LightningElement {",
      "",
      "}",
      "",
    }, "\n"),
    [name .. ".css"] = "/* TODO: add styles */\n",
    [name .. ".svg"] = table.concat({
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">',
      "    <!-- TODO: add icon -->",
      "</svg>",
      "",
    }, "\n"),
    [name .. ".js-meta.xml"] = table.concat({
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">',
      "    <apiVersion>" .. cfg.apiVersion .. "</apiVersion>",
      "    <isExposed>false</isExposed>",
      "</LightningComponentBundle>",
      "",
    }, "\n"),
  }
  for fname, content in pairs(files) do
    local fpath = dir .. fname
    if vim.fn.filereadable(fpath) == 0 then
      vim.fn.writefile(vim.split(content, "\n", { plain = true }), fpath)
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(js_path))
  util.notify("info", "Created LWC bundle: " .. name)
end

function M.new_trigger(object_name, name)
  local cfg = read_project_config()
  if not object_name then
    object_name = prompt("Trigger on object (e.g., Account, MyObject__c): ")
  end
  if not object_name then
    return
  end
  if not is_valid_object_name(object_name) then
    util.notify("error", "Invalid object name: " .. object_name)
    return
  end
  local default_name = object_name .. "Trigger"
  if not name then
    name = prompt("Trigger name (default: " .. default_name .. "): ", default_name)
  end
  if not name then
    name = default_name
  end
  name = name:gsub("%s+", "")
  if not is_valid_identifier(name) then
    util.notify("error", "Invalid trigger name: " .. name)
    return
  end
  local dir = cfg.packageDir .. "/main/default/triggers/"
  vim.fn.mkdir(dir, "p")
  local trigger_path = dir .. name .. ".trigger"
  local meta_path = dir .. name .. ".trigger-meta.xml"
  if vim.fn.filereadable(trigger_path) == 1 then
    util.notify("error", "Trigger already exists: " .. trigger_path)
    return
  end
  local trigger_content = table.concat({
    "/**",
    " * @description TODO: add description",
    " */",
    "trigger " .. name .. " on " .. object_name
      .. " (before insert, before update, after insert, after update) {",
    "",
    "}",
    "",
  }, "\n")
  local meta_content = table.concat({
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">',
    "    <apiVersion>" .. cfg.apiVersion .. "</apiVersion>",
    "    <status>Active</status>",
    "</ApexTrigger>",
    "",
  }, "\n")
  vim.fn.writefile(vim.split(trigger_content, "\n", { plain = true }), trigger_path)
  vim.fn.writefile(vim.split(meta_content, "\n", { plain = true }), meta_path)
  vim.cmd("edit " .. vim.fn.fnameescape(trigger_path))
  util.notify("info", "Created trigger " .. name)
end

return M