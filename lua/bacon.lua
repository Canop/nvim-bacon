-- A companion to bacon - https://dystroy.org/bacon

local api = vim.api
local buf, win

local locations
local location_idx = 0 -- 1-indexed, 0 is "none"

local function center(str, width)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  local remain = width - shift - string.len(str)
  return string.rep(' ', shift) .. str .. string.rep(' ', remain)
end

local function open_window()
  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'bacon')

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
    col = col
  }

  win = api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  local width = api.nvim_win_get_width(0)
  api.nvim_buf_set_lines(buf, 0, -1, false, { center('Bacon Locations (hit q to close)', width), '', ''})
  api.nvim_buf_add_highlight(buf, -1, 'BaconHeader', 0, 0, -1)
end


local function close_window()
  api.nvim_win_close(win, true)
end

-- Tell whether a file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
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

local function move_cursor()
  local new_pos = math.max(3, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, {new_pos, 0})
end

local function set_mappings()
  local mappings = {
    ['<cr>'] = 'open_selected_location()',
    q = 'close_window()',
    k = 'move_cursor()'
  }

  for k,v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"bacon".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

-- Open a specific location and remember it as "last
local function open_location(idx)
  local location = locations[idx]
  api.nvim_command('edit ' .. location.path)
  api.nvim_win_set_cursor(0, {location.line, location.col - 1})
  location_idx = idx
end

-- Open the location under the cursor in the location window
local function open_selected_location()
  local i = api.nvim_win_get_cursor(win)[1] - 2
  close_window()
  if (i > 0 and i <= #locations) then
      open_location(i)
  end
end

local function same_location(a, b)
  return a and b and a.path == b.path and a.line == b.line and a.col == b.col
end

-- Load the locations found in the .bacon-locations file.
-- Doesn't modify the display, only the location table.
-- We look in the current work directory and in the parent directories.
local function bacon_load()
  local old_location = nil
  if location_idx > 0 then
    old_location = locations[location_idx]
  end
  locations = {}
  local dir = ''
  repeat 
    local file = dir .. '.bacon-locations'
    if file_exists(file) then
      local raw_lines = lines_from(file)
      for i, raw_line in ipairs(raw_lines) do
        -- each line is like "error lua/bacon.lua:61:15"
        local cat, path, line, col = string.match(raw_line, '(%S+) (%S+):(%d+):(%d+)')
        if #cat > 0 then
          local location = { cat=cat, path=dir..path, line=tonumber(line), col=tonumber(col) }
          table.insert(locations, location)
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
    dir = '../' .. dir
  until not file_exists(dir)
end

-- Fill our buf with the locations, one per line
local function update_view()
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  local lines = {}
  for i, location in ipairs(locations) do
     local shield = center(''..i, 5)
     table.insert(lines, ' ' .. shield .. location.path .. ':' .. location.line .. ':' .. location.col)
  end
  api.nvim_buf_set_lines(buf, 2, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

-- Show the window with the locations, assuming they have been previously loaded
local function bacon_show()
  if #locations > 0 then
    open_window()
    update_view()
    set_mappings()
    api.nvim_win_set_cursor(win, {3, 0})
  else
    print('Error: no bacon locations loaded')
  end
end

-- Load the locations, then show them
local function bacon_list()
  bacon_load()
  bacon_show()
end

local function bacon_previous()
  if #locations > 0 then
    location_idx = location_idx - 1
    if location_idx < 1 then
      location_idx = #locations
    end
    open_location(location_idx)
  else
    print('Error: no bacon locations loaded')
  end
end

local function bacon_next()
  if #locations > 0 then
    location_idx = location_idx + 1
    if location_idx > #locations then
      location_idx = 1
    end
    open_location(location_idx)
  else
    print('Error: no bacon locations loaded')
  end
end

-- Return the public API
return {
  bacon_load = bacon_load,
  bacon_list = bacon_list,
  bacon_show = bacon_show,
  bacon_previous = bacon_previous,
  bacon_next = bacon_next,
  open_selected_location = open_selected_location,
  move_cursor = move_cursor,
  close_window = close_window
}
