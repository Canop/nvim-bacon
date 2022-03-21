-- A companion to bacon
-- 
--
-- Note: the whole plugin's structure was based on this article:
-- https://dev.to/2nit/how-to-write-neovim-plugins-in-lua-5cca

local api = vim.api
local buf, win

local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function open_window()
  buf = vim.api.nvim_create_buf(false, true)
  local border_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'bacon')

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  vim.api.nvim_win_set_option(win, 'cursorline', true)

  api.nvim_buf_set_lines(buf, 0, -1, false, { center('Bacon Locations (hit q to close)'), '', ''})
  api.nvim_buf_add_highlight(buf, -1, 'BaconHeader', 0, 0, -1)
end

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

local function update_view()
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  local result = lines_from(".bacon-locations")

  if #result == 0 then table.insert(result, '') end
  for k,v in pairs(result) do
    result[k] = '  '..v
  end

  api.nvim_buf_set_lines(buf, 2, -1, false, result)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function close_window()
  api.nvim_win_close(win, true)
end

-- open one of the locations
local function open_location()
  local location = api.nvim_get_current_line()
  -- location is normally file_path:line:col
  local parts = string.gmatch(location, '[^:]+')
  local path = parts()
  local line = tonumber(parts())
  local col = tonumber(parts())
  close_window()
  -- ok, if somebody knows how to directly jump to a precise location, please tell me
  api.nvim_command('edit ' .. path)
  api.nvim_win_set_cursor(0, {line, col})
end

local function move_cursor()
  local new_pos = math.max(3, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, {new_pos, 0})
end

local function set_mappings()
  local mappings = {
    ['<cr>'] = 'open_location()',
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

local function bacon_list()
  open_window()
  set_mappings()
  update_view()
  api.nvim_win_set_cursor(win, {3, 0})
end

return {
  bacon_list = bacon_list,
  update_view = update_view,
  open_location = open_location,
  move_cursor = move_cursor,
  close_window = close_window
}
