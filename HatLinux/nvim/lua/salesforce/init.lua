-- salesforce.init — setup, keymaps, user commands.
-- Linux-only: on other platforms, keymaps and commands become no-ops.

local M = {}

local function is_linux()
  return vim.fn.has("linux") == 1
end

local function no_op()
  vim.notify("[salesforce] Linux-only feature on HatDots", vim.log.levels.WARN)
end

local function set_keymaps_linux()
  local ok_utils, utils = pcall(require, "config.utils")
  local map = ok_utils and utils.map or function(mode, lhs, rhs, opts)
    opts = opts or {}
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  map("n", "<leader>So", function()
    require("salesforce.org").open_picker()
  end, { desc = "Salesforce: Org picker" })

  map("n", "<leader>Sd", function()
    require("salesforce.org").display()
  end, { desc = "Salesforce: Display current org" })

  map("n", "<leader>Sp", function()
    require("salesforce.pickers").deploy()
  end, { desc = "Salesforce: Deploy" })

  map("n", "<leader>Sr", function()
    require("salesforce.pickers").retrieve()
  end, { desc = "Salesforce: Retrieve" })

  map("n", "<leader>SrR", function()
    require("salesforce.pickers").retrieve_selective()
  end, { desc = "Salesforce: Retrieve selective (by metadata type)" })

  map("n", "<leader>Sq", function()
    require("salesforce.pickers").soql()
  end, { desc = "Salesforce: SOQL query" })

  map("n", "<leader>Sa", function()
    require("salesforce.pickers").apex_run()
  end, { desc = "Salesforce: Run anonymous Apex" })

  map("n", "<leader>Sl", function()
    require("salesforce.pickers").log_picker()
  end, { desc = "Salesforce: Debug log picker" })

  map("n", "<leader>St", function()
    require("salesforce.terminal").toggle()
  end, { desc = "Salesforce: Toggle sf terminal" })

  map("n", "<leader>SO", function()
    require("salesforce.org").set_by_alias()
  end, { desc = "Salesforce: Set target-org by alias" })

  map("n", "<leader>SNA", function()
    require("salesforce.scaffolds").new_apex_class()
  end, { desc = "Salesforce: New Apex class" })

  map("n", "<leader>SNL", function()
    require("salesforce.scaffolds").new_lwc()
  end, { desc = "Salesforce: New LWC bundle" })

  map("n", "<leader>SNT", function()
    require("salesforce.scaffolds").new_trigger()
  end, { desc = "Salesforce: New Apex trigger" })

  map("n", "<leader>Ss", function()
    local tests = require("salesforce.tests")
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname:match("%.cls$") and vim.fn.fnamemodify(bufname, ":t:r"):match("Test$") then
      tests.run_buffer()
    else
      tests.run_picker()
    end
  end, { desc = "Salesforce: Run Apex tests (buffer or picker)" })

  map("n", "<leader>SsA", function()
    require("salesforce.tests").run_all()
  end, { desc = "Salesforce: Run all Apex tests" })

  map("n", "<leader>SsC", function()
    require("salesforce.tests").run_class()
  end, { desc = "Salesforce: Run Apex tests by class name" })
end

