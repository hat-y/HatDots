-- Markdown utility functions shared between plugins/markdown.lua and plugins/obsidian.lua
local M = {}

function M.toggle_checkbox()
	local line = vim.api.nvim_get_current_line()

	if line:match("^%s*-%s+%[x%]") then
		vim.api.nvim_set_current_line(line:gsub("(%s*-%s+)%[x%](%s*)", "%1[ ]%2"))
	elseif line:match("^%s*-%s+%[ %]") then
		vim.api.nvim_set_current_line(line:gsub("(%s*-%s+)%[ %](%s*)", "%1[x]%2"))
	else
		local row = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_buf_set_text(0, row - 1, 0, row - 1, 0, { "- [ ] " })
	end
end

function M.insert_checkbox()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { "- [ ] " })
	vim.api.nvim_win_set_cursor(0, { row, col + 6 })
end

function M.insert_blockquote()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { "> " })
	vim.api.nvim_win_set_cursor(0, { row, col + 2 })
end

function M.insert_heading(opts)
	opts = opts or {}
	local level = opts.level or 2
	if level < 1 or level > 6 then
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local heading = string.rep("#", level) .. " "
	vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { heading })
	vim.api.nvim_win_set_cursor(0, { row, col + #heading })
end

-- Convenience wrappers
function M.insert_h1()
	M.insert_heading({ level = 1 })
end
function M.insert_h2()
	M.insert_heading({ level = 2 })
end
function M.insert_h3()
	M.insert_heading({ level = 3 })
end
function M.insert_h4()
	M.insert_heading({ level = 4 })
end
function M.insert_h5()
	M.insert_heading({ level = 5 })
end
function M.insert_h6()
	M.insert_heading({ level = 6 })
end

-- Generate Table of Contents from headings in current buffer
function M.generate_toc()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local toc = {}

	for i, line in ipairs(lines) do
		local level = line:match("^#*")
		if level then
			local heading = line:gsub("^#+%s*", "")
			local heading_id = heading:lower():gsub("%s+", "-"):gsub("[^%a%-]", "")
			table.insert(toc, string.rep("  ", (#level / 2) - 1) .. "- [" .. heading .. "](#" .. heading_id .. ")")
		end
	end

	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	table.insert(toc, 1, "---")
	table.insert(toc, 1, "## Table of Contents")
	table.insert(toc, 1, "---")

	vim.api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, toc)
	vim.cmd("normal! zz")
end

return M
