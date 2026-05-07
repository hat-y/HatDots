local M = {}

local function is_separator(line)
	local trimmed = line:match("^%s*(.-)%s*$")
	if not trimmed then return false end
	local without_pipes = trimmed:gsub("|", "")
	return without_pipes:match("^[%s%-%:]+$") ~= nil
		and trimmed:find("|") ~= nil
		and trimmed:find("-") ~= nil
end

local function get_table_bounds()
	local buf = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	if not lines[row] or not lines[row]:match("^%s*|") then
		return nil, nil
	end

	local start_row = row
	while start_row > 0 and lines[start_row - 1] and lines[start_row - 1]:match("^%s*|") do
		start_row = start_row - 1
	end

	local end_row = row
	while end_row < #lines - 1 and lines[end_row + 1] and lines[end_row + 1]:match("^%s*|") do
		end_row = end_row + 1
	end

	return start_row, end_row
end

local function parse_cells(line)
	local cells = {}
	local trimmed = line:match("^%s*|(.*)|%s*$")
	if not trimmed then return cells end
	for cell in trimmed:gmatch("[^|]+") do
		cells[#cells + 1] = cell:match("^%s*(.-)%s*$") or ""
	end
	return cells
end

local function count_columns(line)
	return #parse_cells(line)
end

local function find_separator(start_row, end_row)
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)
	for i, line in ipairs(lines) do
		if is_separator(line) then
			return start_row + i - 1
		end
	end
	return nil
end

local function add_row()
	local start_row, end_row = get_table_bounds()
	if not start_row then return end

	local buf = vim.api.nvim_get_current_buf()
	local sep_row = find_separator(start_row, end_row)
	if not sep_row then return end

	local sep_line = vim.api.nvim_buf_get_lines(buf, sep_row, sep_row + 1, false)[1]
	local cols = count_columns(sep_line)
	if cols == 0 then return end

	local row_str = ""
	for _ = 1, cols do
		row_str = row_str .. "| "
	end
	row_str = row_str .. "|"

	local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	if cur_row < start_row or cur_row > end_row then return end

	local insert_at = cur_row
	if insert_at < sep_row then
		insert_at = sep_row
	end

	vim.api.nvim_buf_set_lines(buf, insert_at + 1, insert_at + 1, false, { row_str })
	vim.api.nvim_win_set_cursor(0, { insert_at + 2, 2 })
end

local function delete_row()
	local start_row, end_row = get_table_bounds()
	if not start_row then return end

	local buf = vim.api.nvim_get_current_buf()
	local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	if cur_row < start_row or cur_row > end_row then return end

	local sep_row = find_separator(start_row, end_row)
	if not sep_row then return end
	if cur_row < sep_row then return end

	local data_rows = end_row - sep_row

	if data_rows <= 1 then
		vim.api.nvim_buf_set_lines(buf, sep_row, end_row + 1, false, {})
		if sep_row == start_row + 1 then
			vim.api.nvim_buf_set_lines(buf, start_row, start_row + 1, false, {})
		end
	else
		vim.api.nvim_buf_set_lines(buf, cur_row, cur_row + 1, false, {})
	end
end

