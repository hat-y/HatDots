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

return {
	"markdown-keymaps",
	ft = { "markdown", "markdown.mdx" },
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "markdown", "markdown.mdx" },
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				local km = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
				end

				km("i", ",1", function()
					M.insert_heading({ level = 1 })
				end, "Insert H1")
				km("i", ",2", function()
					M.insert_heading({ level = 2 })
				end, "Insert H2")
				km("i", ",3", function()
					M.insert_heading({ level = 3 })
				end, "Insert H3")
				km("i", ",4", function()
					M.insert_heading({ level = 4 })
				end, "Insert H4")
				km("i", ",5", function()
					M.insert_heading({ level = 5 })
				end, "Insert H5")
				km("i", ",6", function()
					M.insert_heading({ level = 6 })
				end, "Insert H6")
				km("i", ",q", M.insert_blockquote, "Insert blockquote")
				km("n", ",c", M.toggle_checkbox, "Toggle checkbox")
			end,
		})

		package.loaded["markdown-keymaps"] = M
	end,
}
