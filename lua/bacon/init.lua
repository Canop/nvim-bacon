-- A companion to bacon - https://dystroy.org/bacon
local config = require("bacon.config")
-- local options = config.options

local Bacon = {}

local api = vim.api
local buf, win

local locations
local location_idx = 0 -- 1-indexed, 0 is "none"

function Bacon.setup(opts)
	config.setup(opts)
end

local function center(str, width)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	local remain = width - shift - string.len(str)
	return string.rep(" ", shift) .. str .. string.rep(" ", remain)
end

local function open_window()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "bacon")

	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	local win_height = math.ceil(height * 0.8 - 4)
	local win_width = math.ceil(width * 0.8)
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
	}

	win = api.nvim_open_win(buf, true, opts)
	vim.api.nvim_win_set_option(win, "cursorline", true)
	local width = api.nvim_win_get_width(0)
	api.nvim_buf_set_lines(buf, 0, -1, false, { center("Bacon Locations (hit q to close)", width), "", "" })
	api.nvim_buf_add_highlight(buf, -1, "BaconHeader", 0, 0, -1)
end

function Bacon.close_window()
	api.nvim_win_close(win, true)
end

-- Tell whether a file exists
function file_exists(file)
	local f = io.open(file, "rb")
	if f then
		f:close()
	end
	return f ~= nil
end

-- get all lines from a file
function lines_from(file)
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

function Bacon.move_cursor()
	local new_pos = math.max(3, api.nvim_win_get_cursor(win)[1] - 1)
	api.nvim_win_set_cursor(win, { new_pos, 0 })
end

local function set_mappings()
	local mappings = {
		["<cr>"] = "open_selected_location()",
		q = "close_window()",
		k = "move_cursor()",
	}
	for digit = 1, 9 do
		mappings["" .. digit] = 'close_window() require"bacon".open_location(' .. digit .. ")"
	end

	for k, v in pairs(mappings) do
		api.nvim_buf_set_keymap(buf, "n", k, ':lua require"bacon".' .. v .. "<cr>", {
			nowait = true,
			noremap = true,
			silent = true,
		})
	end
	local other_chars = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"i",
		"n",
		"o",
		"p",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
		"z",
	}
	for k, v in ipairs(other_chars) do
		api.nvim_buf_set_keymap(buf, "n", v, "", { nowait = true, noremap = true, silent = true })
		api.nvim_buf_set_keymap(buf, "n", v:upper(), "", { nowait = true, noremap = true, silent = true })
		api.nvim_buf_set_keymap(buf, "n", "<c-" .. v .. ">", "", { nowait = true, noremap = true, silent = true })
	end
end

-- Open a specific location and remember it as "last
function Bacon.open_location(idx)
	local location = locations[idx]
	api.nvim_command("edit " .. location.filename)
	api.nvim_win_set_cursor(0, { location.lnum, location.col - 1 })
	location_idx = idx
end

-- Open the location under the cursor in the location window
function Bacon.open_selected_location()
	local i = api.nvim_win_get_cursor(win)[1] - 2
	Bacon.close_window()
	if i > 0 and i <= #locations then
		Bacon.open_location(i)
	end
end

local function same_location(a, b)
	return a and b and a.path == b.path and a.line == b.line and a.col == b.col
end

-- Load the locations found in the .bacon-locations file.
-- Doesn't modify the display, only the location table.
-- We look in the current work directory and in the parent directories.
function Bacon.bacon_load()
	local old_location = nil
	if location_idx > 0 then
		old_location = locations[location_idx]
	end
	locations = {}
	local dir = ""
	repeat
		local file = dir .. ".bacon-locations"
		if file_exists(file) then
			local raw_lines = lines_from(file)
			for i, raw_line in ipairs(raw_lines) do
				-- each line is like "error lua/bacon.lua:61:15 the faucet is leaking"
				-- print('parse raw "' .. raw_line .. '"')
				local cat, path, line, col, text = string.match(raw_line, "(%S+) (%S+):(%d+):(%d+)%s*(.*)")
				if cat ~= nil and #cat > 0 then
					local loc_path = path
					if string.sub(loc_path, 1, 1) ~= "/" then
						loc_path = dir .. loc_path
					end
					local location = {
						cat = cat,
						filename = loc_path,
						lnum = tonumber(line),
						col = tonumber(col),
					}
					if text ~= "" then
						location.text = text
					else
						location.text = ""
					end
					table.insert(locations, location)
				end
			end
			if config.options.quickfix.enabled then
				vim.fn.setqflist(locations, " ")
				vim.fn.setqflist({}, "a", { title = "Bacon" })
				if config.options.quickfix.event_trigger then
					-- triggers the Neovim event for populating the quickfix list
					vim.cmd("doautocmd QuickFixCmdPost")
				end
			end
			location_idx = 0
			if old_location then
				for idx, location in ipairs(locations) do
					if same_location(location, old_location) then
						location_idx = idx
						break
					end
				end
			end
			break
		end
		dir = "../" .. dir
	until not file_exists(dir)
end

-- Fill our buf with the locations, one per line
local function update_view()
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	local cwd = vim.fn.getcwd() .. "/"
	local lines = {}
	for i, location in ipairs(locations) do
		local cat = string.upper(location.cat):sub(1, 1)
		local path = location.filename
		if string.find(path, cwd) == 1 then
			path = string.gsub(location.filename, cwd, "")
		end
		local shield = center("" .. i, 5)
		table.insert(
			lines,
			" " .. cat .. shield .. path .. ":" .. location.lnum .. ":" .. location.col .. " | " .. location.text
		)
	end
	api.nvim_buf_set_lines(buf, 2, -1, false, lines)
	api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Show the window with the locations, assuming they have been previously loaded
function Bacon.bacon_show()
	if #locations > 0 then
		location_idx = 0
		open_window()
		update_view()
		set_mappings()
		api.nvim_win_set_option(win, "wrap", false)
		api.nvim_win_set_cursor(win, { 3, 1 })
	else
		print("Error: no bacon locations loaded")
	end
end

-- Load the locations, then show them
function Bacon.bacon_list()
	Bacon.bacon_load()
	Bacon.bacon_show()
end

function Bacon.bacon_previous()
	if #locations > 0 then
		location_idx = location_idx - 1
		if location_idx < 1 then
			location_idx = #locations
		end
		Bacon.open_location(location_idx)
	else
		print("Error: no bacon locations loaded")
	end
end

function Bacon.bacon_next()
	if #locations > 0 then
		location_idx = location_idx + 1
		if location_idx > #locations then
			location_idx = 1
		end
		Bacon.open_location(location_idx)
	else
		print("Error: no bacon locations loaded")
	end
end

-- Return the public API
return Bacon