local function add_column()
	local start_row, end_row = get_table_bounds()
	if not start_row then return end

	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)

	local new_lines = {}
	for _, line in ipairs(lines) do
		local last_pipe = 0
		for i = 1, #line do
			if line:sub(i, i) == "|" then
				last_pipe = i
			end
		end
		if last_pipe == 0 then
			new_lines[#new_lines + 1] = line
		else
			local prefix = line:sub(1, last_pipe - 1):gsub("%s+$", "")
			if is_separator(line) then
				new_lines[#new_lines + 1] = prefix .. " | --- |"
			else
				new_lines[#new_lines + 1] = prefix .. " |  |"
			end
		end
	end

	vim.api.nvim_buf_set_lines(buf, start_row, end_row + 1, false, new_lines)
end

local function delete_column()
	local start_row, end_row = get_table_bounds()
	if not start_row then return end

	local buf = vim.api.nvim_get_current_buf()
	local cur = vim.api.nvim_win_get_cursor(0)
	local cur_row = cur[1] - 1
	local cur_col = cur[2]

	if cur_row < start_row or cur_row > end_row then return end

	local line = vim.api.nvim_buf_get_lines(buf, cur_row, cur_row + 1, false)[1]
	local prefix = line:sub(1, cur_col + 1)

	local col_idx = 0
	for _ in prefix:gmatch("|") do
		col_idx = col_idx + 1
	end
	if col_idx == 0 then col_idx = 1 end

	local first_line = vim.api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1]
	local total_cols = count_columns(first_line)
	if total_cols <= 1 then return end
	if col_idx > total_cols then col_idx = total_cols end

	local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)
	local new_lines = {}

	for _, l in ipairs(lines) do
		local pipes = {}
		for i = 1, #l do
			if l:sub(i, i) == "|" then
				pipes[#pipes + 1] = i
			end
		end
		if col_idx <= #pipes and col_idx + 1 <= #pipes then
			new_lines[#new_lines + 1] = l:sub(1, pipes[col_idx]) .. l:sub(pipes[col_idx + 1] + 1)
		else
			new_lines[#new_lines + 1] = l
		end
	end

	vim.api.nvim_buf_set_lines(buf, start_row, end_row + 1, false, new_lines)
end

local function align_table()
	local start_row, end_row = get_table_bounds()
	if not start_row then return end

	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)

	local all_cells = {}
	for _, line in ipairs(lines) do
		all_cells[#all_cells + 1] = parse_cells(line)
	end

	local num_cols = 0
	for _, cells in ipairs(all_cells) do
		if #cells > num_cols then num_cols = #cells end
	end
	if num_cols == 0 then return end

	local max_widths = {}
	for c = 1, num_cols do
		max_widths[c] = 1
		for r = 1, #all_cells do
			local cell = all_cells[r][c] or ""
			local w = #cell
			if w > max_widths[c] then max_widths[c] = w end
		end
	end

	local new_lines = {}
	for r, line in ipairs(lines) do
		if is_separator(line) then
			local parts = {}
			for c = 1, num_cols do
				local cell = all_cells[r][c] or ""
				local left = cell:match("^:") or ""
				local right = cell:match(":$") or ""
				local dash_width = math.max(3, max_widths[c] - #left - #right)
				parts[#parts + 1] = left .. string.rep("-", dash_width) .. right
			end
			new_lines[#new_lines + 1] = "| " .. table.concat(parts, " | ") .. " |"
		else
			local parts = {}
			for c = 1, num_cols do
				local cell = all_cells[r][c] or ""
				parts[#parts + 1] = cell .. string.rep(" ", max_widths[c] - #cell)
			end
			new_lines[#new_lines + 1] = "| " .. table.concat(parts, " | ") .. " |"
		end
	end

	vim.api.nvim_buf_set_lines(buf, start_row, end_row + 1, false, new_lines)
end

local function get_cell_positions(line)
	local positions = {}
	for i = 1, #line do
		if line:sub(i, i) == "|" then
			positions[#positions + 1] = i
		end
	end
	return positions
end

local function get_current_cell_index()
	local line = vim.api.nvim_get_current_line()
	local cur_col = vim.api.nvim_win_get_cursor(0)[2]
	local positions = get_cell_positions(line)

	if #positions < 2 then return 1 end

	for i = 1, #positions - 1 do
		if cur_col >= positions[i] and cur_col < positions[i + 1] then
			return i
		end
	end
	return #positions - 1
end

local function next_cell()
	local line = vim.api.nvim_get_current_line()
	local positions = get_cell_positions(line)
	if #positions < 2 then return end

	local idx = get_current_cell_index()
	if idx < #positions - 1 then
		vim.api.nvim_win_set_cursor(0, {
			vim.api.nvim_win_get_cursor(0)[1],
			positions[idx + 1] + 1,
		})
	end
end

local function prev_cell()
	local line = vim.api.nvim_get_current_line()
	local positions = get_cell_positions(line)
	if #positions < 2 then return end

	local idx = get_current_cell_index()
	if idx > 1 then
		vim.api.nvim_win_set_cursor(0, {
			vim.api.nvim_win_get_cursor(0)[1],
			positions[idx] + 1,
		})
	end
end

local function cell_down()
	local cur = vim.api.nvim_win_get_cursor(0)
	local buf = vim.api.nvim_get_current_buf()
	local next_row = cur[1] + 1
	local next_lines = vim.api.nvim_buf_get_lines(buf, next_row - 1, next_row, false)
	if #next_lines == 0 or not next_lines[1]:match("^%s*|") then return end

	local positions = get_cell_positions(next_lines[1])
	local idx = get_current_cell_index()
	if idx <= #positions then
		vim.api.nvim_win_set_cursor(0, { next_row, positions[idx] + 1 })
	end
end

local function cell_up()
	local cur = vim.api.nvim_win_get_cursor(0)
	local buf = vim.api.nvim_get_current_buf()
	local prev_row = cur[1] - 1
	if prev_row < 1 then return end

	local prev_lines = vim.api.nvim_buf_get_lines(buf, prev_row - 1, prev_row, false)
	if #prev_lines == 0 or not prev_lines[1]:match("^%s*|") then return end

	local positions = get_cell_positions(prev_lines[1])
	local idx = get_current_cell_index()
	if idx <= #positions then
		vim.api.nvim_win_set_cursor(0, { prev_row, positions[idx] + 1 })
	end
end

local function setup()
	local buf = vim.api.nvim_get_current_buf()
	local km = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
	end

	km("n", ",tr", add_row, "Table: add row")
	km("n", ",tR", delete_row, "Table: delete row")
	km("n", ",tc", add_column, "Table: add column")
	km("n", ",tC", delete_column, "Table: delete column")
	km("n", ",ta", align_table, "Table: align table")
	km("n", ",tj", cell_down, "Table: cell down")
	km("n", ",tk", cell_up, "Table: cell up")
	km("n", ",th", next_cell, "Table: next cell")
	km("n", ",tl", prev_cell, "Table: previous cell")
end

return {
	"markdown-tables",
	ft = "markdown",
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = setup,
		})
	end,
}
