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

  function ansi_highlight_task(line)
    local l = vim.fn.getbufoneline(buf, line)
    local prev_hi = ''
    local prev_idx = ''
    local hi_list = {}

    local s = 0
    while true do
      local m, s, e = unpack(vim.fn.matchstrpos(l, '\\e\\[[0-9;]*[mK]', s))
      if #m == 0 then
        break
      end
      if s == 0 then
        l = l:sub(e + 1)
      else
        l = l:sub(1, s) .. l:sub(e + 1)
      end

      local cur_hi = ansi_hi_group(m)
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

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.fn.setbufline(buf, line, l)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    for _, v in ipairs(hi_list) do
      local prefix, s, e = v[1], v[2], v[3]
      vim.highlight.range(buf, ns, 'gvAnsi'..prefix, {line-1, s}, {line-1,e}, opts)
    end
  end

  function ansi_highlight_worker(cur, _bufId)
    for i = cur, max_line do
      if not vim.api.nvim_buf_is_loaded(buf) then
        return
      end
      local curBufId = vim.b[buf].ansi_buf_id
      if curBufId ~= _bufId then
        return
      end

      if i >= min_visble_line and i <= max_visble_line then
        goto continue
      end

      ansi_highlight_task(i)

      if i >= max_line then
        return
      end

      if i - cur > LINE_CHUNK and i + 1 <= max_line then
        vim.defer_fn(function()
          ansi_highlight_worker(i + 1, _bufId)
        end, 100)
        return
      end
      ::continue::
    end
  end

  if max_visble_line - min_visble_line > 0 then
    for i = min_visble_line, max_visble_line do
      ansi_highlight_task(i)
    end
    vim.defer_fn(function()
      ansi_highlight_worker(1, bufId)
    end, 100)
  else
    ansi_highlight_worker(1, bufId)
  end

end

function ansi_hi_group(ansi)
  return vim.fn.matchstr(ansi, '\\d\\zem')
end



return M
