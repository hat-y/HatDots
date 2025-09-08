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

	-- Enter inteligente (seguir link / toggle checkbox / etc.)
	map("n", "<CR>", function()
		return util.smart_action()
	end, { expr = true, desc = "Obsidian smart action" })

	-- Toggle checkbox (usamos el comando del plugin: robusto)
	map("n", "<leader>ch", "<cmd>ObsidianToggleCheckbox<CR>", { desc = "Obsidian: toggle checkbox" })

	map("n", "<leader>oo", "<cmd>ObsidianOpen<CR>", { desc = "Obsidian: abrir app" })
	map("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "Obsidian: nueva nota" })
	map("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Obsidian: quick switch" })
	map("n", "<leader>os", "<cmd>ObsidianSearch<CR>", { desc = "Obsidian: buscar" })
	map("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>", { desc = "Obsidian: insertar template" })
	map("n", "<leader>od", "<cmd>ObsidianToday<CR>", { desc = "Obsidian: daily (hoy)" })
	map("n", "<leader>oD", "<cmd>ObsidianTomorrow<CR>", { desc = "Obsidian: daily (mañana)" })
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
	-- attach inmediato por si ya estás en un .md al cargar Neovim
	vim.schedule(function()
		attach(vim.api.nvim_get_current_buf())
	end)
end

return M
