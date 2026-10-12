local M = {}

local function attach(buf)
	if not buf or not vim.api.nvim_buf_is_loaded(buf) then
		return
	end
	if vim.bo[buf].filetype ~= "markdown" then
		return
	end

	local ok, obs = pcall(require, "obsidian")
	if not ok then
		return
	end

	local util = obs.util
	local function map(mode, lhs, rhs, opts)
		opts = opts or {}
		opts.buffer = buf
		opts.silent = opts.silent ~= false
		vim.keymap.set(mode, lhs, rhs, opts)
	end

	map("n", "gf", function()
		return util.gf_passthrough()
	end, { expr = true, noremap = false, desc = "Obsidian follow (gf)" })

	-- Smart Enter (follow link / toggle checkbox / etc.)
	map("n", "<CR>", function()
		return util.smart_action()
	end, { expr = true, desc = "Obsidian smart action" })

	-- Toggle checkbox (we use plugin command: robust)
	map("n", "<leader>ch", "<cmd>ObsidianToggleCheckbox<CR>", { desc = "Obsidian: toggle checkbox" })

	map("n", "<leader>oo", "<cmd>ObsidianOpen<CR>", { desc = "Obsidian: open app" })
	map("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "Obsidian: new note" })
	map("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Obsidian: quick switch" })
	map("n", "<leader>os", "<cmd>ObsidianSearch<CR>", { desc = "Obsidian: search" })
	map("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>", { desc = "Obsidian: insert template" })
	map("n", "<leader>od", "<cmd>ObsidianToday<CR>", { desc = "Obsidian: daily (today)" })
	map("n", "<leader>oD", "<cmd>ObsidianTomorrow<CR>", { desc = "Obsidian: daily (tomorrow)" })
end

function M.setup_autocmd()
	local aug = vim.api.nvim_create_augroup("HatObsidianMaps", { clear = true })
	vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
		group = aug,
		pattern = "markdown",
		callback = function(ev)
			attach(ev.buf)
		end,
	})
	-- immediate attach in case you're already in a .md when loading Neovim
	vim.schedule(function()
		attach(vim.api.nvim_get_current_buf())
	end)
end

return M
