local M = {}
local ns = vim.api.nvim_create_namespace("gvhi")
local opts = {
  priority=300
}

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
  local lines = vim.api.nvim_buf_get_lines(buf, s - 1, e, false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  for i, l in pairs(lines) do
    local cur_col
    if i + s - 1 == vim.fn.line('.') then
      cur_col = vim.fn.col('.')
    end
    local new_l, new_l_hi, col_shift = M.ansi_highlight_line(l, cur_col)
    if next(new_l_hi) ~= nil then
      vim.api.nvim_buf_set_lines(buf, i + s - 2, i + s - 1, false, {new_l})
      for _, v in ipairs(new_l_hi) do
        local suffix, col_s, col_e = v[1], v[2], v[3]
        vim.highlight.range(buf, ns, 'gvAnsi'..suffix, {i + s - 2, col_s}, {i + s - 2, col_e}, opts)
      end
      if cur_col ~= nil then
        vim.fn.setpos('.', {buf, i + s - 1, cur_col - col_shift})
      end
    end
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end


function M.ansi_get_hi_group(ansi)
  -- \0[1;33m   <-- ansi example
  local bold = vim.fn.matchstr(ansi, '1;')
  -- only take the last number to represent color
  local suffix = vim.fn.matchstr(ansi, '3\\zs\\d\\zem')
  return bold ~= '' and suffix ~= '' and 'Bold' .. suffix or suffix
end

function M.ansi_highlight_line(l, cur_col)
  local prev_hi = ''
  local prev_idx = ''
  local hi_list = {}

  local m, e
  local s = 0
  local col_shift = 0
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

    if cur_col ~= nil and cur_col > e then
      col_shift = col_shift + e - s
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
  return l, hi_list, col_shift
end

return M