local function set_commands_linux()
  vim.api.nvim_create_user_command("SfHealth", function()
    require("salesforce.health").diagnose()
  end, { desc = "Salesforce: Health check" })

  vim.api.nvim_create_user_command("SfOrgPicker", function()
    require("salesforce.org").open_picker()
  end, { desc = "Salesforce: Org picker" })

  vim.api.nvim_create_user_command("SfOrgDisplay", function()
    require("salesforce.org").display()
  end, { desc = "Salesforce: Display current org" })

  vim.api.nvim_create_user_command("SfOrgSet", function(args)
    require("salesforce.org").set_by_alias(args.args)
  end, { nargs = "?", desc = "Salesforce: Set target-org by alias" })

  vim.api.nvim_create_user_command("SfDeploy", function()
    require("salesforce.pickers").deploy()
  end, { desc = "Salesforce: Deploy" })

  vim.api.nvim_create_user_command("SfRetrieve", function()
    require("salesforce.pickers").retrieve()
  end, { desc = "Salesforce: Retrieve" })

  vim.api.nvim_create_user_command("SfRetrieveSelective", function()
    require("salesforce.pickers").retrieve_selective()
  end, { desc = "Salesforce: Retrieve specific metadata by type" })

  vim.api.nvim_create_user_command("SfSoql", function()
    require("salesforce.pickers").soql()
  end, { desc = "Salesforce: SOQL query" })

  vim.api.nvim_create_user_command("SfApexRun", function()
    require("salesforce.pickers").apex_run()
  end, { desc = "Salesforce: Run anonymous Apex" })

  vim.api.nvim_create_user_command("SfNewApex", function()
    require("salesforce.scaffolds").new_apex_class()
  end, { desc = "Salesforce: New Apex class" })

  vim.api.nvim_create_user_command("SfNewLwc", function()
    require("salesforce.scaffolds").new_lwc()
  end, { desc = "Salesforce: New LWC bundle" })

  vim.api.nvim_create_user_command("SfNewTrigger", function()
    require("salesforce.scaffolds").new_trigger()
  end, { desc = "Salesforce: New Apex trigger" })

  vim.api.nvim_create_user_command("SfTestRun", function(args)
    local tests = require("salesforce.tests")
    if args.args and args.args ~= "" then
      tests.run_class(args.args)
    else
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname:match("%.cls$") and vim.fn.fnamemodify(bufname, ":t:r"):match("Test$") then
        tests.run_buffer()
      else
        tests.run_picker()
      end
    end
  end, { nargs = "?", desc = "Salesforce: Run Apex tests (buffer, picker, or by name)" })

  vim.api.nvim_create_user_command("SfTestRunAll", function()
    require("salesforce.tests").run_all()
  end, { desc = "Salesforce: Run all Apex tests in project" })

  vim.api.nvim_create_user_command("SfTestRunClass", function(args)
    require("salesforce.tests").run_class(args.args)
  end, { nargs = 1, desc = "Salesforce: Run a specific Apex test class by name" })

  vim.api.nvim_create_user_command("SfLogPicker", function()
    require("salesforce.pickers").log_picker()
  end, { desc = "Salesforce: Debug log picker" })
end

local function set_keymaps_no_op()
  -- On non-Linux: keymaps are no-ops with a notification.
  local no_op_map = function(lhs, desc)
    vim.keymap.set("n", lhs, no_op, { desc = desc, silent = true })
  end
  no_op_map("<leader>So", "Salesforce: Org picker (Linux only)")
  no_op_map("<leader>Sd", "Salesforce: Display org (Linux only)")
  no_op_map("<leader>Sp", "Salesforce: Deploy (Linux only)")
  no_op_map("<leader>Sr", "Salesforce: Retrieve (Linux only)")
  no_op_map("<leader>SrR", "Salesforce: Retrieve selective (Linux only)")
  no_op_map("<leader>Sq", "Salesforce: SOQL (Linux only)")
  no_op_map("<leader>Sa", "Salesforce: Apex run (Linux only)")
  no_op_map("<leader>Sl", "Salesforce: Log picker (Linux only)")
  no_op_map("<leader>St", "Salesforce: SF terminal (Linux only)")
  no_op_map("<leader>SO", "Salesforce: Set org (Linux only)")
  no_op_map("<leader>SNA", "Salesforce: New Apex class (Linux only)")
  no_op_map("<leader>SNL", "Salesforce: New LWC (Linux only)")
  no_op_map("<leader>SNT", "Salesforce: New trigger (Linux only)")
  no_op_map("<leader>Ss", "Salesforce: Run Apex tests (Linux only)")
  no_op_map("<leader>SsA", "Salesforce: Run all tests (Linux only)")
  no_op_map("<leader>SsC", "Salesforce: Run tests by class (Linux only)")
