local M = {}
local LINE_CHUNK = 100
local VISIBLE_PADDING = 100
local ns = vim.api.nvim_create_namespace("gvhi")
local opts = {
  priority=300
}

function M.ansi_highlight()
  local max_line = vim.fn.line('$')

  local min_visble_line = vim.fn.line('w0') - VISIBLE_PADDING
  min_visble_line = min_visble_line < 1 and 1 or min_visble_line
  local max_visble_line = vim.fn.line('w$') + VISIBLE_PADDING
  max_visble_line = max_visble_line > max_line and max_line or max_visble_line

  local buf = vim.fn.bufnr('%')
  local bufId = vim.b[buf].ansi_buf_id
  if bufId == nil then
    bufId = 0
  end

  bufId = bufId + 1
  vim.b[buf].ansi_buf_id = bufId

  if max_visble_line - min_visble_line > 0 then
    M.ansi_highlight_range(buf, min_visble_line, max_visble_line)
    vim.defer_fn(function()
      M.ansi_highlight_worker(1, max_line, min_visble_line, max_visble_line, buf, bufId)
    end, 100)
  else
    M.ansi_highlight_worker(1, max_line, min_visble_line, max_visble_line, buf, bufId)
  end

end

function M.ansi_highlight_visible(b)
  local max_line = vim.fn.line('$')

  local min_visble_line = vim.fn.line('w0')
  min_visble_line = min_visble_line < 1 and 1 or min_visble_line
  local max_visble_line = vim.fn.line('w$')
  max_visble_line = max_visble_line > max_line and max_line or max_visble_line

  local buf = b == -1 or vim.fn.bufnr('%') and b

  if max_visble_line - min_visble_line > 0 then
    M.ansi_highlight_visible_range(buf, min_visble_line, max_visble_line)
  end
end

function M.ansi_highlight_visible_range(buf, s, e)
  local lines = vim.api.nvim_buf_get_lines(buf, s, e, false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  for i, l in pairs(lines) do
    local new_l, new_l_hi = M.ansi_highlight_line(l)
    if next(new_l_hi) ~= nil then
      vim.api.nvim_buf_set_lines(buf, i + s - 1, i + s - 1, false, {new_l})
      for _, v in ipairs(new_l_hi) do
        local prefix, col_s, col_e = v[1], v[2], v[3]
        vim.highlight.range(buf, ns, 'gvAnsi'..prefix, {i + s - 1, col_s}, {i + s - 1, col_e}, opts)
      end
    end
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end


function M.ansi_get_hi_group(ansi)
  return vim.fn.matchstr(ansi, '\\d\\zem')
end

function M.ansi_highlight_line(l)
  local prev_hi = ''
  local prev_idx = ''
  local hi_list = {}

  local m, e
  local s = 0
  while true do
    m, s, e = unpack(vim.fn.matchstrpos(l, '\\e\\[[0-9;]*[mK]', s))
    if #m == 0 then
      break
    end
    if s == 0 then
      l = l:sub(e + 1)
    else
      l = l:sub(1, s) .. l:sub(e + 1)
    end

    local cur_hi = M.ansi_get_hi_group(m)
    if prev_hi == cur_hi then
      goto continue
    end

    if #prev_hi > 0 then
      table.insert(hi_list, {prev_hi, prev_idx, s})
    end

    prev_hi = cur_hi
    prev_idx = s
    ::continue::
  end
  return l, hi_list
end

function M.ansi_highlight_range(buf, s, e)
  local lines = vim.api.nvim_buf_get_lines(buf, s, e, false)
  local new_lines = {}
  local new_lines_hi = {}
  for _, l in pairs(lines) do
    local new_l, new_l_hi = M.ansi_highlight_line(l)
    table.insert(new_lines, new_l)
    table.insert(new_lines_hi, new_l_hi)
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, s, e, false, new_lines)

  for i, d in pairs(new_lines_hi) do
    for _, v in ipairs(d) do
      local prefix, col_s, col_e = v[1], v[2], v[3]
      vim.highlight.range(buf, ns, 'gvAnsi'..prefix, {i + s - 1, col_s}, {i + s - 1, col_e}, opts)
    end
  end
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.ansi_highlight_worker(cur, max_line, min_visble_line, max_visble_line, buf, bufId)
  if not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local curBufId = vim.b[buf].ansi_buf_id
  if curBufId ~= bufId then
    return
  end

  local s = cur
  local e = s + LINE_CHUNK

  if s >= min_visble_line and s < max_visble_line then
    s =  max_visble_line
    e =  s + LINE_CHUNK
  elseif e >= min_visble_line and e < max_visble_line then
    e = min_visble_line - 1

    if e < s then
      s = max_visble_line
      e =  s + LINE_CHUNK
    end
  end

  e = e > max_line and max_line or e

  M.ansi_highlight_range(buf, s, e)

  if e <= max_line then
    vim.defer_fn(function()
      M.ansi_highlight_worker(e, max_line, min_visble_line, max_visble_line, buf, bufId)
    end, 100)
  end
end

return M