end

local function set_commands_no_op()
  vim.api.nvim_create_user_command("SfHealth", no_op, { desc = "Salesforce: Health (Linux only)" })
  vim.api.nvim_create_user_command("SfOrgPicker", no_op, { desc = "Salesforce: Org picker (Linux only)" })
  vim.api.nvim_create_user_command("SfOrgDisplay", no_op, { desc = "Salesforce: Org display (Linux only)" })
  vim.api.nvim_create_user_command("SfOrgSet", no_op, { nargs = "?", desc = "Salesforce: Set org (Linux only)" })
  vim.api.nvim_create_user_command("SfDeploy", no_op, { desc = "Salesforce: Deploy (Linux only)" })
  vim.api.nvim_create_user_command("SfRetrieve", no_op, { desc = "Salesforce: Retrieve (Linux only)" })
  vim.api.nvim_create_user_command("SfRetrieveSelective", no_op, { desc = "Salesforce: Retrieve selective (Linux only)" })
  vim.api.nvim_create_user_command("SfSoql", no_op, { desc = "Salesforce: SOQL (Linux only)" })
  vim.api.nvim_create_user_command("SfApexRun", no_op, { desc = "Salesforce: Apex run (Linux only)" })
  vim.api.nvim_create_user_command("SfLogPicker", no_op, { desc = "Salesforce: Log picker (Linux only)" })
      vim.api.nvim_create_user_command("SfNewApex", no_op, { desc = "Salesforce: New Apex class (Linux only)" })
      vim.api.nvim_create_user_command("SfNewLwc", no_op, { desc = "Salesforce: New LWC (Linux only)" })
      vim.api.nvim_create_user_command("SfNewTrigger", no_op, { desc = "Salesforce: New trigger (Linux only)" })
      vim.api.nvim_create_user_command("SfTestRun", no_op, { nargs = "?", desc = "Salesforce: Run tests (Linux only)" })
      vim.api.nvim_create_user_command("SfTestRunAll", no_op, { desc = "Salesforce: Run all tests (Linux only)" })
      vim.api.nvim_create_user_command("SfTestRunClass", no_op, { nargs = 1, desc = "Salesforce: Run tests by class (Linux only)" })
end

function M.setup(_)
  if is_linux() then
    require("salesforce.health").init()
    require("salesforce.lsp").setup()
    require("salesforce.statusline").setup()
    set_keymaps_linux()
    set_commands_linux()
  else
    set_keymaps_no_op()
    set_commands_no_op()
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "SfSalesforceReady" })
end

function M.health_check()
  if is_linux() then
    require("salesforce.health").diagnose()
  else
    no_op()
  end
end

-- Auto-setup on first Salesforce file open. This is the lazy-loading trigger.
vim.api.nvim_create_autocmd("BufReadPre", {
  group = vim.api.nvim_create_augroup("SalesforceAutoSetup", { clear = true }),
  pattern = { "*.cls", "*.trigger", "*.apex" },
  callback = function(args)
    if not is_linux() then
      return
    end
    -- Only setup once per session.
    if vim.g.sf_initialized then
      return
    end
    vim.g.sf_initialized = true
    M.setup()
  end,
})

-- Auto-setup on VimEnter when cwd contains sfdx-project.json. This makes
-- <leader>S* keymaps available immediately when entering a Salesforce project,
-- even before any .cls/.trigger/.apex file is opened.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("SalesforceAutoSetup", { clear = true }),
  callback = function()
    if not is_linux() then
      return
    end
    if vim.g.sf_initialized then
      return
    end
    -- findfile from current dir upward; returns "" if not found.
    if vim.fn.findfile("sfdx-project.json", ".;") ~= "" then
      vim.g.sf_initialized = true
      M.setup()
    end
  end,
})

return M